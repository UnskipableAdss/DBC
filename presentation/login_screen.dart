// lib/presentation/login_screen.dart
// ─────────────────────────────────────────────────────────────────────────────
// Login Screen — Student tab + Admin tab + Register flow
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:edi_translator/application/auth_bloc.dart';
import 'package:edi_translator/data/edi_constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Theme
// ─────────────────────────────────────────────────────────────────────────────
class _T {
  static const bg = Color(0xFF0D0F14);
  static const surface = Color(0xFF151922);
  static const card = Color(0xFF1C2230);
  static const border = Color(0xFF2A3347);
  static const accent = Color(0xFF00E5A0);
  static const purple = Color(0xFF9D7FEA);
  static const error = Color(0xFFFF4D6A);
  static const textPrimary = Color(0xFFE8EDF5);
  static const textSecondary = Color(0xFF8A96AA);
  static const warning = Color(0xFFFFB020);
}

// ─────────────────────────────────────────────────────────────────────────────
// Login Screen
// ─────────────────────────────────────────────────────────────────────────────

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
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
      body: SafeArea(
        child: BlocListener<AuthBloc, AuthState>(
          listener: (ctx, state) {
            if (state is AuthError) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(
                  content: Text(state.message,
                      style: GoogleFonts.robotoMono(
                          fontSize: 12, color: _T.textPrimary)),
                  backgroundColor: _T.card,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: _T.error),
                  ),
                ),
              );
            }
          },
          child: Column(
            children: [
              const SizedBox(height: 48),
              _buildHeader(),
              const SizedBox(height: 32),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tab,
                  children: const [
                    _StudentLoginTab(),
                    _AdminLoginTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: _T.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _T.accent.withOpacity(0.3), width: 1.5),
          ),
          child: const Icon(Icons.link_rounded, color: _T.accent, size: 36),
        ),
        const SizedBox(height: 16),
        Text(
          'EDI Blockchain',
          style: GoogleFonts.spaceMono(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: _T.textPrimary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Academic Records on Chain',
          style: GoogleFonts.inter(fontSize: 13, color: _T.textSecondary),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: _T.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _T.border),
        ),
        child: TabBar(
          controller: _tab,
          labelStyle: GoogleFonts.spaceMono(
              fontSize: 12, fontWeight: FontWeight.w700),
          unselectedLabelStyle: GoogleFonts.spaceMono(fontSize: 12),
          labelColor: _T.bg,
          unselectedLabelColor: _T.textSecondary,
          indicator: BoxDecoration(
            color: _T.accent,
            borderRadius: BorderRadius.circular(10),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.school_rounded, size: 15),
                  SizedBox(width: 6),
                  Text('STUDENT'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.admin_panel_settings_rounded, size: 15),
                  SizedBox(width: 6),
                  Text('ADMIN'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Student Login Tab
// ─────────────────────────────────────────────────────────────────────────────

class _StudentLoginTab extends StatefulWidget {
  const _StudentLoginTab();

  @override
  State<_StudentLoginTab> createState() => _StudentLoginTabState();
}

class _StudentLoginTabState extends State<_StudentLoginTab> {
  final _idCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  bool _obscure = true;
  bool _showRegister = false;

  // Register fields
  final _regIdCtrl = TextEditingController();
  final _regPwCtrl = TextEditingController();
  String? _regUniversity;

  @override
  void dispose() {
    _idCtrl.dispose();
    _pwCtrl.dispose();
    _regIdCtrl.dispose();
    _regPwCtrl.dispose();
    super.dispose();
  }

  void _login() {
    final id = _idCtrl.text.trim();
    final pw = _pwCtrl.text;
    if (id.isEmpty || pw.isEmpty) return;
    context.read<AuthBloc>().add(AuthLoginRequested(
          role: 'student',
          username: id,
          password: pw,
        ));
    FocusScope.of(context).unfocus();
  }

  void _register() {
    final id = _regIdCtrl.text.trim();
    final pw = _regPwCtrl.text;
    final uni = _regUniversity;
    if (id.isEmpty || pw.isEmpty || uni == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fill all fields.',
              style: GoogleFonts.inter(color: _T.textPrimary)),
          backgroundColor: _T.card,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    context.read<AuthBloc>().add(AuthRegisterRequested(
          studentId: id,
          password: pw,
          university: uni,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (ctx, state) {
        if (state is AuthRegistered) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text(state.message,
                  style: GoogleFonts.robotoMono(
                      fontSize: 12, color: _T.textPrimary)),
              backgroundColor: _T.card,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: _T.accent),
              ),
            ),
          );
          setState(() => _showRegister = false);
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (ctx, state) {
            final loading = state is AuthLoading;

            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _showRegister
                  ? _buildRegisterForm(loading)
                  : _buildLoginForm(loading),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoginForm(bool loading) {
    return Column(
      key: const ValueKey('student-login'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        _label('Student ID'),
        const SizedBox(height: 6),
        _inputField(
          controller: _idCtrl,
          hint: 'e.g. STU2024001',
          prefix: Icons.badge_rounded,
        ),
        const SizedBox(height: 16),
        _label('Password'),
        const SizedBox(height: 6),
        _inputField(
          controller: _pwCtrl,
          hint: '••••••••',
          prefix: Icons.lock_rounded,
          obscure: _obscure,
          suffix: IconButton(
            icon: Icon(
                _obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                color: _T.textSecondary,
                size: 18),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
        const SizedBox(height: 24),
        loading
            ? const Center(child: CircularProgressIndicator(color: _T.accent))
            : _primaryButton('LOGIN AS STUDENT', _login, _T.accent),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => setState(() => _showRegister = true),
            child: Text(
              'New student? Register here',
              style: GoogleFonts.inter(fontSize: 12, color: _T.accent),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterForm(bool loading) {
    return Column(
      key: const ValueKey('student-register'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded,
                  color: _T.textSecondary, size: 20),
              onPressed: () => setState(() => _showRegister = false),
            ),
            Text('Register Student Account',
                style: GoogleFonts.spaceMono(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _T.textPrimary)),
          ],
        ),
        const SizedBox(height: 16),
        _label('Student ID'),
        const SizedBox(height: 6),
        _inputField(
            controller: _regIdCtrl,
            hint: 'e.g. STU2024001',
            prefix: Icons.badge_rounded),
        const SizedBox(height: 14),
        _label('Password'),
        const SizedBox(height: 6),
        _inputField(
            controller: _regPwCtrl,
            hint: 'Choose a password',
            prefix: Icons.lock_rounded,
            obscure: true),
        const SizedBox(height: 14),
        _label('University'),
        const SizedBox(height: 6),
        _universityDropdown(),
        const SizedBox(height: 24),
        loading
            ? const Center(child: CircularProgressIndicator(color: _T.accent))
            : _primaryButton('CREATE ACCOUNT', _register, const Color(0xFF00996B)),
      ],
    );
  }

  Widget _universityDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: _T.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _T.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _regUniversity,
          hint: Text('Select your university',
              style: GoogleFonts.inter(
                  fontSize: 13, color: _T.textSecondary)),
          dropdownColor: _T.card,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: _T.textSecondary),
          items: kSegmentNames.keys
              .toList()
              .where((_) => true)
              .toList()
              .isEmpty
              ? _nodeItems()
              : _nodeItems(),
          onChanged: (v) => setState(() => _regUniversity = v),
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> _nodeItems() {
    const nodes = [
      'AIIMS','IITB','IITD','IITK','IITM','IITKGP','IITR','IITG','IITBH',
      'IISc','IISER','NITK','NITR','NITW','NITD','NITJ','NITC','NITP','NITM',
      'NITG','BITS','IIIT-H','IIIT-B','IIIT-D','IIIT-NR','ISI','TIFR','JNU',
      'DU','AMU','BHU','PU','AU','CU','MU','GU','RU','SU','TU','VIT','SRM',
      'MIT','SNU','Ashoka','OPJGU','JGU','IGNOU','IIM-A','IIM-B','IIM-C','IIM-L'
    ];
    return nodes
        .map((n) => DropdownMenuItem(
              value: n,
              child: Text(n,
                  style: GoogleFonts.robotoMono(
                      fontSize: 13, color: _T.textPrimary)),
            ))
        .toList();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Admin Login Tab
// ─────────────────────────────────────────────────────────────────────────────

class _AdminLoginTab extends StatefulWidget {
  const _AdminLoginTab();

  @override
  State<_AdminLoginTab> createState() => _AdminLoginTabState();
}

class _AdminLoginTabState extends State<_AdminLoginTab> {
  final _nodeCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  bool _obscure = true;
  String? _selectedNode;

  @override
  void dispose() {
    _nodeCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  void _login() {
    final node = _selectedNode ?? _nodeCtrl.text.trim();
    final pw = _pwCtrl.text;
    if (node.isEmpty || pw.isEmpty) return;
    context.read<AuthBloc>().add(AuthLoginRequested(
          role: 'admin',
          username: node,
          password: pw,
        ));
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (ctx, state) {
          final loading = state is AuthLoading;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              // Info banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _T.purple.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _T.purple.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: _T.purple, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'PLEASE ENTER LOGIN DETAILS PROVIDED BY YOUR UNIVERSITY',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: _T.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _label('Institution / Node'),
              const SizedBox(height: 6),
              // Node dropdown
              Container(
                decoration: BoxDecoration(
                  color: _T.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _T.border),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedNode,
                    hint: Text('Select institution',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: _T.textSecondary)),
                    dropdownColor: _T.card,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: _T.textSecondary),
                    items: _nodes
                        .map((n) => DropdownMenuItem(
                              value: n,
                              child: Text(n,
                                  style: GoogleFonts.robotoMono(
                                      fontSize: 13,
                                      color: _T.textPrimary)),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedNode = v),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _label('Password'),
              const SizedBox(height: 6),
              _inputField(
                controller: _pwCtrl,
                hint: '••••••••',
                prefix: Icons.lock_rounded,
                obscure: _obscure,
                suffix: IconButton(
                  icon: Icon(
                      _obscure
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      color: _T.textSecondary,
                      size: 18),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              const SizedBox(height: 24),
              loading
                  ? const Center(
                      child: CircularProgressIndicator(color: _T.purple))
                  : _primaryButton(
                      'LOGIN AS ADMIN', _login, _T.purple),
            ],
          );
        },
      ),
    );
  }

  static const _nodes = [
    'AIIMS','IITB','IITD','IITK','IITM','IITKGP','IITR','IITG','IITBH',
    'IISc','IISER','NITK','NITR','NITW','NITD','NITJ','NITC','NITP','NITM',
    'NITG','BITS','IIIT-H','IIIT-B','IIIT-D','IIIT-NR','ISI','TIFR','JNU',
    'DU','AMU','BHU','PU','AU','CU','MU','GU','RU','SU','TU','VIT','SRM',
    'MIT','SNU','Ashoka','OPJGU','JGU','IGNOU','IIM-A','IIM-B','IIM-C','IIM-L'
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────



Widget _label(String text) => Text(
      text,
      style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _T.textSecondary),
    );

Widget _inputField({
  required TextEditingController controller,
  required String hint,
  required IconData prefix,
  bool obscure = false,
  Widget? suffix,
  TextInputType? inputType,
}) =>
    Container(
      decoration: BoxDecoration(
        color: _T.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _T.border),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: inputType,
        style: GoogleFonts.robotoMono(fontSize: 13, color: _T.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.robotoMono(
              fontSize: 12, color: _T.textSecondary.withOpacity(0.5)),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          prefixIcon: Icon(prefix, color: _T.textSecondary, size: 18),
          suffixIcon: suffix,
        ),
      ),
    );

Widget _primaryButton(String label, VoidCallback onTap, Color color) =>
    FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: color == _T.accent ? _T.bg : Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        label,
        style: GoogleFonts.spaceMono(
            fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );

