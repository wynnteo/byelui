import 'package:flutter/material.dart';
import '../services/data_service.dart';
import '../services/bill_notification_service.dart';
import '../services/security_service.dart';
import '../services/biometric_service.dart';
import '../services/theme_controller.dart';
import '../i18n/language_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import 'recurring_screen.dart';
import 'categories_screen.dart';
import 'budgets_screen.dart';
import 'payment_cards_screen.dart';
import 'pin_setup_screen.dart';
import 'export_screen.dart';
import 'backup_screen.dart';
import '../i18n/s.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _dataService = DataService();
  static const _currencies = ['SGD', 'MYR', 'USD'];

  bool _hasPin = false;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  bool _securityLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSecurityStatus();
  }

  Future<void> _loadSecurityStatus() async {
    final hasPin = await SecurityService().hasPin();
    final available = await BiometricService.canUseBiometric();
    final enabled = await BiometricService.isBiometricEnabled();
    if (!mounted) return;
    setState(() {
      _hasPin = hasPin;
      _biometricAvailable = available;
      _biometricEnabled = enabled;
      _securityLoading = false;
    });
  }

  bool _reminderBusy = false;

  Future<void> _toggleBillReminders(bool enabled) async {
    if (_reminderBusy) return;
    setState(() => _reminderBusy = true);
    try {
      if (enabled) {
        final granted = await BillNotificationService.instance.requestPermission();
        if (!granted) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notification permission was not granted.')),
          );
          return;
        }
      }
      await _dataService.setBillRemindersEnabled(enabled);
      await BillNotificationService.instance.syncSafely();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update reminders: $error')),
      );
    } finally {
      if (mounted) setState(() => _reminderBusy = false);
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      // Verify biometrics actually work before turning the setting on.
      final response = await BiometricService.authenticate();
      if (!response.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.errorMessage ?? S.t.couldNotVerifyBiometrics)),
          );
        }
        return;
      }
    }
    await BiometricService.setBiometricEnabled(value);
    setState(() => _biometricEnabled = value);
  }

  @override
  Widget build(BuildContext context) {
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
                    icon: Icon(Icons.arrow_back, color: AppTheme.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(S.t.settings, style: AppTheme.headingMedium),
                ],
              ),
              const SizedBox(height: 16),

              Text(S.t.appearance, style: AppTheme.bodySmall),
              const SizedBox(height: 8),
              const _ThemeModeSelector(),
              const SizedBox(height: 20),

              Text(S.t.language, style: AppTheme.bodySmall),
              const SizedBox(height: 8),
              const _LanguageSelector(),
              const SizedBox(height: 20),

              Text(S.t.baseCurrency, style: AppTheme.bodySmall),
              const SizedBox(height: 8),
              GlassCard(
                child: Row(
                  children: [
                    Icon(Icons.attach_money, color: AppTheme.textSecondary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(S.t.baseCurrencyHint, style: AppTheme.bodyMedium),
                    ),
                    DropdownButton<String>(
                      value: _dataService.baseCurrency,
                      dropdownColor: AppTheme.primaryCharcoal,
                      underline: const SizedBox(),
                      style: AppTheme.bodyLarge,
                      items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _dataService.baseCurrency = v);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Text('Bill notifications', style: AppTheme.bodySmall),
              const SizedBox(height: 8),
              GlassCard(
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active_outlined,
                        color: AppTheme.accentAmber),
                    const SizedBox(width: 10),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Payment due reminders', style: AppTheme.bodyLarge),
                        Text('One alert per bill, around 9 AM',
                            style: AppTheme.caption),
                      ],
                    )),
                    Switch(
                      value: _dataService.billRemindersEnabled,
                      onChanged: _reminderBusy ? null : _toggleBillReminders,
                    ),
                  ],
                ),
              ),
              if (_dataService.billRemindersEnabled) ...[
                const SizedBox(height: 10),
                GlassCard(
                  child: Row(
                    children: [
                      Expanded(child: Text('Remind me before due date',
                          style: AppTheme.bodyMedium)),
                      DropdownButton<int>(
                        value: _dataService.billReminderDaysBefore,
                        dropdownColor: AppTheme.primaryCharcoal,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('1 day')),
                          DropdownMenuItem(value: 3, child: Text('3 days')),
                        ],
                        onChanged: _reminderBusy ? null : (days) async {
                          if (days == null) return;
                          setState(() => _reminderBusy = true);
                          try {
                            await _dataService.setBillReminderDaysBefore(days);
                            await BillNotificationService.instance.syncSafely();
                          } finally {
                            if (mounted) setState(() => _reminderBusy = false);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),

              Text(S.t.security, style: AppTheme.bodySmall),
              const SizedBox(height: 8),
              if (_securityLoading)
                const GlassCard(child: SizedBox(height: 24))
              else ...[
                if (_biometricAvailable)
                  GlassCard(
                    child: Row(
                      children: [
                        const Icon(Icons.fingerprint, color: AppTheme.accentAmber),
                        const SizedBox(width: 10),
                        Expanded(child: Text(S.t.biometricUnlock, style: AppTheme.bodyLarge)),
                        Switch(
                          value: _biometricEnabled,
                          activeColor: AppTheme.primaryCoral,
                          onChanged: _toggleBiometric,
                        ),
                      ],
                    ),
                  )
                else
                  GlassCard(
                    child: Row(
                      children: [
                        Icon(Icons.fingerprint, color: AppTheme.textTertiary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            S.t.biometricNotAvailableDevice,
                            style: AppTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 10),
                GlassCard(
                  onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => const PinSetupScreen()));
                    _loadSecurityStatus();
                  },
                  child: Row(
                    children: [
                      Icon(Icons.lock_outline, color: AppTheme.stampText),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(S.t.pinLock, style: AppTheme.bodyLarge),
                            Text(_hasPin ? S.t.pinSetTapToChange : S.t.notSetUp, style: AppTheme.bodySmall),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: AppTheme.textTertiary),
                    ],
                  ),
                ),
                if (!_hasPin && !_biometricEnabled) ...[
                  const SizedBox(height: 6),
                  Text(
                    S.t.securityHint,
                    style: AppTheme.caption,
                  ),
                ],
              ],

              const SizedBox(height: 20),
              Text(S.t.data, style: AppTheme.bodySmall),
              const SizedBox(height: 8),
              GlassCard(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExportScreen())),
                child: Row(
                  children: [
                    const Icon(Icons.ios_share, color: AppTheme.accentAmber),
                    const SizedBox(width: 10),
                    Expanded(child: Text(S.t.exportTransactionsMenu, style: AppTheme.bodyLarge)),
                    Icon(Icons.chevron_right, color: AppTheme.textTertiary),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              GlassCard(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BackupScreen())),
                child: Row(
                  children: [
                    const Icon(Icons.swap_horiz, color: Color(0xFF6366F1)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(S.t.backupRestoreMenu, style: AppTheme.bodyLarge)),
                    Icon(Icons.chevron_right, color: AppTheme.textTertiary),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              Text(S.t.manage, style: AppTheme.bodySmall),
              const SizedBox(height: 8),
              GlassCard(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecurringScreen())),
                child: Row(
                  children: [
                    const Icon(Icons.repeat, color: AppTheme.accentAmber),
                    const SizedBox(width: 10),
                    Expanded(child: Text(S.t.recurringTransactions, style: AppTheme.bodyLarge)),
                    Icon(Icons.chevron_right, color: AppTheme.textTertiary),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              GlassCard(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetsScreen())),
                child: Row(
                  children: [
                    Icon(Icons.pie_chart_outline, color: AppTheme.successColor),
                    const SizedBox(width: 10),
                    Expanded(child: Text(S.t.budgets, style: AppTheme.bodyLarge)),
                    Icon(Icons.chevron_right, color: AppTheme.textTertiary),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              GlassCard(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesScreen())),
                child: Row(
                  children: [
                    Icon(Icons.category_outlined, color: AppTheme.stampText),
                    const SizedBox(width: 10),
                    Expanded(child: Text(S.t.categories, style: AppTheme.bodyLarge)),
                    Icon(Icons.chevron_right, color: AppTheme.textTertiary),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              GlassCard(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentCardsScreen())),
                child: Row(
                  children: [
                    const Icon(Icons.credit_card_outlined, color: AppTheme.accentAmber),
                    const SizedBox(width: 10),
                    Expanded(child: Text(S.t.paymentCards, style: AppTheme.bodyLarge)),
                    Icon(Icons.chevron_right, color: AppTheme.textTertiary),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Text(S.t.about, style: AppTheme.bodySmall),
              const SizedBox(height: 8),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(S.t.appName, style: AppTheme.bodyLarge),
                    const SizedBox(height: 4),
                    Text(S.t.version('1.0.0'), style: AppTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}


/// Segmented control — same look as [ScopeToggle]. Used for Appearance and Language.
class _Segmented<T> extends StatelessWidget {
  final List<(T, String, IconData?)> options;
  final T selected;
  final ValueChanged<T> onChanged;

  const _Segmented({required this.options, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.glassBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: Row(
        children: options.map((o) {
          final isSelected = o.$1 == selected;
          final fg = isSelected ? AppTheme.onStamp : AppTheme.textSecondary;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(o.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryCoral : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (o.$3 != null) ...[
                      Icon(o.$3, size: 16, color: fg),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        o.$2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.bodyMedium.copyWith(
                          color: fg,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// System / Light / Dark. Reads the mode straight from ThemeController; the
/// app-wide rebuild that follows setMode() refreshes this too (no local state).
class _ThemeModeSelector extends StatelessWidget {
  const _ThemeModeSelector();

  @override
  Widget build(BuildContext context) {
    final controller = ThemeController();
    return _Segmented<AppThemeMode>(
      options: [
        (AppThemeMode.system, S.t.system, Icons.brightness_auto),
        (AppThemeMode.light, S.t.themeLight, Icons.light_mode_outlined),
        (AppThemeMode.dark, S.t.themeDark, Icons.dark_mode_outlined),
      ],
      selected: controller.mode,
      onChanged: controller.setMode,
    );
  }
}

/// System / English / 简体中文. Language names are shown in their own language
/// on purpose, so someone who can't read the current UI language can still find theirs.
class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector();

  @override
  Widget build(BuildContext context) {
    final controller = LanguageController();
    return _Segmented<AppLanguage>(
      options: [
        (AppLanguage.system, S.t.system, Icons.translate),
        (AppLanguage.en, 'English', null),
        (AppLanguage.zh, '简体中文', null),
      ],
      selected: controller.preference,
      onChanged: controller.setPreference,
    );
  }
}
