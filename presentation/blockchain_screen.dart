// lib/presentation/blockchain_screen.dart
// ─────────────────────────────────────────────────────────────────────────────
// Blockchain Academic Records UI
// Tabs: Chain | Add Block | Search | Nodes
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:edi_translator/application/blockchain_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Theme tokens (same as main_screen)
// ─────────────────────────────────────────────────────────────────────────────
class _T {
  static const bg = Color(0xFF0D0F14);
  static const surface = Color(0xFF151922);
  static const card = Color(0xFF1C2230);
  static const border = Color(0xFF2A3347);
  static const accent = Color(0xFF00E5A0);
  static const accentDim = Color(0xFF00996B);
  static const warning = Color(0xFFFFB020);
  static const error = Color(0xFFFF4D6A);
  static const textPrimary = Color(0xFFE8EDF5);
  static const textSecondary = Color(0xFF8A96AA);
  static const purple = Color(0xFF9D7FEA);
  static const blue = Color(0xFF4A9EFF);
}

// ─────────────────────────────────────────────────────────────────────────────
// Root
// ─────────────────────────────────────────────────────────────────────────────

class BlockchainScreen extends StatefulWidget {
  const BlockchainScreen({super.key});

  @override
  State<BlockchainScreen> createState() => _BlockchainScreenState();
}

