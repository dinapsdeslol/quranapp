import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _fnameCtrl = TextEditingController();
  final _lnameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final AuthService _auth = AuthService();

  DateTime? _birthDate;
  bool _loading = false;
  String _error = '';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2005),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _register() async {
    if (!_form.currentState!.validate()) return;
    if (_birthDate == null) { setState(() => _error = 'Select your date of birth'); return; }
    if (_auth.calculateAge(_birthDate!) < 13) { setState(() => _error = 'Must be 13 or older'); return; }

    setState(() { _loading = true; _error = ''; });
    try {
      await _auth.register(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        firstName: _fnameCtrl.text.trim(),
        lastName: _lnameCtrl.text.trim(),
        birthDate: _birthDate!,
        phoneNumber: _phoneCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account created! Please login.')));
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _fnameCtrl.dispose(); _lnameCtrl.dispose(); _emailCtrl.dispose();
    _passCtrl.dispose(); _confirmCtrl.dispose(); _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.white)),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0D47A1), Color(0xFF1565C0)])),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.person_add, size: 80, color: Colors.white),
                  const SizedBox(height: 16),
                  const Text('Create Account', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  if (_error.isNotEmpty) Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(8)), child: Text(_error, style: const TextStyle(color: Colors.white70)),),
                  if (_error.isNotEmpty) const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _field(_fnameCtrl, 'First Name *', Icons.person, (v) => v == null || v.isEmpty ? 'Required' : null)),
                      const SizedBox(width: 12),
                      Expanded(child: _field(_lnameCtrl, 'Last Name *', Icons.person, (v) => v == null || v.isEmpty ? 'Required' : null)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _field(_emailCtrl, 'Email *', Icons.email, (v) => v == null || v.isEmpty ? 'Required' : null, TextInputType.emailAddress),
                  const SizedBox(height: 12),
                  _field(_passCtrl, 'Password *', Icons.lock, (v) => v == null || v.length < 6 ? 'Min 6 chars' : null, TextInputType.visiblePassword, true),
                  const SizedBox(height: 12),
                  _field(_confirmCtrl, 'Confirm *', Icons.lock, (v) => v != _passCtrl.text ? 'No match' : null, TextInputType.visiblePassword, true),
                  const SizedBox(height: 12),
                  _field(_phoneCtrl, 'Phone', Icons.phone, null, TextInputType.phone),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.3))),
                      child: Row(children: [
                        const Icon(Icons.calendar_today, color: Colors.white70),
                        const SizedBox(width: 12),
                        Text(_birthDate != null ? DateFormat('dd/MM/yyyy').format(_birthDate!) : 'Date of Birth *', style: TextStyle(color: _birthDate != null ? Colors.white : Colors.white70, fontSize: 16)),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loading ? null : _register,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF0D47A1), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Create Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon, String? Function(String?)? validator, [TextInputType? type, bool obs = false]) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      obscureText: obs,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label, labelStyle: const TextStyle(color: Colors.white70), prefixIcon: Icon(icon, color: Colors.white70),
        filled: true, fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white)),
      ),
      validator: validator,
    );
  }
}
