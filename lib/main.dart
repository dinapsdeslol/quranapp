import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'services/auth_service.dart';
import 'services/bio_service.dart';
import 'screens/bio_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await Firebase.initializeApp();
  }
  runApp(const QuranPlayerApp());
}

class QuranPlayerApp extends StatelessWidget {
  const QuranPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quran Player',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D47A1)),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      ),
      home: const AppFlow(),
    );
  }
}

class AppFlow extends StatefulWidget {
  const AppFlow({super.key});

  @override
  State<AppFlow> createState() => _AppFlowState();
}

class _AppFlowState extends State<AppFlow> {
  final AuthService? _auth = kIsWeb ? null : AuthService();
  final BioService? _bio = kIsWeb ? null : BioService();
  bool _showBio = false;
  bool _showLogin = false;
  Map<String, dynamic>? _userData;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      setState(() {
        _showBio = false;
        _showLogin = true;
      });
      return;
    }
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final isFirst = await _bio!.isFirstLaunch();
    if (isFirst) {
      setState(() => _showBio = true);
      return;
    }

    final user = _auth!.currentUser;
    if (user != null) {
      final data = await _auth!.getUserData(user.uid);
      if (data != null) {
        setState(() { _userData = data; _loggedIn = true; _showBio = false; _showLogin = false; });
      }
    }
  }

  void _onBioSuccess() {
    if (_loggedIn) return;
    setState(() { _showBio = false; _showLogin = true; });
  }

  void _onLogin(Map<String, dynamic> data) {
    setState(() { _userData = data; _loggedIn = true; _showLogin = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_showBio) {
      return BiometricScreen(onSuccess: _onBioSuccess);
    }

    if (_showLogin) {
      return LoginScreen(onLogin: _onLogin);
    }

    if (_loggedIn && _userData != null) {
      return HomeScreen(userData: _userData!);
    }

    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
