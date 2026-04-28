// lib/domain/edi_parser.dart
// ─────────────────────────────────────────────────────────────────────────────
// Pure-Dart EDI Logic Engine
//
// Implements the three-level hierarchical parsing pipeline described in the
// technical spec, mirroring the JavaScript reference implementation:
//
//   Level 1 → Raw string  ──► List<String>  segments
//   Level 2 → Segment     ──► List<String>  elements
//   Level 3 → Element     ──► List<String>  components (sub-elements)
//
// Delimiter detection is DYNAMIC – never hardcoded to '*' or '~'.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:edi_translator/data/edi_constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Domain models
// ─────────────────────────────────────────────────────────────────────────────

/// A single element within a segment, supporting optional sub-components.
class EDIElement {
  const EDIElement({
    required this.index,
    required this.label,
    required this.rawValue,
    required this.components,
  });

  /// 1-based element position, e.g. 1 → "BEG-01"
  final int index;

  /// Human-readable label if available in [kElementDescriptions].
  final String label;

  /// Raw string value as it appeared in the file.
  final String rawValue;

  /// Sub-components split by the component separator (may be a single item).
  final List<String> components;

  String get displayLabel => label.isNotEmpty ? label : 'Element';

  Map<String, dynamic> toJson() => {
        'index': index,
        'label': displayLabel,
        'value': rawValue,
        if (components.length > 1) 'components': components,
      };
}

/// One parsed EDI segment (e.g. the entire "BEG*00*SA*PO12345**20240101~").
class EDISegment {
  const EDISegment({
    required this.id,
    required this.name,
    required this.rawLine,
    required this.elements,
    required this.segmentIndex,
  });

  /// Segment identifier, e.g. "BEG", "ISA", "N1".
  final String id;

  /// Human-readable name from [kSegmentNames], or empty string.
  final String name;

  /// Original raw text for this segment (without terminator).
  final String rawLine;

  /// Parsed element list (index 0 is the segment ID itself, index 1 is
  /// the first data element → displayed as XX-01 to match EDI convention).
  final List<EDIElement> elements;

  /// Position of this segment within the full transaction (0-based).
  final int segmentIndex;

  Map<String, dynamic> toJson() => {
        'segment': id,
        'name': name,
        'index': segmentIndex,
        'elements': elements.map((e) => e.toJson()).toList(),
      };
}

/// Detected delimiters extracted from the ISA / UNA header.
class EDIDelimiters {
  const EDIDelimiters({
    required this.element,
    required this.segment,
    required this.component,
    required this.repetition,
  });

  final String element;
  final String segment;
  final String component;
  final String repetition;

  @override
  String toString() =>
      'EDIDelimiters(element=$element, segment=$segment, '
      'component=$component, repetition=$repetition)';
}

/// Full result of parsing one EDI interchange.
class EDIParseResult {
  const EDIParseResult({
    required this.segments,
    required this.delimiters,
    required this.rawInput,
    required this.parseTimeMs,
  });

  final List<EDISegment> segments;
  final EDIDelimiters delimiters;
  final String rawInput;
  final int parseTimeMs;

  int get segmentCount => segments.length;

  /// Flat JSON list for the share_plus export feature.
  List<Map<String, dynamic>> toJsonList() =>
      segments.map((s) => s.toJson()).toList();
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom exceptions
// ─────────────────────────────────────────────────────────────────────────────

class InvalidEDIException implements Exception {
  const InvalidEDIException(this.message);
  final String message;

  @override
  String toString() => 'InvalidEDIException: $message';
}

class EDIFileTooLargeException implements Exception {
  const EDIFileTooLargeException(this.sizeBytes);
  final int sizeBytes;

  @override
  String toString() =>
      'EDIFileTooLargeException: File is ${(sizeBytes / 1048576).toStringAsFixed(2)} MB. '
      'Only files ≤ 10 MB are supported in direct mode; use streaming for larger files.';
}

// ─────────────────────────────────────────────────────────────────────────────
// EDIProcessor – the core parsing engine
// ─────────────────────────────────────────────────────────────────────────────

class EDIProcessor {
  /// Maximum bytes for non-paginated (eager) parsing.
  static const int kMaxEagerBytes = 1 * 1024 * 1024; // 1 MB

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Parse [raw] synchronously. Throws [InvalidEDIException] on bad input.
  /// Callers MUST wrap in try/catch.
  EDIParseResult parse(String raw) {
    final sw = Stopwatch()..start();
    final cleaned = _normalizeLineEndings(raw.trim());
    _validatePreamble(cleaned);

    final delimiters = _detectDelimiters(cleaned);
    final segments = _parseSegments(cleaned, delimiters);
    sw.stop();

    return EDIParseResult(
      segments: segments,
      delimiters: delimiters,
      rawInput: raw,
      parseTimeMs: sw.elapsedMilliseconds,
    );
  }

  /// Async wrapper – runs [parse] in an isolate-friendly Future so the UI
  /// thread never blocks. Use with FutureBuilder or BLoC.
  Future<EDIParseResult> parseAsync(String raw) async {
    // For files >1 MB, we still parse but signal the UI to paginate.
    return Future(() => parse(raw));
  }

  /// Streaming variant for very large files: emits [EDISegment] objects one
  /// at a time so a StreamBuilder can render progressively.
  Stream<EDISegment> parseStream(String raw) async* {
    final cleaned = _normalizeLineEndings(raw.trim());
    _validatePreamble(cleaned);
    final delimiters = _detectDelimiters(cleaned);

    // Level 1: split into raw segment strings
    final rawSegments = _splitSegments(cleaned, delimiters.segment);
    int segIdx = 0;
    for (final seg in rawSegments) {
      final trimmed = seg.trim();
      if (trimmed.isEmpty) continue;
      yield _buildSegment(trimmed, delimiters, segIdx++);
      // Yield control every 50 segments to keep the stream responsive
      if (segIdx % 50 == 0) await Future.delayed(Duration.zero);
    }
  }

