// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:edi_translator/application/auth_bloc.dart';
import 'package:edi_translator/application/blockchain_bloc.dart';
import 'package:edi_translator/application/edi_bloc.dart';
import 'package:edi_translator/data/auth_model.dart';
import 'package:edi_translator/presentation/login_screen.dart';
import 'package:edi_translator/presentation/student_home.dart';
import 'package:edi_translator/presentation/admin_home.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0D0F14),
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const EDIApp());
}

class EDIApp extends StatelessWidget {
  const EDIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthBloc()),
        BlocProvider(create: (_) => BlockchainBloc()),
        BlocProvider(create: (_) => EDIBloc()),
      ],
      child: MaterialApp(
        title: 'EDI Blockchain',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF00E5A0),
            brightness: Brightness.dark,
            surface: const Color(0xFF151922),
          ),
          scaffoldBackgroundColor: const Color(0xFF0D0F14),
          textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        ),
        home: const _RootRouter(),
      ),
    );
  }
}

/// Listens to AuthBloc and routes to the correct screen.
class _RootRouter extends StatelessWidget {
  const _RootRouter();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (ctx, state) {
        if (state is AuthAuthenticated) {
          final session = state.session;
          if (session.isAdmin) return AdminHome(session: session);
          return StudentHome(session: session);
        }
        return const LoginScreen();
      },
    );
  }
}
