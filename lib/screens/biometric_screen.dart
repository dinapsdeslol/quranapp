import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/biometric_service.dart';

class BiometricScreen extends StatefulWidget {
  final VoidCallback onSuccess;

  const BiometricScreen({super.key, required this.onSuccess});

  @override
  State<BiometricScreen> createState() => _BiometricScreenState();
}

class _BiometricScreenState extends State<BiometricScreen> {
  final BiometricService _biometricService = BiometricService();
  bool _isLoading = false;
  String _message = 'Place your finger on the sensor';
  bool _isFirstLaunch = true;
  bool _hasBiometric = false;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    setState(() => _isLoading = true);

    final isAvailable = await _biometricService.isBiometricAvailable();
    final isFirstLaunch = await _biometricService.isFirstLaunch();
    _isFirstLaunch = isFirstLaunch;

    if (!isAvailable) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasBiometric = false;
          _message = 'No fingerprint configured. You can skip this step or set up a fingerprint in Settings > Security.';
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        _hasBiometric = true;
      });
      await _authenticate();
    }
  }

  Future<void> _authenticate() async {
    setState(() {
      _isLoading = true;
      _message = 'Place your finger on the sensor...';
    });

    final success = await _biometricService.authenticate(
      reason: _isFirstLaunch
          ? 'Verify your identity to access the Quran Player'
          : 'Verify your identity to continue',
    );

    if (success) {
      final player = AudioPlayer();
      try {
        await player.play(AssetSource('sounds/success.mp3'));
      } catch (e) {
      }
      await Future.delayed(const Duration(milliseconds: 300));
      await player.dispose();

      if (_isFirstLaunch) {
        await _biometricService.setFirstLaunchComplete();
      }

      if (mounted) {
        widget.onSuccess();
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _message = 'Authentication failed. Tap "Try Again" to retry.';
        });
      }
    }
  }

  void _skipBiometric() async {
    if (_isFirstLaunch) {
      await _biometricService.setFirstLaunchComplete();
    }
    if (mounted) {
      widget.onSuccess();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.teal.shade700,
              Colors.teal.shade900,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.fingerprint,
                    size: 120,
                    color: _hasBiometric ? Colors.white : Colors.white54,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Quran Player',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 40),
                  if (_isLoading)
                    const CircularProgressIndicator(color: Colors.white)
                  else
                    const SizedBox.shrink(),
                  const SizedBox(height: 16),
                  Text(
                    _message,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  if (_hasBiometric && !_isLoading)
                    ElevatedButton.icon(
                      onPressed: _authenticate,
                      icon: const Icon(Icons.fingerprint),
                      label: const Text('Try Again'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.teal.shade700,
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (!_isLoading)
                    TextButton(
                      onPressed: _skipBiometric,
                      child: const Text(
                        'Skip for now',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
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
