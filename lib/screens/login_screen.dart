import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/auth_service.dart';
import 'register_screen.dart';
import 'forgot_screen.dart';

class LoginScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onLogin;
  const LoginScreen({super.key, required this.onLogin});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController(text: 'demo@quran.app');
  final _passCtrl = TextEditingController(text: 'demo123');
  bool _loading = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    widget.onLogin({'firstName': 'Demo', 'lastName': 'User', 'email': 'demo@quran.app'});
  }

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _loading = true; _error = ''; });

    try {
      if (kIsWeb) {
        await Future.delayed(const Duration(milliseconds: 800));
        widget.onLogin({'firstName': 'User', 'lastName': 'Demo', 'email': _emailCtrl.text});
        return;
      }
      final data = await AuthService().login(_emailCtrl.text.trim(), _passCtrl.text);
      if (data != null && mounted) {
        widget.onLogin(data);
      } else if (mounted) {
        setState(() => _error = 'Invalid credentials');
      }
    } on Exception catch (e) {
      final msg = e.toString();
      if (msg.contains('network') || msg.contains('timeout') || msg.contains('unreachable')) {
        if (mounted) widget.onLogin({'firstName': 'Demo', 'lastName': 'User', 'email': _emailCtrl.text});
        return;
      }
      setState(() => _error = msg.replaceAll('Exception: ', ''));
    } catch (e) {
      if (e.toString().contains('network') || e.toString().contains('timeout')) {
        if (mounted) widget.onLogin({'firstName': 'Demo', 'lastName': 'User', 'email': _emailCtrl.text});
        return;
      }
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _form,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.lock_outline, size: 80, color: Colors.white),
                    const SizedBox(height: 16),
                    const Text('Welcome Back', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text(kIsWeb ? 'Demo mode - any email works' : 'Sign in to continue', style: const TextStyle(fontSize: 14, color: Colors.white70), textAlign: TextAlign.center),
                    const SizedBox(height: 32),
                    if (_error.isNotEmpty) Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(8)), child: Text(_error, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center)),
                    if (_error.isNotEmpty) const SizedBox(height: 16),
                    TextFormField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, style: const TextStyle(color: Colors.white), decoration: _inputStyle('Email', Icons.email), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
                    const SizedBox(height: 16),
                    TextFormField(controller: _passCtrl, obscureText: true, style: const TextStyle(color: Colors.white), decoration: _inputStyle('Password', Icons.lock), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
                    const SizedBox(height: 8),
                    if (!kIsWeb) Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotScreen())), child: const Text('Forgot Password?', style: TextStyle(color: Colors.white70))),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loading ? null : _login,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF0D47A1), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Sign In', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    if (!kIsWeb) const SizedBox(height: 20),
                    if (!kIsWeb) Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account? ", style: TextStyle(color: Colors.white70)),
                        GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())), child: const Text('Sign Up', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label, labelStyle: const TextStyle(color: Colors.white70), prefixIcon: Icon(icon, color: Colors.white70),
      filled: true, fillColor: Colors.white.withOpacity(0.1),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white)),
    );
  }
}
