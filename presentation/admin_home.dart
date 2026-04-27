// lib/presentation/admin_home.dart
// ─────────────────────────────────────────────────────────────────────────────
// Admin Home — full access: chain, add block, search, nodes, register student
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:edi_translator/application/auth_bloc.dart';
import 'package:edi_translator/application/blockchain_bloc.dart';
import 'package:edi_translator/data/auth_model.dart';
import 'package:edi_translator/data/auth_api.dart';
import 'package:edi_translator/data/blockchain_api.dart';

class _T {
  static const bg = Color(0xFF0D0F14);
  static const surface = Color(0xFF151922);
  static const card = Color(0xFF1C2230);
  static const border = Color(0xFF2A3347);
  static const accent = Color(0xFF00E5A0);
  static const accentDim = Color(0xFF00996B);
  static const purple = Color(0xFF9D7FEA);
  static const blue = Color(0xFF4A9EFF);
  static const error = Color(0xFFFF4D6A);
  static const warning = Color(0xFFFFB020);
  static const textPrimary = Color(0xFFE8EDF5);
  static const textSecondary = Color(0xFF8A96AA);
}

class AdminHome extends StatefulWidget {
  const AdminHome({super.key, required this.session});
  final UserSession session;

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
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
              listener: _handleMessages,
              child: TabBarView(
                controller: _tab,
                children: [
                  _ChainTab(),
                  _AddBlockTab(adminNode: widget.session.adminNode!),
                  const _SearchTab(),
                  _NodesTab(adminNode: widget.session.adminNode!),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleMessages(BuildContext ctx, BlockchainState state) {
    String? msg;
    Color color = _T.accent;
    if (state is BCBlockAdded) {
      msg = state.message;
      color = state.message.contains('❌') ? _T.error : _T.accent;
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
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: Text(msg,
            style:
                GoogleFonts.robotoMono(fontSize: 12, color: _T.textPrimary)),
        backgroundColor: _T.card,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: color),
        ),
        duration: const Duration(seconds: 4),
      ));
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
            child: const Icon(Icons.admin_panel_settings_rounded,
                color: _T.purple, size: 16),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.session.adminNode!,
                  style: GoogleFonts.spaceMono(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _T.textPrimary)),
              Text('Admin Portal',
                  style: GoogleFonts.inter(
                      fontSize: 10, color: _T.textSecondary)),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: _T.accent, size: 20),
          onPressed: () => context.read<BlockchainBloc>()
            ..add(const BCCheckStatus())
            ..add(const BCLoadChain()),
        ),
        IconButton(
          icon: const Icon(Icons.logout_rounded,
              color: _T.textSecondary, size: 20),
          onPressed: () =>
              context.read<AuthBloc>().add(const AuthLogoutRequested()),
          tooltip: 'Logout',
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
        labelStyle: GoogleFonts.spaceMono(
            fontSize: 10, fontWeight: FontWeight.w700),
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
// Chain Tab
// ─────────────────────────────────────────────────────────────────────────────

class _ChainTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BlockchainBloc, BlockchainState>(
      builder: (ctx, state) {
        if (state is BCLoading) return _loader();
        if (state is BCChainLoaded) return _buildList(state.chain);
        if (state is BCError) return _errView(state.message);
        return _loader();
      },
    );
  }

  Widget _buildList(List<Map<String, dynamic>> chain) {
    return Column(
      children: [
        Container(
          color: _T.surface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.link_rounded, color: _T.purple, size: 16),
              const SizedBox(width: 8),
              Text('${chain.length} blocks',
                  style: GoogleFonts.spaceMono(
                      fontSize: 12, color: _T.textPrimary)),
              const Spacer(),
              if (chain.isNotEmpty)
                Text('Latest: #${chain.last['index']}',
                    style: GoogleFonts.spaceMono(
                        fontSize: 10, color: _T.textSecondary)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: chain.length,
            itemBuilder: (ctx, i) {
              final block = chain[chain.length - 1 - i];
              return _BlockCard(
                  block: block, isGenesis: block['index'] == 0);
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add Block Tab (admin only — pre-fills creator with admin's node)
// ─────────────────────────────────────────────────────────────────────────────

class _AddBlockTab extends StatefulWidget {
  const _AddBlockTab({required this.adminNode});
  final String adminNode;

  @override
  State<_AddBlockTab> createState() => _AddBlockTabState();
}

class _AddBlockTabState extends State<_AddBlockTab> {
  final _sidCtrl = TextEditingController();
  final _courseCtrl = TextEditingController();
  final _creditsCtrl = TextEditingController();

  // Register student fields
  final _regSidCtrl = TextEditingController();
  final _regPwCtrl = TextEditingController();
  bool _registerMode = false;
  String? _registerMsg;

  @override
  void dispose() {
    _sidCtrl.dispose();
    _courseCtrl.dispose();
    _creditsCtrl.dispose();
    _regSidCtrl.dispose();
    _regPwCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final sid = _sidCtrl.text.trim();
    final course = _courseCtrl.text.trim();
    final credits = int.tryParse(_creditsCtrl.text.trim()) ?? 0;
    if (sid.isEmpty || course.isEmpty || credits < 1) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Fill all fields with valid values.',
            style: GoogleFonts.inter(color: _T.textPrimary)),
        backgroundColor: _T.card,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    context.read<BlockchainBloc>().add(BCAddBlock(
          studentId: sid,
          course: course,
          credits: credits,
          creator: widget.adminNode,
        ));
    _sidCtrl.clear();
    _courseCtrl.clear();
    _creditsCtrl.clear();
    FocusScope.of(context).unfocus();
  }

  Future<void> _registerStudent() async {
    final sid = _regSidCtrl.text.trim();
    final pw = _regPwCtrl.text;
    if (sid.isEmpty || pw.isEmpty) return;
    try {
      final msg = await AuthApi.registerStudent(
        studentId: sid,
        password: pw,
        university: widget.adminNode,
      );
      setState(() {
        _registerMsg = msg;
        _regSidCtrl.clear();
        _regPwCtrl.clear();
      });
    } on ApiException catch (e) {
      setState(() => _registerMsg = e.message);
    } catch (e) {
      setState(() => _registerMsg = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BlockchainBloc, BlockchainState>(
      builder: (ctx, state) {
        final loading = state is BCLoading;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Creator badge
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _T.purple.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _T.purple.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_rounded,
                        color: _T.purple, size: 16),
                    const SizedBox(width: 8),
                    Text('Issuing as: ',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: _T.textSecondary)),
                    Text(widget.adminNode,
                        style: GoogleFonts.spaceMono(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _T.purple)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _sectionLabel('Add Academic Record'),
              const SizedBox(height: 12),
              _field('Student ID', _sidCtrl, 'e.g. STU2024001'),
              const SizedBox(height: 10),
              _field('Course Name', _courseCtrl, 'e.g. Data Structures'),
              const SizedBox(height: 10),
              _field('Credits', _creditsCtrl, 'e.g. 4',
                  type: TextInputType.number),
              const SizedBox(height: 20),
              loading
                  ? const Center(
                      child: CircularProgressIndicator(color: _T.accent))
                  : FilledButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.add_rounded),
                      label: Text('ADD TO BLOCKCHAIN',
                          style: GoogleFonts.spaceMono(
                              fontSize: 13, fontWeight: FontWeight.w700)),
                      style: FilledButton.styleFrom(
                        backgroundColor: _T.accent,
                        foregroundColor: _T.bg,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),

              const SizedBox(height: 28),
              const Divider(color: _T.border),
              const SizedBox(height: 16),

              // Register student section
              Row(
                children: [
                  _sectionLabel('Register New Student'),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                        _registerMode
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: _T.textSecondary,
                        size: 20),
                    onPressed: () =>
                        setState(() => _registerMode = !_registerMode),
                  ),
                ],
              ),
              if (_registerMode) ...[
                const SizedBox(height: 12),
                _field('Student ID', _regSidCtrl, 'e.g. STU2024002'),
                const SizedBox(height: 10),
                _field('Temporary Password', _regPwCtrl, 'Set initial password',
                    obscure: true),
                const SizedBox(height: 6),
                Text('University will be set to: ${widget.adminNode}',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: _T.textSecondary)),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _registerStudent,
                  icon: const Icon(Icons.person_add_rounded, size: 16),
                  label: Text('Register Student',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _T.accent,
                    side: const BorderSide(color: _T.accent),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                if (_registerMsg != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _registerMsg!.contains('✅')
                          ? _T.accent.withOpacity(0.08)
                          : _T.error.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: _registerMsg!.contains('✅')
                              ? _T.accent.withOpacity(0.3)
                              : _T.error.withOpacity(0.3)),
                    ),
                    child: Text(_registerMsg!,
                        style: GoogleFonts.robotoMono(
                            fontSize: 11, color: _T.textPrimary)),
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _field(String label, TextEditingController ctrl, String hint,
      {TextInputType? type, bool obscure = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 11,
                color: _T.textSecondary,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            color: _T.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _T.border),
          ),
          child: TextFormField(
            controller: ctrl,
            keyboardType: type,
            obscureText: obscure,
            style:
                GoogleFonts.robotoMono(fontSize: 13, color: _T.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.robotoMono(
                  fontSize: 12,
                  color: _T.textSecondary.withOpacity(0.5)),
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
// Search Tab
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BlockchainBloc, BlockchainState>(
      builder: (ctx, state) {
        return Column(
          children: [
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
                        onFieldSubmitted: (_) => _search(ctx),
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
                    onPressed: () => _search(ctx),
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
            Expanded(
              child: Builder(builder: (_) {
                if (state is BCLoading) return _loader();
                if (state is BCSearchResult) {
                  if (state.records.isEmpty) {
                    return Center(
                        child: Text('No records for "${state.studentId}"',
                            style: GoogleFonts.inter(
                                color: _T.textSecondary)));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.records.length,
                    itemBuilder: (ctx, i) =>
                        _BlockCard(block: state.records[i], isGenesis: false),
                  );
                }
                return Center(
                    child: Text('Search by student ID',
                        style: GoogleFonts.inter(color: _T.textSecondary)));
              }),
            ),
          ],
        );
      },
    );
  }

  void _search(BuildContext ctx) {
    final id = _ctrl.text.trim();
    if (id.isEmpty) return;
    ctx.read<BlockchainBloc>().add(BCSearchStudent(id));
    FocusScope.of(context).unfocus();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Nodes Tab
// ─────────────────────────────────────────────────────────────────────────────

class _NodesTab extends StatefulWidget {
  const _NodesTab({required this.adminNode});
  final String adminNode;

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
                      Future.delayed(const Duration(milliseconds: 600), () {
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
            if (state is BCLoading) Expanded(child: _loader()),
            if (state is BCNodesLoaded)
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: state.nodes.length,
                  itemBuilder: (ctx, i) {
                    final isMe = state.nodes[i] == widget.adminNode;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isMe
                            ? _T.purple.withOpacity(0.1)
                            : _T.card,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: isMe
                                ? _T.purple.withOpacity(0.3)
                                : _T.border),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.account_balance_rounded,
                              color: isMe ? _T.purple : _T.textSecondary,
                              size: 16),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(state.nodes[i],
                                style: GoogleFonts.robotoMono(
                                    fontSize: 13,
                                    color: _T.textPrimary)),
                          ),
                          if (isMe)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _T.purple.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('YOU',
                                  style: GoogleFonts.spaceMono(
                                      fontSize: 9, color: _T.purple)),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared: Block card with hash expand
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
    final isGenesis = widget.isGenesis;
    final color = isGenesis ? _T.warning : _T.accent;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _T.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: _expanded ? color.withOpacity(0.4) : _T.border,
            width: _expanded ? 1.5 : 1),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Center(
                      child: Text('#${b['index'] ?? 0}',
                          style: GoogleFonts.spaceMono(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: color)),
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
                              color: _T.textPrimary),
                        ),
                        Text(
                          isGenesis
                              ? 'Chain origin'
                              : '${b['course'] ?? '—'} · ${b['credits'] ?? 0} cr',
                          style: GoogleFonts.inter(
                              fontSize: 11, color: _T.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  if (!isGenesis)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _T.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                            color: _T.purple.withOpacity(0.3)),
                      ),
                      child: Text('${b['creator'] ?? '?'}',
                          style: GoogleFonts.spaceMono(
                              fontSize: 9, color: _T.purple)),
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
          if (_expanded) ...[
            const Divider(height: 1, color: _T.border),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _hashRow(context, 'Hash', '${b['hash'] ?? ''}', _T.accent),
                  const SizedBox(height: 8),
                  _hashRow(context, 'Prev Hash',
                      '${b['prev_hash'] ?? ''}', _T.blue),
                  const SizedBox(height: 6),
                  _row('Timestamp', _formatTs(b['timestamp'])),
                  if (!isGenesis) ...[
                    _row('Student ID', '${b['student_id'] ?? '—'}'),
                    _row('Course', '${b['course'] ?? '—'}'),
                    _row('Credits', '${b['credits'] ?? 0}'),
                    _row('Creator', '${b['creator'] ?? '—'}'),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _hashRow(BuildContext ctx, String label, String value, Color color) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.inter(fontSize: 10, color: _T.textSecondary)),
          const SizedBox(height: 2),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                content: Text('Copied',
                    style: GoogleFonts.robotoMono(
                        fontSize: 11, color: _T.textPrimary)),
                backgroundColor: _T.card,
                duration: const Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
              ));
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.07),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Text(value,
                  style: GoogleFonts.robotoMono(fontSize: 9, color: color),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2),
            ),
          ),
        ],
      );

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            SizedBox(
                width: 80,
                child: Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 11, color: _T.textSecondary))),
            Expanded(
                child: Text(value,
                    style: GoogleFonts.robotoMono(
                        fontSize: 11, color: _T.textPrimary))),
          ],
        ),
      );

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
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

Widget _loader() =>
    const Center(child: CircularProgressIndicator(color: _T.accent));

Widget _errView(String msg) => Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, color: _T.error, size: 48),
            const SizedBox(height: 16),
            Text(msg,
                style: GoogleFonts.robotoMono(
                    fontSize: 11, color: _T.textSecondary),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );

Widget _sectionLabel(String t) => Text(t,
    style: GoogleFonts.spaceMono(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: _T.textPrimary));