class _BlockchainScreenState extends State<BlockchainScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    // Check server + load chain on open
    context.read<BlockchainBloc>()
      ..add(const BCCheckStatus())
      ..add(const BCLoadChain());
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bg,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: BlocListener<BlockchainBloc, BlockchainState>(
              listener: _handleStateMessages,
              child: TabBarView(
                controller: _tab,
                children: const [
                  _ChainTab(),
                  _AddBlockTab(),
                  _SearchTab(),
                  _NodesTab(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleStateMessages(BuildContext ctx, BlockchainState state) {
    String? msg;
    Color color = _T.accent;

    if (state is BCBlockAdded) {
      msg = state.message;
      color = state.message.contains('❌') ? _T.error : _T.accent;
      // Reload chain after adding
      ctx.read<BlockchainBloc>().add(const BCLoadChain());
    } else if (state is BCNodeAdded) {
      msg = state.message;
      color = state.message.contains('❌') ? _T.error : _T.accent;
    } else if (state is BCError) {
      msg = state.message;
      color = _T.error;
    } else if (state is BCServerStatus) {
      msg = state.isOnline ? '✅ Server online' : '❌ Server offline';
      color = state.isOnline ? _T.accent : _T.error;
    }

    if (msg != null && ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(msg,
              style: GoogleFonts.robotoMono(
                  fontSize: 12, color: _T.textPrimary)),
          backgroundColor: _T.card,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: color, width: 1),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _T.surface,
      elevation: 0,
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _T.purple.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _T.purple.withOpacity(0.4)),
            ),
            child: const Icon(Icons.link_rounded, color: _T.purple, size: 18),
          ),
          const SizedBox(width: 10),
          Text(
            'Blockchain Records',
            style: GoogleFonts.spaceMono(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _T.textPrimary,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: _T.accent, size: 20),
          onPressed: () {
            context.read<BlockchainBloc>()
              ..add(const BCCheckStatus())
              ..add(const BCLoadChain());
          },
          tooltip: 'Refresh',
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _T.border),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: _T.surface,
      child: TabBar(
        controller: _tab,
        labelStyle:
            GoogleFonts.spaceMono(fontSize: 10, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.spaceMono(fontSize: 10),
        labelColor: _T.accent,
        unselectedLabelColor: _T.textSecondary,
        indicatorColor: _T.accent,
        indicatorWeight: 2,
        tabs: const [
          Tab(icon: Icon(Icons.storage_rounded, size: 16), text: 'CHAIN'),
          Tab(icon: Icon(Icons.add_box_rounded, size: 16), text: 'ADD'),
          Tab(icon: Icon(Icons.search_rounded, size: 16), text: 'SEARCH'),
          Tab(icon: Icon(Icons.hub_rounded, size: 16), text: 'NODES'),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1: Chain Viewer
// ─────────────────────────────────────────────────────────────────────────────

class _ChainTab extends StatelessWidget {
  const _ChainTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BlockchainBloc, BlockchainState>(
      builder: (ctx, state) {
        if (state is BCLoading) return const _Loader();
        if (state is BCChainLoaded) {
          return _buildChain(ctx, state.chain);
        }
        if (state is BCError) return _ErrorView(state.message);
        // Default: show loading while initial fetch runs
        return const _Loader();
      },
    );
  }

  Widget _buildChain(BuildContext ctx, List<Map<String, dynamic>> chain) {
    return Column(
      children: [
        // Stats bar
        Container(
          color: _T.surface,
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.link_rounded, color: _T.purple, size: 16),
              const SizedBox(width: 8),
              Text(
                '${chain.length} blocks in chain',
                style: GoogleFonts.spaceMono(
                    fontSize: 12, color: _T.textPrimary),
              ),
              const Spacer(),
              if (chain.isNotEmpty)
                Text(
                  'Latest: #${chain.last['index']}',
                  style: GoogleFonts.spaceMono(
                      fontSize: 10, color: _T.textSecondary),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: chain.length,
            itemBuilder: (ctx, i) {
              // Show newest first
              final block = chain[chain.length - 1 - i];
              return _BlockCard(block: block, isGenesis: block['index'] == 0);
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Block card
// ─────────────────────────────────────────────────────────────────────────────

class _BlockCard extends StatefulWidget {
  const _BlockCard({required this.block, required this.isGenesis});
  final Map<String, dynamic> block;
  final bool isGenesis;

  @override
  State<_BlockCard> createState() => _BlockCardState();
}

class _BlockCardState extends State<_BlockCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final b = widget.block;
    final index = b['index'] ?? 0;
    final isGenesis = widget.isGenesis;
    final color = isGenesis ? _T.warning : _T.accent;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _T.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _expanded ? color.withOpacity(0.4) : _T.border,
          width: _expanded ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Block index badge
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Center(
                      child: Text(
                        '#$index',
                        style: GoogleFonts.spaceMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isGenesis
                              ? 'Genesis Block'
                              : 'Student: ${b['student_id'] ?? '—'}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _T.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isGenesis
                              ? 'Chain origin'
                              : '${b['course'] ?? '—'} · ${b['credits'] ?? 0} credits',
                          style: GoogleFonts.inter(
                              fontSize: 11, color: _T.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  // Creator chip
                  if (!isGenesis)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: _T.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: _T.purple.withOpacity(0.3)),
                      ),
                      child: Text(
                        '${b['creator'] ?? '?'}',
                        style: GoogleFonts.spaceMono(
                            fontSize: 9, color: _T.purple),
                      ),
                    ),
                  const SizedBox(width: 6),
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

          // Expanded hash details
          if (_expanded) ...[
            const Divider(height: 1, color: _T.border),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  _hashRow('Hash', '${b['hash'] ?? ''}', _T.accent),
                  const SizedBox(height: 8),
                  _hashRow(
                      'Prev Hash', '${b['prev_hash'] ?? ''}', _T.blue),
                  const SizedBox(height: 8),
                  _infoRow('Timestamp',
                      _formatTs(b['timestamp'])),
                  if (!isGenesis) ...[
                    const SizedBox(height: 6),
                    _infoRow('Creator', '${b['creator'] ?? '—'}'),
                    _infoRow('Student ID', '${b['student_id'] ?? '—'}'),
                    _infoRow('Course', '${b['course'] ?? '—'}'),
                    _infoRow(
                        'Credits', '${b['credits'] ?? 0}'),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _hashRow(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 10, color: _T.textSecondary)),
        const SizedBox(height: 2),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Hash copied',
                    style: GoogleFonts.robotoMono(
                        fontSize: 11, color: _T.textPrimary)),
                backgroundColor: _T.card,
                duration: const Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.07),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Text(
              value,
              style: GoogleFonts.robotoMono(
                  fontSize: 9, color: color),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: GoogleFonts.inter(
                    fontSize: 11, color: _T.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: GoogleFonts.robotoMono(
                    fontSize: 11, color: _T.textPrimary)),
          ),
        ],
      ),
    );
  }

  String _formatTs(dynamic ts) {
    if (ts == null) return '—';
    try {
      final dt = DateTime.fromMillisecondsSinceEpoch(
          (ts as num).toInt() * 1000);
      return '${dt.day}/${dt.month}/${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '$ts';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2: Add Block
// ─────────────────────────────────────────────────────────────────────────────

class _AddBlockTab extends StatefulWidget {
  const _AddBlockTab();

  @override
  State<_AddBlockTab> createState() => _AddBlockTabState();
}

class _AddBlockTabState extends State<_AddBlockTab> {
  final _studentIdCtrl = TextEditingController();
  final _courseCtrl = TextEditingController();
  final _creditsCtrl = TextEditingController();
  String? _selectedCreator;

  // Authorized nodes from backend (pre-filled with known ones)
  static const _knownNodes = [
    'AIIMS','IITB','IITD','IITK','IITM','IITKGP','IITR','IITG','IITBH',
    'IISc','IISER','NITK','NITR','NITW','NITD','NITJ','NITC','NITP','NITM',
    'NITG','BITS','IIIT-H','IIIT-B','IIIT-D','IIIT-NR','ISI','TIFR','JNU',
    'DU','AMU','BHU','PU','AU','CU','MU','GU','RU','SU','TU','VIT','SRM',
    'MIT','SNU','Ashoka','OPJGU','JGU','IGNOU','IIM-A','IIM-B','IIM-C','IIM-L'
  ];

  @override
  void dispose() {
    _studentIdCtrl.dispose();
    _courseCtrl.dispose();
    _creditsCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final sid = _studentIdCtrl.text.trim();
    final course = _courseCtrl.text.trim();
    final creditsStr = _creditsCtrl.text.trim();
    final creator = _selectedCreator;

    if (sid.isEmpty || course.isEmpty || creditsStr.isEmpty || creator == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill all fields.',
              style: GoogleFonts.inter(color: _T.textPrimary)),
          backgroundColor: _T.card,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final credits = int.tryParse(creditsStr);
    if (credits == null || credits < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Credits must be a positive number.',
              style: GoogleFonts.inter(color: _T.textPrimary)),
          backgroundColor: _T.card,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    context.read<BlockchainBloc>().add(BCAddBlock(
          studentId: sid,
          course: course,
          credits: credits,
          creator: creator,
        ));

    // Clear fields on submit
    _studentIdCtrl.clear();
    _courseCtrl.clear();
    _creditsCtrl.clear();
    setState(() => _selectedCreator = null);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BlockchainBloc, BlockchainState>(
      builder: (ctx, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sectionHeader('New Academic Record'),
              const SizedBox(height: 16),
              _field('Student ID', _studentIdCtrl,
                  hint: 'e.g. STU2024001'),
              const SizedBox(height: 12),
              _field('Course Name', _courseCtrl,
                  hint: 'e.g. Data Structures'),
              const SizedBox(height: 12),
              _field('Credits', _creditsCtrl,
                  hint: 'e.g. 4',
                  inputType: TextInputType.number),
              const SizedBox(height: 12),

              // Creator dropdown
              Container(
                decoration: BoxDecoration(
                  color: _T.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _T.border),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCreator,
                    hint: Text('Select Authorized Node (Creator)',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: _T.textSecondary)),
                    dropdownColor: _T.card,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: _T.textSecondary),
                    items: _knownNodes
                        .map((n) => DropdownMenuItem(
                              value: n,
                              child: Text(n,
                                  style: GoogleFonts.robotoMono(
                                      fontSize: 13,
                                      color: _T.textPrimary)),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCreator = v),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit
              state is BCLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: _T.accent))
                  : FilledButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.add_rounded),
                      label: Text('ADD TO BLOCKCHAIN',
                          style: GoogleFonts.spaceMono(
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                      style: FilledButton.styleFrom(
                        backgroundColor: _T.accent,
                        foregroundColor: _T.bg,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),

              // Result card
              if (state is BCBlockAdded && state.block != null) ...[
                const SizedBox(height: 20),
                _sectionHeader('Block Added'),
                const SizedBox(height: 10),
                _BlockCard(block: state.block!, isGenesis: false),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _field(String label, TextEditingController ctrl,
      {String hint = '', TextInputType? inputType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 11,
                color: _T.textSecondary,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: _T.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _T.border),
          ),
          child: TextFormField(
            controller: ctrl,
            keyboardType: inputType,
            style:
                GoogleFonts.robotoMono(fontSize: 13, color: _T.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.robotoMono(
                  fontSize: 12, color: _T.textSecondary.withOpacity(0.5)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 3: Search Student
// ─────────────────────────────────────────────────────────────────────────────

class _SearchTab extends StatefulWidget {
  const _SearchTab();

  @override
  State<_SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<_SearchTab> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _search() {
    final id = _ctrl.text.trim();
    if (id.isEmpty) return;
    context.read<BlockchainBloc>().add(BCSearchStudent(id));
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BlockchainBloc, BlockchainState>(
      builder: (ctx, state) {
        return Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: _T.card,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _T.border),
                      ),
                      child: TextFormField(
                        controller: _ctrl,
                        style: GoogleFonts.robotoMono(
                            fontSize: 13, color: _T.textPrimary),
                        onFieldSubmitted: (_) => _search(),
                        decoration: InputDecoration(
                          hintText: 'Enter Student ID…',
                          hintStyle: GoogleFonts.robotoMono(
                              fontSize: 12,
                              color: _T.textSecondary.withOpacity(0.5)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          prefixIcon: const Icon(Icons.search_rounded,
                              color: _T.textSecondary, size: 18),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: _search,
                    style: FilledButton.styleFrom(
                      backgroundColor: _T.accent,
                      foregroundColor: _T.bg,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      minimumSize: const Size(52, 48),
                    ),
                    child: const Icon(Icons.search_rounded),
                  ),
                ],
              ),
            ),

            // Results
            Expanded(
              child: Builder(builder: (_) {
                if (state is BCLoading) return const _Loader();
                if (state is BCSearchResult) {
                  if (state.records.isEmpty) {
                    return _emptySearch(state.studentId);
                  }
                  return _buildResults(state);
                }
                return _searchHint();
              }),
            ),
          ],
        );
      },
    );
  }

  Widget _buildResults(BCSearchResult state) {
    final totalCredits = state.records.fold<int>(
        0, (sum, b) => sum + ((b['credits'] ?? 0) as num).toInt());

    return Column(
      children: [
        // Summary
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _T.accent.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _T.accent.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              const Icon(Icons.school_rounded, color: _T.accent, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(state.studentId,
                        style: GoogleFonts.spaceMono(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _T.textPrimary)),
                    Text(
                        '${state.records.length} course(s) · $totalCredits total credits',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: _T.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: state.records.length,
            itemBuilder: (ctx, i) => _BlockCard(
                block: state.records[i], isGenesis: false),
          ),
        ),
      ],
    );
  }

  Widget _emptySearch(String id) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_search_rounded,
                color: _T.textSecondary, size: 52),
            const SizedBox(height: 12),
            Text('No records found for "$id"',
                style: GoogleFonts.inter(
                    fontSize: 14, color: _T.textSecondary)),
          ],
        ),
      );

  Widget _searchHint() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.manage_search_rounded,
                color: _T.textSecondary, size: 52),
            const SizedBox(height: 12),
            Text('Enter a student ID to search the chain.',
                style: GoogleFonts.inter(
                    fontSize: 13, color: _T.textSecondary)),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 4: Nodes
// ─────────────────────────────────────────────────────────────────────────────

class _NodesTab extends StatefulWidget {
  const _NodesTab();

  @override
  State<_NodesTab> createState() => _NodesTabState();
}

class _NodesTabState extends State<_NodesTab> {
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<BlockchainBloc>().add(const BCLoadNodes());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BlockchainBloc, BlockchainState>(
      builder: (ctx, state) {
        return Column(
          children: [
            // Add node bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: _T.card,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _T.border),
                      ),
                      child: TextFormField(
                        controller: _ctrl,
                        style: GoogleFonts.robotoMono(
                            fontSize: 13, color: _T.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'New node name…',
                          hintStyle: GoogleFonts.robotoMono(
                              fontSize: 12,
                              color: _T.textSecondary.withOpacity(0.5)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: () {
                      final node = _ctrl.text.trim();
                      if (node.isEmpty) return;
                      ctx.read<BlockchainBloc>().add(BCAddNode(node));
                      _ctrl.clear();
                      FocusScope.of(context).unfocus();
                      // Reload nodes after add
                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (context.mounted) {
                          ctx.read<BlockchainBloc>().add(const BCLoadNodes());
                        }
                      });
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: _T.purple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      minimumSize: const Size(52, 48),
                    ),
                    child: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
            ),

            // Node list
            if (state is BCLoading) const _Loader(),
            if (state is BCNodesLoaded)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '${state.nodes.length} authorized nodes',
                        style: GoogleFonts.spaceMono(
                            fontSize: 11, color: _T.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: state.nodes.length,
                        itemBuilder: (ctx, i) => Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: _T.card,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _T.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.account_balance_rounded,
                                  color: _T.purple, size: 16),
                              const SizedBox(width: 10),
                              Text(
                                state.nodes[i],
                                style: GoogleFonts.robotoMono(
                                    fontSize: 13, color: _T.textPrimary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared widgets
// ─────────────────────────────────────────────────────────────────────────────

class _Loader extends StatelessWidget {
  const _Loader();
  @override
  Widget build(BuildContext context) => const Center(
        child: CircularProgressIndicator(color: _T.accent),
      );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, color: _T.error, size: 48),
              const SizedBox(height: 16),
              Text('Connection Error',
                  style: GoogleFonts.spaceMono(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _T.error)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _T.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: _T.error.withOpacity(0.25)),
                ),
                child: Text(message,
                    style: GoogleFonts.robotoMono(
                        fontSize: 11, color: _T.textPrimary),
                    textAlign: TextAlign.center),
              ),
            ],
          ),
        ),
      );
}

Widget _sectionHeader(String title) => Text(
      title,
      style: GoogleFonts.spaceMono(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: _T.textPrimary,
          letterSpacing: 0.5),
    );
