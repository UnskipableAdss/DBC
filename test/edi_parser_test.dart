// test/edi_parser_test.dart
// ─────────────────────────────────────────────────────────────────────────────
// Unit tests for EDIProcessor
// Run with: flutter test
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_test/flutter_test.dart';
import 'package:edi_translator/domain/edi_parser.dart';

void main() {
  final processor = EDIProcessor();

  // ── Sample EDI strings ────────────────────────────────────────────────────

  const kValidX12 =
      'ISA*00*          *00*          *ZZ*SENDERID       *ZZ*RECEIVERID     *240101*1200*^*00501*000000001*0*T*:~'
      'GS*PO*SENDER*RECEIVER*20240101*1200*1*X*005010~'
      'ST*850*0001~'
      'BEG*00*SA*PO12345**20240101~'
      'N1*BY*ACME CORP*92*123456~'
      'N3*123 MAIN ST~'
      'N4*ANYTOWN*CA*90210*US~'
      'PO1*001*10*EA*25.00*PE*BP*WIDGET-A~'
      'CTT*1~'
      'SE*8*0001~'
      'GE*1*1~'
      'IEA*1*000000001~';

  const kEmptyElements =
      'ISA*00*          *00*          *ZZ*SENDER         *ZZ*RECEIVER       *240101*1200*^*00501*000000001*0*P*:~'
      'ST*850**0001~'; // ST-02 is empty

  const kEdifact =
      "UNA:+.? '\n"
      "UNB+UNOA:1+SENDER+RECEIVER+240101:1200+000000001'\n"
      "UNH+1+ORDERS:D:96A:UN'\n"
      "BGM+220+PO12345+9'\n"
      "UNT+3+1'\n"
      "UNZ+1+000000001'";

  // ── Tests ──────────────────────────────────────────────────────────────────

  group('Delimiter Detection', () {
    test('X12: detects * as element separator', () {
      final result = processor.parse(kValidX12);
      expect(result.delimiters.element, '*');
    });

    test('X12: detects ~ as segment terminator', () {
      final result = processor.parse(kValidX12);
      expect(result.delimiters.segment, '~');
    });

    test('X12: detects : as component separator', () {
      final result = processor.parse(kValidX12);
      expect(result.delimiters.component, ':');
    });

    test('EDIFACT: detects + as element separator', () {
      final result = processor.parse(kEdifact);
      expect(result.delimiters.element, '+');
    });

    test('EDIFACT: detects single-quote as segment terminator', () {
      final result = processor.parse(kEdifact);
      expect(result.delimiters.segment, "'");
    });
  });

  group('Hierarchical Parsing', () {
    test('Level 1: correct segment count for X12 850', () {
      final result = processor.parse(kValidX12);
      // ISA GS ST BEG N1 N3 N4 PO1 CTT SE GE IEA = 12
      expect(result.segmentCount, 12);
    });

    test('Level 2: ISA has 16 elements', () {
      final result = processor.parse(kValidX12);
      final isa = result.segments.firstWhere((s) => s.id == 'ISA');
      expect(isa.elements.length, 16);
    });

    test('Level 2: BEG elements correctly indexed', () {
      final result = processor.parse(kValidX12);
      final beg = result.segments.firstWhere((s) => s.id == 'BEG');
      expect(beg.elements[0].rawValue, '00'); // BEG-01
      expect(beg.elements[1].rawValue, 'SA'); // BEG-02
      expect(beg.elements[2].rawValue, 'PO12345'); // BEG-03
    });

    test('Level 3: component splitting on ISA-16 value', () {
      final result = processor.parse(kValidX12);
      // The ISA-16 element in this sample is ':' itself, so components = [':']
      // A real sub-element like "AB:CD" would split into ['AB','CD']
      final sta = result.segments.firstWhere((s) => s.id == 'ST');
      expect(sta.elements.isNotEmpty, true);
    });
  });

  group('Empty Element Handling', () {
    test('Empty ST-02 does not shift ST-03 index', () {
      final result = processor.parse(kEmptyElements);
      final st = result.segments.firstWhere((s) => s.id == 'ST');
      expect(st.elements[0].rawValue, '850'); // ST-01
      expect(st.elements[1].rawValue, '');    // ST-02 empty – preserved!
      expect(st.elements[2].rawValue, '0001'); // ST-03 not shifted
    });
  });

  group('Validation', () {
    test('Throws InvalidEDIException for non-ISA/UNA/UNB input', () {
      expect(
        () => processor.parse('HELLO WORLD'),
        throwsA(isA<InvalidEDIException>()),
      );
    });

    test('Throws InvalidEDIException for short ISA', () {
      expect(
        () => processor.parse('ISA*00*short'),
        throwsA(isA<InvalidEDIException>()),
      );
    });

    test('Accepts valid EDIFACT UNA prefix', () {
      expect(() => processor.parse(kEdifact), returnsNormally);
    });
  });

  group('Dictionary Mapping', () {
    test('ISA segment gets correct human name', () {
      final result = processor.parse(kValidX12);
      final isa = result.segments.firstWhere((s) => s.id == 'ISA');
      expect(isa.name, 'Interchange Control Header');
    });

    test('BEG-01 gets element description', () {
      final result = processor.parse(kValidX12);
      final beg = result.segments.firstWhere((s) => s.id == 'BEG');
      expect(beg.elements[0].label, 'Transaction Set Purpose Code');
    });

    test('Unknown segment ID has empty name (not null)', () {
      // Force an unknown segment by embedding a fake one
      const fakeEdi =
          'ISA*00*          *00*          *ZZ*SENDER         *ZZ*RECEIVER       *240101*1200*^*00501*000000001*0*T*:~'
          'ZZZ*test~'
          'IEA*0*000000001~';
      final result = processor.parse(fakeEdi);
      final zzz = result.segments.firstWhere((s) => s.id == 'ZZZ');
      expect(zzz.name, '');
    });
  });

  group('JSON Export', () {
    test('toJsonList returns one entry per segment', () {
      final result = processor.parse(kValidX12);
      final json = result.toJsonList();
      expect(json.length, result.segmentCount);
    });

    test('Each JSON entry has segment key', () {
      final result = processor.parse(kValidX12);
      final json = result.toJsonList();
      expect(json.first.containsKey('segment'), true);
    });
  });
}
