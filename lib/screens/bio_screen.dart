import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/bio_service.dart';

class BiometricScreen extends StatefulWidget {
  final VoidCallback onSuccess;
  const BiometricScreen({super.key, required this.onSuccess});

  @override
  State<BiometricScreen> createState() => _BiometricScreenState();
}

class _BiometricScreenState extends State<BiometricScreen> {
  final BioService _bio = BioService();
  String _msg = 'Verifying device...';
  bool _hasBio = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final available = await _bio.isBiometricAvailable();
    if (!available) {
      if (!mounted) return;
      setState(() {
        _msg = 'No fingerprint registered. Please set one up in Settings > Security.';
        _hasBio = false;
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _hasBio = true;
      _msg = 'Place your finger on the sensor';
    });
    await _tryAuth();
  }

  Future<void> _tryAuth() async {
    if (!mounted) return;
    setState(() => _msg = 'Place your finger on the sensor');

    final ok = await _bio.authenticate();
    if (ok) {
      try {
        final p = AudioPlayer();
        await p.play(AssetSource('sounds/success.mp3'));
        await Future.delayed(const Duration(milliseconds: 500));
        await p.dispose();
      } catch (e) {}
      await _bio.setFirstLaunchComplete();
      if (mounted) widget.onSuccess();
    } else {
      if (mounted) setState(() => _msg = 'Authentication failed. Tap the button to retry.');
    }
  }

  void _goSettings() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Setup Fingerprint'),
        content: const Text('Please go to Settings > Security and add a fingerprint to secure your device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF1976D2)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.fingerprint, size: 120, color: Colors.white.withOpacity(0.9)),
                  const SizedBox(height: 20),
                  const Text(
                    'Quran Player',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Secure Audio Experience',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _hasBio ? Icons.touch_app : Icons.security,
                          size: 48,
                          color: Colors.white70,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _msg,
                          style: const TextStyle(fontSize: 16, color: Colors.white, height: 1.5),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  if (_hasBio)
                    ElevatedButton.icon(
                      onPressed: _tryAuth,
                      icon: const Icon(Icons.fingerprint),
                      label: const Text('Retry Fingerprint'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF0D47A1),
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                  const SizedBox(height: 12),
                  if (!_hasBio)
                    ElevatedButton.icon(
                      onPressed: _goSettings,
                      icon: const Icon(Icons.settings),
                      label: const Text('Go to Settings'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF0D47A1),
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
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
