import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/security_service.dart';
import '../services/biometric_service.dart';
import '../theme/app_theme.dart';
import '../i18n/s.dart';

/// Shown at app cold-start when a PIN and/or biometric unlock has been set
/// up. Tries biometric first if enabled, falls back to PIN entry if a PIN
/// exists; if only biometric is enabled (no PIN), offers a retry button
/// instead of a PIN field.
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
  bool _loading = true;
  bool _hasPin = false;
  bool _biometricEnabled = false;
  String? _errorMessage;
  Timer? _lockTimer;
  DateTime? _lockedUntil;

  bool get _isLockedOut => _lockedUntil != null;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final hasPin = await _securityService.hasPin();
    final biometricEnabled = await BiometricService.isBiometricEnabled();
    final lock = await _securityService.lockRemaining();
    if (!mounted) return;
    setState(() {
      _hasPin = hasPin;
      _biometricEnabled = biometricEnabled;
      _loading = false;
    });
    _startLockCountdown(lock);
    if (biometricEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
    }
  }

  /// Shows "Too many attempts…" with a live countdown until the lockout ends.
  void _startLockCountdown(Duration? remaining) {
    _lockTimer?.cancel();
    if (remaining == null) {
      if (mounted) setState(() => _lockedUntil = null);
      return;
    }
    final until = DateTime.now().add(remaining);
    void tick() {
      final left = until.difference(DateTime.now());
      if (!mounted) return;
      if (left <= Duration.zero) {
        _lockTimer?.cancel();
        setState(() {
          _lockedUntil = null;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _lockedUntil = until;
          _errorMessage = S.t.tooManyAttempts(formatLockDuration(left));
        });
      }
    }

    tick();
    _lockTimer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  @override
  void dispose() {
    _lockTimer?.cancel();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _tryBiometric() async {
    _biometricTried = true;
    final available = await BiometricService.canUseBiometric();
    if (!available || !mounted) return;

    final response = await BiometricService.authenticate();
    if (!mounted) return;
    if (response.isSuccess) {
      widget.onUnlocked();
    }
  }

  Future<void> _verifyPin() async {
    if (_isVerifying || _isLockedOut) return;
    final input = _pinController.text;
    if (input.length < 4) {
      setState(() => _errorMessage = S.t.pinMin4);
      return;
    }
    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final result = await _securityService.checkPin(input);
      if (!mounted) return;
      if (result.ok) {
        widget.onUnlocked();
      } else {
        setState(() {
          _isVerifying = false;
          _pinController.clear();
          _errorMessage = result.attemptsLeft > 0 && result.attemptsLeft <= 2
              ? S.t.incorrectPinTriesLeft(result.attemptsLeft)
              : S.t.incorrectPin;
        });
        if (result.isLocked) _startLockCountdown(result.lockedFor);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _errorMessage = S.t.somethingWentWrong;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(backgroundColor: AppTheme.primaryCharcoal, body: SizedBox());
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_hasPin ? Icons.lock_outline : Icons.fingerprint, size: 56, color: AppTheme.stampText),
                    const SizedBox(height: 24),
                    Text(S.t.appLocked, style: AppTheme.headingSmall, textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text(
                      _hasPin ? S.t.enterPinToContinue : S.t.unlockBiometricToContinue,
                      style: AppTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    if (_hasPin) ...[
                      TextField(
                        controller: _pinController,
                        enabled: !_isLockedOut,
                        autofocus: !_biometricEnabled,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                        style: AppTheme.numeral(size: 20).copyWith(letterSpacing: 8),
                        decoration: AppTheme.glassInputDecoration(),
                        onSubmitted: (_) => _verifyPin(),
                      ),
                      const SizedBox(height: 16),
                      if (_errorMessage != null)
                        Text(_errorMessage!, style: AppTheme.bodySmall.copyWith(color: AppTheme.errorColor), textAlign: TextAlign.center),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (_isVerifying || _isLockedOut) ? null : _verifyPin,
                          style: AppTheme.primaryButtonStyle,
                          child: _isVerifying
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.onStamp),
                                )
                              : Text(S.t.unlock),
                        ),
                      ),
                    ],

                    if (_biometricEnabled) ...[
                      if (_hasPin) const SizedBox(height: 12),
                      if (!_hasPin) ...[
                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(_errorMessage!, style: AppTheme.bodySmall.copyWith(color: AppTheme.errorColor), textAlign: TextAlign.center),
                          ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _tryBiometric,
                            style: AppTheme.primaryButtonStyle,
                            icon: const Icon(Icons.fingerprint),
                            label: Text(S.t.unlockWithBiometrics),
                          ),
                        ),
                      ] else
                        TextButton.icon(
                          onPressed: _tryBiometric,
                          icon: Icon(Icons.fingerprint, color: AppTheme.inkFaded),
                          label: Text(S.t.useBiometricsInstead, style: AppTheme.bodyMedium),
                        ),
                    ],
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
