// lib/presentation/student_home.dart
// ─────────────────────────────────────────────────────────────────────────────
// Student Home — read-only view of their own records
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:edi_translator/application/auth_bloc.dart';
import 'package:edi_translator/application/blockchain_bloc.dart';
import 'package:edi_translator/data/auth_model.dart';

class _T {
  static const bg = Color(0xFF0D0F14);
  static const surface = Color(0xFF151922);
  static const card = Color(0xFF1C2230);
  static const border = Color(0xFF2A3347);
  static const accent = Color(0xFF00E5A0);
  static const error = Color(0xFFFF4D6A);
  static const textPrimary = Color(0xFFE8EDF5);
  static const textSecondary = Color(0xFF8A96AA);
  static const warning = Color(0xFFFFB020);
  static const blue = Color(0xFF4A9EFF);
}

class StudentHome extends StatefulWidget {
  const StudentHome({super.key, required this.session});
  final UserSession session;

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  @override
  void initState() {
    super.initState();
    // Auto-load this student's records on login
    context
        .read<BlockchainBloc>()
        .add(BCSearchStudent(widget.session.studentId!));
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    return Scaffold(
      backgroundColor: _T.bg,
      appBar: AppBar(
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
              child: const Icon(Icons.school_rounded, color: _T.accent, size: 16),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session.studentId!,
                    style: GoogleFonts.spaceMono(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _T.textPrimary)),
                Text(session.university ?? '',
                    style: GoogleFonts.inter(
                        fontSize: 10, color: _T.textSecondary)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _T.accent, size: 20),
            onPressed: () => context
                .read<BlockchainBloc>()
                .add(BCSearchStudent(session.studentId!)),
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
      ),
      body: BlocBuilder<BlockchainBloc, BlockchainState>(
        builder: (ctx, state) {
          if (state is BCLoading) {
            return const Center(
                child: CircularProgressIndicator(color: _T.accent));
          }

          if (state is BCError) {
            return _errorView(state.message);
          }

          if (state is BCSearchResult) {
            return _buildRecords(session, state);
          }

          return const Center(
              child: CircularProgressIndicator(color: _T.accent));
        },
      ),
    );
  }

  Widget _buildRecords(UserSession session, BCSearchResult state) {
    final records = state.records;
    final totalCredits = records.fold<int>(
        0, (sum, b) => sum + ((b['credits'] ?? 0) as num).toInt());

    return Column(
      children: [
        // Summary card
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _T.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _T.accent.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Academic Summary',
                        style: GoogleFonts.spaceMono(
                            fontSize: 11, color: _T.textSecondary)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _statChip('${records.length}', 'Courses', _T.accent),
                        const SizedBox(width: 12),
                        _statChip('$totalCredits', 'Credits', _T.blue),
                        const SizedBox(width: 12),
                        _statChip(
                            session.university ?? '—', 'University', _T.warning),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Records
        if (records.isEmpty)
          Expanded(child: _emptyRecords())
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: records.length,
              itemBuilder: (ctx, i) => _RecordCard(block: records[i]),
            ),
          ),
      ],
    );
  }

  Widget _statChip(String value, String label, Color color) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: GoogleFonts.spaceMono(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color)),
          Text(label,
              style: GoogleFonts.inter(fontSize: 9, color: _T.textSecondary)),
        ],
      );

  Widget _emptyRecords() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_rounded,
                color: _T.textSecondary.withOpacity(0.3), size: 64),
            const SizedBox(height: 16),
            Text('No records found on the chain yet.',
                style:
                    GoogleFonts.inter(fontSize: 14, color: _T.textSecondary)),
            const SizedBox(height: 6),
            Text('Your university will add them once processed.',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    color: _T.textSecondary.withOpacity(0.6))),
          ],
        ),
      );

  Widget _errorView(String msg) => Center(
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
              Text(msg,
                  style: GoogleFonts.robotoMono(
                      fontSize: 11, color: _T.textSecondary),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Record card (read-only, always expanded)
// ─────────────────────────────────────────────────────────────────────────────

class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.block});
  final Map<String, dynamic> block;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _T.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _T.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course name + credits
          Row(
            children: [
              const Icon(Icons.menu_book_rounded,
                  color: _T.accent, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${block['course'] ?? '—'}',
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _T.textPrimary),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _T.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border:
                      Border.all(color: _T.accent.withOpacity(0.3)),
                ),
                child: Text(
                  '${block['credits'] ?? 0} cr',
                  style: GoogleFonts.spaceMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _T.accent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: _T.border),
          const SizedBox(height: 10),
          // Meta info
          _meta('Issued by', '${block['creator'] ?? '—'}', _T.warning),
          const SizedBox(height: 4),
          _meta('Block #', '${block['index'] ?? '—'}', _T.textSecondary),
          const SizedBox(height: 4),
          _meta('Date', _formatTs(block['timestamp']), _T.textSecondary),
          const SizedBox(height: 8),
          // Hash (truncated)
          Text('Hash',
              style: GoogleFonts.inter(
                  fontSize: 10, color: _T.textSecondary)),
          const SizedBox(height: 3),
          Text(
            '${block['hash'] ?? ''}',
            style: GoogleFonts.robotoMono(
                fontSize: 9, color: _T.blue),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _meta(String label, String value, Color color) => Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(label,
                style: GoogleFonts.inter(
                    fontSize: 11, color: _T.textSecondary)),
          ),
          Text(value,
              style: GoogleFonts.robotoMono(fontSize: 11, color: color)),
        ],
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
