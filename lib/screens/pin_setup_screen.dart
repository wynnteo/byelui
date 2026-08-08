import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/security_service.dart';
import '../services/biometric_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

enum _Step { enterCurrent, enterNew, confirmNew }

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final _securityService = SecurityService();
  final _controller = TextEditingController();
  _Step _step = _Step.enterNew;
  String? _pendingNewPin;
  String? _error;
  bool _hasPin = false;
  bool _loading = true;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final hasPin = await _securityService.hasPin();
    final bioAvailable = await BiometricService.canUseBiometric();
    final bioEnabled = await BiometricService.isBiometricEnabled();
    setState(() {
      _hasPin = hasPin;
      _step = hasPin ? _Step.enterCurrent : _Step.enterNew;
      _biometricAvailable = bioAvailable;
      _biometricEnabled = bioEnabled;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final input = _controller.text;
    if (input.length < 4) {
      setState(() => _error = 'PIN must be at least 4 digits');
      return;
    }

    if (_step == _Step.enterCurrent) {
      final valid = await _securityService.verifyPin(input);
      if (!valid) {
        setState(() {
          _error = 'Incorrect PIN';
          _controller.clear();
        });
        return;
      }
      setState(() {
        _step = _Step.enterNew;
        _controller.clear();
        _error = null;
      });
    } else if (_step == _Step.enterNew) {
      setState(() {
        _pendingNewPin = input;
        _step = _Step.confirmNew;
        _controller.clear();
        _error = null;
      });
    } else if (_step == _Step.confirmNew) {
      if (input != _pendingNewPin) {
        setState(() {
          _error = "PINs don't match, try again";
          _controller.clear();
          _step = _Step.enterNew;
          _pendingNewPin = null;
        });
        return;
      }
      await _securityService.setPin(input);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN saved')));
        setState(() {
          _hasPin = true;
          _controller.clear();
        });
        Navigator.pop(context);
      }
    }
  }

  Future<void> _removePin() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.primaryCharcoal,
        title: const Text('Remove PIN lock?', style: AppTheme.headingSmall),
        content: Text('ByeLui will open without needing a PIN or biometric.', style: AppTheme.bodyMedium),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _securityService.clearPin();
    await BiometricService.setBiometricEnabled(false);
    if (mounted) Navigator.pop(context);
  }

  String get _prompt {
    switch (_step) {
      case _Step.enterCurrent:
        return 'Enter your current PIN';
      case _Step.enterNew:
        return _hasPin ? 'Enter a new PIN' : 'Create a PIN';
      case _Step.confirmNew:
        return 'Confirm your new PIN';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(backgroundColor: AppTheme.primaryCharcoal, body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppTheme.primaryCharcoal,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(_hasPin ? 'Manage PIN' : 'Set up PIN', style: AppTheme.headingMedium),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Text(_prompt, style: AppTheme.bodyLarge, textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _controller,
                      autofocus: true,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                      style: AppTheme.headingSmall.copyWith(letterSpacing: 8),
                      decoration: AppTheme.glassInputDecoration(hintText: '••••'),
                      onSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 12),
                    if (_error != null) Text(_error!, style: AppTheme.bodySmall.copyWith(color: AppTheme.errorColor)),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(gradient: AppTheme.buttonGradient, borderRadius: BorderRadius.circular(16)),
                        child: ElevatedButton(
                          style: AppTheme.primaryButtonStyle,
                          onPressed: _submit,
                          child: const Text('Continue'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (_hasPin) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      if (_biometricAvailable)
                        GlassCard(
                          child: Row(
                            children: [
                              const Icon(Icons.fingerprint, color: AppTheme.accentAmber),
                              const SizedBox(width: 10),
                              Expanded(child: Text('Use biometrics too', style: AppTheme.bodyLarge)),
                              Switch(
                                value: _biometricEnabled,
                                activeColor: AppTheme.primaryCoral,
                                onChanged: (v) async {
                                  await BiometricService.setBiometricEnabled(v);
                                  setState(() => _biometricEnabled = v);
                                },
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 10),
                      GlassCard(
                        onTap: _removePin,
                        child: Row(
                          children: [
                            const Icon(Icons.lock_open, color: AppTheme.errorColor),
                            const SizedBox(width: 10),
                            Text('Remove PIN lock', style: AppTheme.bodyLarge.copyWith(color: AppTheme.errorColor)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
