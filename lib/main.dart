import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/biometric_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';
import 'models/user_profile.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const AuthenticationFlow(),
    );
  }
}

class AuthenticationFlow extends StatefulWidget {
  const AuthenticationFlow({super.key});

  @override
  State<AuthenticationFlow> createState() => _AuthenticationFlowState();
}

class _AuthenticationFlowState extends State<AuthenticationFlow> {
  final AuthService _authService = AuthService();
  bool _showBiometric = true;
  bool _biometricDone = false;

  @override
  void initState() {
    super.initState();
    _authService.authStateChanges.listen((user) {
      if (_biometricDone && mounted) {
        setState(() {});
      }
    });
  }

  void _onLoginSuccess(UserProfile profile) {
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => HomeScreen(userProfile: profile),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showBiometric) {
      return BiometricScreen(
        onSuccess: () {
          setState(() {
            _showBiometric = false;
            _biometricDone = true;
          });
        },
      );
    }

    return FutureBuilder(
      future: _authService.currentUser != null
          ? _authService.getUserProfile(_authService.currentUser!.uid)
          : Future.value(null),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final profile = snapshot.data as UserProfile?;

        if (profile != null) {
          return HomeScreen(userProfile: profile);
        }

        return LoginScreen(onLoginSuccess: _onLoginSuccess);
      },
    );
  }
}
