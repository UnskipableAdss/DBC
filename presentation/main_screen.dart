// lib/presentation/main_screen.dart
// ─────────────────────────────────────────────────────────────────────────────
// EDI Translator — Main Screen
// Material 3 · BLoC · Roboto Mono · Dark industrial aesthetic
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:edi_translator/application/edi_bloc.dart';
import 'package:edi_translator/domain/edi_parser.dart';
import 'package:edi_translator/data/edi_constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Theme tokens
// ─────────────────────────────────────────────────────────────────────────────

class _T {
  static const bg = Color(0xFF0D0F14);
  static const surface = Color(0xFF151922);
  static const card = Color(0xFF1C2230);
  static const border = Color(0xFF2A3347);
  static const accent = Color(0xFF00E5A0); // teal-green
  static const accentDim = Color(0xFF00996B);
  static const warning = Color(0xFFFFB020);
  static const error = Color(0xFFFF4D6A);
  static const textPrimary = Color(0xFFE8EDF5);
  static const textSecondary = Color(0xFF8A96AA);
  static const segmentChipBg = Color(0xFF1E2D24);
  static const segmentChipText = Color(0xFF00E5A0);
}

// ─────────────────────────────────────────────────────────────────────────────
// Root widget
// ─────────────────────────────────────────────────────────────────────────────

