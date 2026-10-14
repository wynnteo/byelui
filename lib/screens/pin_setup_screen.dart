import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/security_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../i18n/s.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final _securityService = SecurityService();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _hasPin = false;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final hasPin = await _securityService.hasPin();
    if (mounted) setState(() {
      _hasPin = hasPin;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _error = null);

    if (_hasPin && _currentController.text.isEmpty) {
      setState(() => _error = S.t.enterCurrentPinMsg);
      return;
    }
    if (_newController.text.length < 4) {
      setState(() => _error = S.t.newPinMin);
      return;
    }
    if (_newController.text != _confirmController.text) {
      setState(() => _error = S.t.pinsDontMatch);
      return;
    }

    setState(() => _saving = true);
    try {
      if (_hasPin) {
        final check = await _securityService.checkPin(_currentController.text);
        if (!check.ok) {
          setState(() => _error = _pinFailureMessage(check));
          return;
        }
      }
      await _securityService.setPin(_newController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_hasPin ? S.t.pinUpdated : S.t.pinSaved)));
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _pinFailureMessage(PinCheckResult check) {
    if (check.isLocked) {
      return S.t.tooManyWrongAttempts(formatLockDuration(check.lockedFor!));
    }
    return S.t.currentPinIncorrect;
  }

  Future<void> _removePin() async {
    if (_currentController.text.isEmpty) {
      setState(() => _error = S.t.enterCurrentPinToRemove);
      return;
    }
    final check = await _securityService.checkPin(_currentController.text);
    if (!check.ok) {
      setState(() => _error = _pinFailureMessage(check));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.primaryCharcoal,
        title: Text(S.t.removePinLockQ, style: AppTheme.headingSmall),
        content: Text(
          S.t.removePinBody,
          style: AppTheme.bodyMedium,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(S.t.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(S.t.remove, style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _securityService.clearPin();
    if (mounted) Navigator.pop(context);
  }

  Widget _pinField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      obscureText: true,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
      style: AppTheme.bodyLarge.copyWith(letterSpacing: 6),
      decoration: AppTheme.glassInputDecoration(hintText: hint),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(backgroundColor: AppTheme.primaryCharcoal, body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppTheme.primaryCharcoal,
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.close, color: AppTheme.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(_hasPin ? S.t.changePin : S.t.setUpPin, style: AppTheme.headingMedium),
                ],
              ),
              const SizedBox(height: 16),

              if (_hasPin) ...[
                Text(S.t.currentPin, style: AppTheme.bodySmall),
                const SizedBox(height: 6),
                _pinField(_currentController, S.t.enterCurrentPinHint),
                const SizedBox(height: 16),
              ],

              Text(_hasPin ? S.t.newPin : S.t.pinHint, style: AppTheme.bodySmall),
              const SizedBox(height: 6),
              _pinField(_newController, '••••'),
              const SizedBox(height: 16),

              Text(S.t.confirmPin, style: AppTheme.bodySmall),
              const SizedBox(height: 6),
              _pinField(_confirmController, '••••'),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: AppTheme.bodySmall.copyWith(color: AppTheme.errorColor)),
              ],

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(gradient: AppTheme.buttonGradient, borderRadius: BorderRadius.circular(16)),
                  child: ElevatedButton(
                    style: AppTheme.primaryButtonStyle,
                    onPressed: _saving ? null : _save,
                    child: Text(_hasPin ? S.t.updatePin : S.t.savePin),
                  ),
                ),
              ),

              if (_hasPin) ...[
                const SizedBox(height: 20),
                GlassCard(
                  onTap: _removePin,
                  child: Row(
                    children: [
                      Icon(Icons.lock_open, color: AppTheme.errorColor),
                      const SizedBox(width: 10),
                      Text(S.t.removePinLock, style: AppTheme.bodyLarge.copyWith(color: AppTheme.errorColor)),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(S.t.removePinConfirmHint, style: AppTheme.caption),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