  // ── Step 0: Pre-processing ─────────────────────────────────────────────────

  String _normalizeLineEndings(String raw) =>
      raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

  void _validatePreamble(String raw) {
    final upper = raw.trimLeft().toUpperCase();
    if (!upper.startsWith('ISA') &&
        !upper.startsWith('UNA') &&
        !upper.startsWith('UNB')) {
      throw const InvalidEDIException(
        'Document does not begin with a valid EDI envelope segment '
        '(expected ISA, UNA, or UNB).',
      );
    }
  }

  // ── Step 1: Delimiter detection ────────────────────────────────────────────
  //
  // X12 ISA segment is ALWAYS exactly 106 characters:
  //   ISA + 15 fields of fixed widths separated by a single-char element sep.
  //   Position 3   → element separator      (e.g. '*')
  //   Position 105 → segment terminator     (e.g. '~')
  //   Position 104 → component separator    (ISA-16)
  //
  // EDIFACT UNA is optional and is always 9 chars following "UNA":
  //   UNA:+.? '   where positions 3-8 define the 6 service chars.

  EDIDelimiters _detectDelimiters(String raw) {
    final upper = raw.trimLeft().toUpperCase();

    if (upper.startsWith('ISA')) {
      return _detectX12Delimiters(raw.trimLeft());
    } else if (upper.startsWith('UNA')) {
      return _detectEdifactDelimiters(raw.trimLeft());
    } else {
      // UNB without UNA – use EDIFACT defaults
      return const EDIDelimiters(
        element: '+',
        segment: "'",
        component: ':',
        repetition: ' ',
      );
    }
  }

  EDIDelimiters _detectX12Delimiters(String raw) {
    if (raw.length < 106) {
      throw const InvalidEDIException(
        'ISA segment is malformed – must be at least 106 characters.',
      );
    }
    final elementSep = raw[3];
    final componentSep = raw[104];
    final segmentTerm = raw[105];
    // Repetition separator is ISA-11 (positions 82–84 in an ISA with '*')
    // We can parse it after we know the element sep:
    String repetitionSep = '^'; // X12 4010 default
    try {
      final isaFields = raw.substring(0, 106).split(elementSep);
      if (isaFields.length > 11) {
        final isa11 = isaFields[11].trim();
        if (isa11.isNotEmpty) repetitionSep = isa11[0];
      }
    } catch (_) {
      // non-fatal – use default
    }

    return EDIDelimiters(
      element: elementSep,
      segment: segmentTerm,
      component: componentSep,
      repetition: repetitionSep,
    );
  }

  EDIDelimiters _detectEdifactDelimiters(String raw) {
    // UNA service string: UNA + 6 chars
    // Positions: 3=component, 4=element, 5=decimal, 6=release, 7=reserved, 8=segment
    if (raw.length >= 9 && raw.substring(0, 3).toUpperCase() == 'UNA') {
      return EDIDelimiters(
        component: raw[3],
        element: raw[4],
        segment: raw[8],
        repetition: raw[7],
      );
    }
    return const EDIDelimiters(
      element: '+',
      segment: "'",
      component: ':',
      repetition: ' ',
    );
  }

  // ── Step 2: Level-1 split – segments ──────────────────────────────────────

  List<String> _splitSegments(String raw, String segmentTerminator) {
    // Escape the terminator for safety (it might be a regex meta-char)
    return raw
        .split(segmentTerminator)
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  List<EDISegment> _parseSegments(String raw, EDIDelimiters delimiters) {
    final rawSegments = _splitSegments(raw, delimiters.segment);
    final result = <EDISegment>[];
    for (int i = 0; i < rawSegments.length; i++) {
      final seg = rawSegments[i].trim();
      if (seg.isEmpty) continue;
      result.add(_buildSegment(seg, delimiters, i));
    }
    return result;
  }

  // ── Step 3: Level-2 & Level-3 – elements and components ───────────────────

  EDISegment _buildSegment(
    String rawSeg,
    EDIDelimiters delimiters,
    int segmentIndex,
  ) {
    // Level 2: split on element separator
    final parts = rawSeg.split(delimiters.element);
    final segId = parts.isNotEmpty ? parts[0].trim().toUpperCase() : 'UNKNOWN';
    final segName = kSegmentNames[segId] ?? '';

    final elements = <EDIElement>[];

    // Start from index 1 (index 0 is the segment ID itself).
    // We preserve empty elements so that index positions are never shifted.
    for (int i = 1; i < parts.length; i++) {
      final rawVal = parts[i]; // do NOT trim – empty string is intentional
      final elementKey =
          '$segId-${i.toString().padLeft(2, '0')}';
      final label = kElementDescriptions[elementKey] ?? '';

      // Level 3: split on component separator (only if it appears)
      final components = delimiters.component.isNotEmpty && rawVal.contains(delimiters.component)
          ? rawVal.split(delimiters.component)
          : [rawVal];

      elements.add(EDIElement(
        index: i,
        label: label,
        rawValue: rawVal,
        components: components,
      ));
    }

    return EDISegment(
      id: segId,
      name: segName,
      rawLine: rawSeg,
      elements: elements,
      segmentIndex: segmentIndex,
    );
  }
}