class EDITranslatorApp extends StatelessWidget {
  const EDITranslatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EDIBloc(),
      child: MaterialApp(
        title: 'EDI Translator',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: _T.accent,
            brightness: Brightness.dark,
            surface: _T.surface,
          ),
          scaffoldBackgroundColor: _T.bg,
          textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
          snackBarTheme: const SnackBarThemeData(
            backgroundColor: _T.card,
            contentTextStyle: TextStyle(color: _T.textPrimary),
          ),
        ),
        home: const MainScreen(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MainScreen
// ─────────────────────────────────────────────────────────────────────────────

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  final _textController = TextEditingController();
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _textController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // ── File picker ─────────────────────────────────────────────────────────────

  Future<void> _pickFile(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'edi', 'dat'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return;

    final content = String.fromCharCodes(bytes);
    if (!context.mounted) return;

    context.read<EDIBloc>().add(
          EDIFileLoaded(
            content: content,
            fileName: file.name,
          ),
        );

    // Switch to results tab
    _tabController.animateTo(1);
  }

  void _parse(BuildContext context) {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    context.read<EDIBloc>().add(EDIParseRequested(text));
    _tabController.animateTo(1);
    FocusScope.of(context).unfocus();
  }

  void _clear(BuildContext context) {
    _textController.clear();
    context.read<EDIBloc>().add(const EDICleared());
    _tabController.animateTo(0);
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocListener<EDIBloc, EDIState>(
      listener: (ctx, state) {
        if (state is EDIError) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: _T.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(state.message,
                        style: const TextStyle(color: _T.textPrimary)),
                  ),
                ],
              ),
              backgroundColor: _T.card,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: _T.error, width: 1)),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: _T.bg,
        appBar: _buildAppBar(context),
        body: Column(
          children: [
            _TabBar(controller: _tabController),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _InputTab(
                    controller: _textController,
                    onParse: () => _parse(context),
                    onPickFile: () => _pickFile(context),
                  ),
                  const _ResultsTab(),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: BlocBuilder<EDIBloc, EDIState>(
          builder: (ctx, state) {
            if (state is! EDISuccess) return const SizedBox.shrink();
            return _BottomActionBar(
              onExport: () =>
                  ctx.read<EDIBloc>().add(const EDIExportRequested()),
              onClear: () => _clear(ctx),
              segmentCount: state.result.segmentCount,
              parseTimeMs: state.result.parseTimeMs,
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: _T.surface,
      elevation: 0,
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _T.accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _T.accent.withOpacity(0.4)),
            ),
            child: const Icon(Icons.compare_arrows_rounded,
                color: _T.accent, size: 18),
          ),
          const SizedBox(width: 10),
          Text(
            'EDI Translator',
            style: GoogleFonts.spaceMono(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _T.textPrimary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _T.border),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab bar
// ─────────────────────────────────────────────────────────────────────────────

class _TabBar extends StatelessWidget {
  const _TabBar({required this.controller});
  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _T.surface,
      child: TabBar(
        controller: controller,
        labelStyle: GoogleFonts.spaceMono(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.spaceMono(fontSize: 12),
        labelColor: _T.accent,
        unselectedLabelColor: _T.textSecondary,
        indicatorColor: _T.accent,
        indicatorWeight: 2,
        tabs: const [
          Tab(icon: Icon(Icons.edit_note_rounded, size: 18), text: 'INPUT'),
          Tab(icon: Icon(Icons.account_tree_outlined, size: 18), text: 'PARSED'),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Input tab
// ─────────────────────────────────────────────────────────────────────────────

class _InputTab extends StatelessWidget {
  const _InputTab({
    required this.controller,
    required this.onParse,
    required this.onPickFile,
  });

  final TextEditingController controller;
  final VoidCallback onParse;
  final VoidCallback onPickFile;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // File picker card
          _GlassCard(
            child: Row(
              children: [
                const Icon(Icons.folder_open_rounded,
                    color: _T.accent, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Import from local storage',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: _T.textSecondary),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: onPickFile,
                  icon: const Icon(Icons.upload_file_rounded, size: 16),
                  label: const Text('Browse'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _T.accent,
                    foregroundColor: _T.bg,
                    textStyle: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.w700),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Supported: .edi · .txt · .dat',
            style: GoogleFonts.spaceMono(
                fontSize: 10, color: _T.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Divider
          Row(children: [
            const Expanded(child: Divider(color: _T.border)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('or paste',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: _T.textSecondary)),
            ),
            const Expanded(child: Divider(color: _T.border)),
          ]),
          const SizedBox(height: 16),

          // Text input
          Container(
            decoration: BoxDecoration(
              color: _T.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _T.border),
            ),
            child: TextFormField(
              controller: controller,
              maxLines: null,
              minLines: 12,
              keyboardType: TextInputType.multiline,
              style: GoogleFonts.robotoMono(
                fontSize: 12,
                color: _T.textPrimary,
                height: 1.6,
              ),
              decoration: InputDecoration(
                hintText:
                    'ISA*00*          *00*          *ZZ*SENDER         *ZZ*RECEIVER       *240101*1200*^*00501*000000001*0*P*:~\nGS*PO*SENDER*RECEIVER*20240101*1200*1*X*005010~\nST*850*0001~\n...',
                hintStyle: GoogleFonts.robotoMono(
                    fontSize: 11,
                    color: _T.textSecondary.withOpacity(0.5)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Parse button
          FilledButton.icon(
            onPressed: onParse,
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(
              'PARSE EDI',
              style: GoogleFonts.spaceMono(
                  fontSize: 13, fontWeight: FontWeight.w700),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: _T.accent,
              foregroundColor: _T.bg,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Results tab
// ─────────────────────────────────────────────────────────────────────────────

class _ResultsTab extends StatelessWidget {
  const _ResultsTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EDIBloc, EDIState>(
      builder: (ctx, state) {
        if (state is EDIInitial) {
          return _EmptyState();
        } else if (state is EDIParsing) {
          return _LoadingOverlay(progress: state.progress);
        } else if (state is EDISuccess) {
          return _SuccessView(state: state);
        } else if (state is EDIError) {
          return _ErrorView(message: state.message);
        }
        return const SizedBox.shrink();
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading overlay
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.settings_ethernet_rounded,
                color: _T.accent, size: 48),
            const SizedBox(height: 24),
            Text(
              'Parsing EDI document…',
              style: GoogleFonts.spaceMono(
                  color: _T.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: _T.border,
              color: _T.accent,
              minHeight: 4,
              borderRadius: BorderRadius.circular(2),
            ),
            const SizedBox(height: 8),
            Text(
              '${(progress * 100).toInt()}%',
              style: GoogleFonts.spaceMono(
                  color: _T.accent, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Success view
// ─────────────────────────────────────────────────────────────────────────────

class _SuccessView extends StatefulWidget {
  const _SuccessView({required this.state});
  final EDISuccess state;

  @override
  State<_SuccessView> createState() => _SuccessViewState();
}

class _SuccessViewState extends State<_SuccessView> {
  int _currentPage = 0;

  EDISuccess get _s => widget.state;

  List<EDISegment> get _visibleSegments {
    if (!_s.isPaginated) return _s.result.segments;
    final start = _currentPage * EDISuccess.kPageSize;
    final end =
        (start + EDISuccess.kPageSize).clamp(0, _s.result.segmentCount);
    return _s.result.segments.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Stats banner
        _StatsBanner(state: _s),

        // Delimiter info
        _DelimiterBadge(delimiters: _s.result.delimiters),

        // Segment list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
            itemCount: _visibleSegments.length,
            itemBuilder: (ctx, i) =>
                _SegmentTile(segment: _visibleSegments[i]),
          ),
        ),

        // Pagination bar (only for large files)
        if (_s.isPaginated)
          _PaginationBar(
            currentPage: _currentPage,
            totalPages: _s.totalPages,
            onPrev: _currentPage > 0
                ? () => setState(() => _currentPage--)
                : null,
            onNext: _currentPage < _s.totalPages - 1
                ? () => setState(() => _currentPage++)
                : null,
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Segment tile (expandable)
// ─────────────────────────────────────────────────────────────────────────────

class _SegmentTile extends StatefulWidget {
  const _SegmentTile({required this.segment});
  final EDISegment segment;

  @override
  State<_SegmentTile> createState() => _SegmentTileState();
}

class _SegmentTileState extends State<_SegmentTile> {
  bool _expanded = false;

  Color get _chipColor {
    switch (widget.segment.id) {
      case 'ISA':
      case 'IEA':
      case 'GS':
      case 'GE':
        return const Color(0xFF1A2A4A);
      case 'ST':
      case 'SE':
        return const Color(0xFF2A1A3A);
      default:
        return _T.segmentChipBg;
    }
  }

  @override
  Widget build(BuildContext context) {
    final seg = widget.segment;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: _T.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: _expanded ? _T.accent.withOpacity(0.3) : _T.border,
            width: _expanded ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header row
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  // Segment ID chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _chipColor,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: _T.accent.withOpacity(0.25), width: 1),
                    ),
                    child: Text(
                      seg.id,
                      style: GoogleFonts.robotoMono(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _T.segmentChipText,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Human-readable name
                  Expanded(
                    child: Text(
                      seg.name.isNotEmpty ? seg.name : 'Segment',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: _T.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Element count badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _T.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${seg.elements.length}',
                      style: GoogleFonts.spaceMono(
                          fontSize: 10, color: _T.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: _T.textSecondary,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),

          // Expanded element table
          if (_expanded) ...[
            const Divider(height: 1, color: _T.border),
            Padding(
              padding: const EdgeInsets.all(12),
              child: seg.elements.isEmpty
                  ? Text('No data elements.',
                      style: GoogleFonts.robotoMono(
                          fontSize: 11, color: _T.textSecondary))
                  : _ElementTable(
                      segmentId: seg.id, elements: seg.elements),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Element table
// ─────────────────────────────────────────────────────────────────────────────

class _ElementTable extends StatelessWidget {
  const _ElementTable(
      {required this.segmentId, required this.elements});

  final String segmentId;
  final List<EDIElement> elements;

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: IntrinsicColumnWidth(),
        1: IntrinsicColumnWidth(),
        2: FlexColumnWidth(),
      },
      children: [
        // Header
        TableRow(
          decoration: BoxDecoration(
            color: _T.border.withOpacity(0.5),
            borderRadius: BorderRadius.circular(4),
          ),
          children: [
            _th('Index'),
            _th('Label'),
            _th('Value'),
          ],
        ),
        ...elements.map((el) {
          final indexLabel =
              '$segmentId-${el.index.toString().padLeft(2, '0')}';
          return TableRow(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                    color: _T.border.withOpacity(0.4), width: 0.5),
              ),
            ),
            children: [
              _td(indexLabel, mono: true, color: _T.warning),
              _td(
                el.label.isNotEmpty ? el.label : '—',
                color: _T.textSecondary,
              ),
              _td(
                el.rawValue.isEmpty ? '(empty)' : el.rawValue,
                mono: true,
                color: el.rawValue.isEmpty
                    ? _T.textSecondary.withOpacity(0.5)
                    : _T.textPrimary,
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _th(String text) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: Text(
          text,
          style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: _T.textSecondary,
              letterSpacing: 0.5),
        ),
      );

  Widget _td(String text, {bool mono = false, Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Text(
          text,
          style: mono
              ? GoogleFonts.robotoMono(
                  fontSize: 11, color: color ?? _T.textPrimary)
              : GoogleFonts.inter(
                  fontSize: 11, color: color ?? _T.textPrimary),
          softWrap: true,
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats banner
// ─────────────────────────────────────────────────────────────────────────────

class _StatsBanner extends StatelessWidget {
  const _StatsBanner({required this.state});
  final EDISuccess state;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _T.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _stat(Icons.splitscreen_rounded, '${state.result.segmentCount}',
              'segments'),
          const SizedBox(width: 20),
          _stat(Icons.timer_outlined, '${state.result.parseTimeMs}ms',
              'parse time'),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _T.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _T.accent.withOpacity(0.3)),
            ),
            child: Text(
              state.fileName,
              style: GoogleFonts.robotoMono(
                  fontSize: 10, color: _T.accent),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String value, String label) => Row(
        children: [
          Icon(icon, color: _T.accent, size: 14),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: GoogleFonts.spaceMono(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _T.textPrimary)),
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 9, color: _T.textSecondary)),
            ],
          ),
        ],
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Delimiter badge
// ─────────────────────────────────────────────────────────────────────────────

class _DelimiterBadge extends StatelessWidget {
  const _DelimiterBadge({required this.delimiters});
  final EDIDelimiters delimiters;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: _T.bg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Wrap(
        spacing: 10,
        children: [
          _badge('elem', delimiters.element),
          _badge('seg', delimiters.segment == '\n'
              ? '\\n'
              : delimiters.segment),
          _badge('comp', delimiters.component),
          _badge('rep', delimiters.repetition),
        ],
      ),
    );
  }

  Widget _badge(String label, String value) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: _T.card,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: _T.border),
        ),
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                  text: '$label: ',
                  style: GoogleFonts.robotoMono(
                      fontSize: 9, color: _T.textSecondary)),
              TextSpan(
                  text: value,
                  style: GoogleFonts.robotoMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _T.warning)),
            ],
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Pagination bar
// ─────────────────────────────────────────────────────────────────────────────

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.currentPage,
    required this.totalPages,
    this.onPrev,
    this.onNext,
  });

  final int currentPage;
  final int totalPages;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _T.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left_rounded),
            color: onPrev != null ? _T.accent : _T.textSecondary,
          ),
          Text(
            'Page ${currentPage + 1} / $totalPages',
            style: GoogleFonts.spaceMono(
                fontSize: 12, color: _T.textSecondary),
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded),
            color: onNext != null ? _T.accent : _T.textSecondary,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom action bar
// ─────────────────────────────────────────────────────────────────────────────

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.onExport,
    required this.onClear,
    required this.segmentCount,
    required this.parseTimeMs,
  });

  final VoidCallback onExport;
  final VoidCallback onClear;
  final int segmentCount;
  final int parseTimeMs;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _T.surface,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.clear_rounded, size: 16),
            label: const Text('Clear'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _T.error,
              side: const BorderSide(color: _T.error),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton.icon(
              onPressed: onExport,
              icon: const Icon(Icons.share_rounded, size: 16),
              label: Text(
                'Export JSON',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: _T.accentDim,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.article_outlined,
              color: _T.textSecondary.withOpacity(0.3), size: 64),
          const SizedBox(height: 16),
          Text(
            'No EDI document parsed yet.',
            style: GoogleFonts.inter(
                fontSize: 14, color: _T.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            'Go to INPUT and paste or load a file.',
            style: GoogleFonts.inter(
                fontSize: 12,
                color: _T.textSecondary.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error view
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: _T.error, size: 52),
            const SizedBox(height: 16),
            Text(
              'Parse Failed',
              style: GoogleFonts.spaceMono(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _T.error),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _T.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _T.error.withOpacity(0.25)),
              ),
              child: Text(
                message,
                style: GoogleFonts.robotoMono(
                    fontSize: 12, color: _T.textPrimary),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared: Glass card container
// ─────────────────────────────────────────────────────────────────────────────

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _T.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _T.border),
      ),
      child: child,
    );
  }
}
