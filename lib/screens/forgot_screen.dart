import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ForgotScreen extends StatefulWidget {
  const ForgotScreen({super.key});

  @override
  State<ForgotScreen> createState() => _ForgotScreenState();
}

class _ForgotScreenState extends State<ForgotScreen> {
  final _ctrl = TextEditingController();
  final AuthService _auth = AuthService();
  bool _loading = false;
  String _msg = '';
  bool _sent = false;

  Future<void> _send() async {
    if (_ctrl.text.isEmpty) return;
    setState(() { _loading = true; _msg = ''; });
    try {
      await _auth.resetPassword(_ctrl.text.trim());
      setState(() { _sent = true; _msg = 'Reset email sent. Check your inbox.'; });
    } catch (e) {
      setState(() => _msg = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.white)),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0D47A1), Color(0xFF1565C0)])),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(_sent ? Icons.check_circle : Icons.lock_reset, size: 80, color: _sent ? Colors.greenAccent : Colors.white),
                  const SizedBox(height: 16),
                  const Text('Reset Password', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  if (_msg.isNotEmpty) Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _sent ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(8)), child: Text(_msg, style: const TextStyle(color: Colors.white70)),),
                  if (_msg.isNotEmpty) const SizedBox(height: 16),
                  if (!_sent) TextField(
                    controller: _ctrl,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Email', labelStyle: const TextStyle(color: Colors.white70), prefixIcon: const Icon(Icons.email, color: Colors.white70),
                      filled: true, fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loading ? null : _send,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF0D47A1), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(_sent ? 'Back to Login' : 'Send Reset Link'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
