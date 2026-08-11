import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/security_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

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
      setState(() => _error = 'Enter your current PIN');
      return;
    }
    if (_newController.text.length < 4) {
      setState(() => _error = 'New PIN must be at least 4 digits');
      return;
    }
    if (_newController.text != _confirmController.text) {
      setState(() => _error = "New PINs don't match");
      return;
    }

    setState(() => _saving = true);
    try {
      if (_hasPin) {
        final valid = await _securityService.verifyPin(_currentController.text);
        if (!valid) {
          setState(() => _error = 'Current PIN is incorrect');
          return;
        }
      }
      await _securityService.setPin(_newController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_hasPin ? 'PIN updated' : 'PIN saved')));
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _removePin() async {
    if (_currentController.text.isEmpty) {
      setState(() => _error = 'Enter your current PIN to remove it');
      return;
    }
    final valid = await _securityService.verifyPin(_currentController.text);
    if (!valid) {
      setState(() => _error = 'Current PIN is incorrect');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.primaryCharcoal,
        title: const Text('Remove PIN lock?', style: AppTheme.headingSmall),
        content: Text(
          'If biometric unlock is also on, it will keep working on its own. '
          "Otherwise ByeLui will open without needing to unlock.",
          style: AppTheme.bodyMedium,
        ),
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
      return const Scaffold(backgroundColor: AppTheme.primaryCharcoal, body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppTheme.primaryCharcoal,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(_hasPin ? 'Change PIN' : 'Set up PIN', style: AppTheme.headingMedium),
                ],
              ),
              const SizedBox(height: 16),

              if (_hasPin) ...[
                Text('Current PIN', style: AppTheme.bodySmall),
                const SizedBox(height: 6),
                _pinField(_currentController, 'Enter current PIN'),
                const SizedBox(height: 16),
              ],

              Text(_hasPin ? 'New PIN' : 'PIN (4–6 digits)', style: AppTheme.bodySmall),
              const SizedBox(height: 6),
              _pinField(_newController, '••••'),
              const SizedBox(height: 16),

              Text('Confirm PIN', style: AppTheme.bodySmall),
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
                    child: Text(_hasPin ? 'Update PIN' : 'Save PIN'),
                  ),
                ),
              ),

              if (_hasPin) ...[
                const SizedBox(height: 20),
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
                const SizedBox(height: 6),
                Text('Uses the current PIN above to confirm removal.', style: AppTheme.caption),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
