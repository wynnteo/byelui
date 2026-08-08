import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/security_service.dart';
import '../services/biometric_service.dart';
import '../theme/app_theme.dart';

/// Shown at app cold-start when a PIN has been set. Tries biometric first
/// (if enabled and available), falls back to PIN entry.
class LockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;

  const LockScreen({super.key, required this.onUnlocked});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _securityService = SecurityService();
  final _pinController = TextEditingController();
  bool _isVerifying = false;
  bool _biometricTried = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometricFirst());
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _tryBiometricFirst() async {
    if (_biometricTried) return;
    _biometricTried = true;
    final enabled = await BiometricService.isBiometricEnabled();
    final available = await BiometricService.canUseBiometric();
    if (!enabled || !available || !mounted) return;

    final response = await BiometricService.authenticate();
    if (!mounted) return;
    if (response.isSuccess) {
      widget.onUnlocked();
    }
  }

  Future<void> _verifyPin() async {
    if (_isVerifying) return;
    final input = _pinController.text;
    if (input.length < 4) {
      setState(() => _errorMessage = 'PIN must be at least 4 digits');
      return;
    }
    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final isValid = await _securityService.verifyPin(input);
      if (!mounted) return;
      if (isValid) {
        widget.onUnlocked();
      } else {
        setState(() {
          _isVerifying = false;
          _pinController.clear();
          _errorMessage = 'Incorrect PIN, try again';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _errorMessage = 'Something went wrong, try again';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_outline, size: 64, color: Colors.white),
                    const SizedBox(height: 24),
                    Text('ByeLui is locked', style: AppTheme.headingSmall.copyWith(color: Colors.white), textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text('Enter your PIN to continue', style: AppTheme.bodyMedium.copyWith(color: Colors.white70), textAlign: TextAlign.center),
                    const SizedBox(height: 32),
                    TextField(
                      controller: _pinController,
                      autofocus: true,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                      style: AppTheme.headingSmall.copyWith(color: Colors.white, letterSpacing: 8),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Colors.white),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                      onSubmitted: (_) => _verifyPin(),
                    ),
                    const SizedBox(height: 16),
                    if (_errorMessage != null)
                      Text(_errorMessage!, style: AppTheme.bodySmall.copyWith(color: AppTheme.errorColor), textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isVerifying ? null : _verifyPin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.primaryCoral,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isVerifying
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Unlock'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<bool>(
                      future: BiometricService.isBiometricEnabled(),
                      builder: (context, snapshot) {
                        if (snapshot.data != true) return const SizedBox.shrink();
                        return TextButton.icon(
                          onPressed: () async {
                            final response = await BiometricService.authenticate();
                            if (response.isSuccess && mounted) widget.onUnlocked();
                          },
                          icon: const Icon(Icons.fingerprint, color: Colors.white70),
                          label: const Text('Use biometrics instead', style: TextStyle(color: Colors.white70)),
                        );
                      },
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
}
