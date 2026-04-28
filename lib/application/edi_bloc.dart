// lib/application/edi_bloc.dart
// ─────────────────────────────────────────────────────────────────────────────
// BLoC State Management for EDI Translator
// States: EDIInitial → EDIParsing → EDISuccess | EDIError
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:edi_translator/domain/edi_parser.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Events
// ─────────────────────────────────────────────────────────────────────────────

abstract class EDIEvent extends Equatable {
  const EDIEvent();
  @override
  List<Object?> get props => [];
}

/// User pasted or typed raw EDI text.
class EDIParseRequested extends EDIEvent {
  const EDIParseRequested(this.rawText);
  final String rawText;
  @override
  List<Object?> get props => [rawText];
}

/// User picked a file from storage.
class EDIFileLoaded extends EDIEvent {
  const EDIFileLoaded({required this.content, required this.fileName});
  final String content;
  final String fileName;
  @override
  List<Object?> get props => [content, fileName];
}

/// User wants to export/share parsed result.
class EDIExportRequested extends EDIEvent {
  const EDIExportRequested();
}

/// User cleared the workspace.
class EDICleared extends EDIEvent {
  const EDICleared();
}

// ─────────────────────────────────────────────────────────────────────────────
// States
// ─────────────────────────────────────────────────────────────────────────────

abstract class EDIState extends Equatable {
  const EDIState();
  @override
  List<Object?> get props => [];
}

class EDIInitial extends EDIState {
  const EDIInitial();
}

class EDIParsing extends EDIState {
  const EDIParsing({this.progress = 0.0});
  final double progress;
  @override
  List<Object?> get props => [progress];
}

class EDISuccess extends EDIState {
  const EDISuccess({
    required this.result,
    required this.fileName,
    this.page = 0,
  });
  final EDIParseResult result;
  final String fileName;

  /// Current page index when large-file pagination is active.
  final int page;

  static const int kPageSize = 100;

  List<EDISegment> get currentPageSegments {
    final start = page * kPageSize;
    final end = (start + kPageSize).clamp(0, result.segmentCount);
    if (start >= result.segmentCount) return [];
    return result.segments.sublist(start, end);
  }

  int get totalPages =>
      (result.segmentCount / kPageSize).ceil().clamp(1, 9999);

  bool get isPaginated => result.segmentCount > kPageSize;

  EDISuccess copyWith({int? page}) =>
      EDISuccess(result: result, fileName: fileName, page: page ?? this.page);

  @override
  List<Object?> get props => [result, fileName, page];
}

class EDIError extends EDIState {
  const EDIError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

// ─────────────────────────────────────────────────────────────────────────────
// BLoC
// ─────────────────────────────────────────────────────────────────────────────

class EDIBloc extends Bloc<EDIEvent, EDIState> {
  EDIBloc() : super(const EDIInitial()) {
    on<EDIParseRequested>(_onParseRequested);
    on<EDIFileLoaded>(_onFileLoaded);
    on<EDIExportRequested>(_onExportRequested);
    on<EDICleared>(_onCleared);
  }

  final _processor = EDIProcessor();

  // ── Handlers ───────────────────────────────────────────────────────────────

  Future<void> _onParseRequested(
    EDIParseRequested event,
    Emitter<EDIState> emit,
  ) async {
    await _parseContent(event.rawText, 'Pasted Input', emit);
  }

  Future<void> _onFileLoaded(
    EDIFileLoaded event,
    Emitter<EDIState> emit,
  ) async {
    await _parseContent(event.content, event.fileName, emit);
  }

  Future<void> _parseContent(
    String content,
    String fileName,
    Emitter<EDIState> emit,
  ) async {
    emit(const EDIParsing(progress: 0.1));

    try {
      // Simulate progress tick while async parse runs
      emit(const EDIParsing(progress: 0.4));
      final result = await _processor.parseAsync(content);
      emit(const EDIParsing(progress: 0.9));

      await Future.delayed(const Duration(milliseconds: 120)); // UX polish
      emit(EDISuccess(result: result, fileName: fileName));
    } on InvalidEDIException catch (e) {
      emit(EDIError(e.message));
    } on EDIFileTooLargeException catch (e) {
      emit(EDIError(e.toString()));
    } catch (e) {
      emit(EDIError('Unexpected error: $e'));
    }
  }

  Future<void> _onExportRequested(
    EDIExportRequested event,
    Emitter<EDIState> emit,
  ) async {
    final current = state;
    if (current is! EDISuccess) return;

    final jsonStr = const JsonEncoder.withIndent('  ')
        .convert(current.result.toJsonList());

    await Share.share(
      jsonStr,
      subject: 'EDI Parse Result – ${current.fileName}',
    );
  }

  void _onCleared(EDICleared event, Emitter<EDIState> emit) {
    emit(const EDIInitial());
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page navigation events (handled inline in UI via copyWith, not BLoC)
// Kept here so the UI can emit them through the BLoC if preferred.
// ─────────────────────────────────────────────────────────────────────────────

class EDIPageChanged extends EDIEvent {
  const EDIPageChanged(this.page);
  final int page;
  @override
  List<Object?> get props => [page];
}
