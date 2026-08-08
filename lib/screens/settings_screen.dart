import 'package:flutter/material.dart';
import '../services/data_service.dart';
import '../services/security_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import 'recurring_screen.dart';
import 'categories_screen.dart';
import 'budgets_screen.dart';
import 'tag_insights_screen.dart';
import 'pin_setup_screen.dart';
import 'export_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _dataService = DataService();
  static const _currencies = ['SGD', 'MYR', 'USD'];

  @override
  Widget build(BuildContext context) {
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
                    icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text('Settings', style: AppTheme.headingMedium),
                ],
              ),
              const SizedBox(height: 16),

              Text('Base currency', style: AppTheme.bodySmall),
              const SizedBox(height: 8),
              GlassCard(
                child: Row(
                  children: [
                    const Icon(Icons.attach_money, color: AppTheme.textSecondary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('Used to total your income/expense in reports', style: AppTheme.bodyMedium),
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

              Text('Security', style: AppTheme.bodySmall),
              const SizedBox(height: 8),
              FutureBuilder<bool>(
                future: SecurityService().hasPin(),
                builder: (context, snapshot) {
                  final hasPin = snapshot.data ?? false;
                  return GlassCard(
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => const PinSetupScreen()));
                      setState(() {});
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.lock_outline, color: AppTheme.primaryCoral),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('App lock', style: AppTheme.bodyLarge),
                              Text(hasPin ? 'PIN set' : 'Not set up', style: AppTheme.bodySmall),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: AppTheme.textTertiary),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),
              Text('Data', style: AppTheme.bodySmall),
              const SizedBox(height: 8),
              GlassCard(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExportScreen())),
                child: Row(
                  children: [
                    const Icon(Icons.ios_share, color: AppTheme.accentAmber),
                    const SizedBox(width: 10),
                    Expanded(child: Text('Export transactions', style: AppTheme.bodyLarge)),
                    const Icon(Icons.chevron_right, color: AppTheme.textTertiary),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              Text('Manage', style: AppTheme.bodySmall),
              const SizedBox(height: 8),
              GlassCard(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecurringScreen())),
                child: Row(
                  children: [
                    const Icon(Icons.repeat, color: AppTheme.accentAmber),
                    const SizedBox(width: 10),
                    Expanded(child: Text('Recurring transactions', style: AppTheme.bodyLarge)),
                    const Icon(Icons.chevron_right, color: AppTheme.textTertiary),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              GlassCard(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetsScreen())),
                child: Row(
                  children: [
                    const Icon(Icons.pie_chart_outline, color: AppTheme.successColor),
                    const SizedBox(width: 10),
                    Expanded(child: Text('Budgets', style: AppTheme.bodyLarge)),
                    const Icon(Icons.chevron_right, color: AppTheme.textTertiary),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              GlassCard(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TagInsightsScreen())),
                child: Row(
                  children: [
                    const Icon(Icons.sell_outlined, color: Color(0xFF6366F1)),
                    const SizedBox(width: 10),
                    Expanded(child: Text('Tag insights', style: AppTheme.bodyLarge)),
                    const Icon(Icons.chevron_right, color: AppTheme.textTertiary),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              GlassCard(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesScreen())),
                child: Row(
                  children: [
                    const Icon(Icons.category_outlined, color: AppTheme.primaryCoral),
                    const SizedBox(width: 10),
                    Expanded(child: Text('Categories', style: AppTheme.bodyLarge)),
                    const Icon(Icons.chevron_right, color: AppTheme.textTertiary),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Text('About', style: AppTheme.bodySmall),
              const SizedBox(height: 8),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ByeLui', style: AppTheme.bodyLarge),
                    const SizedBox(height: 4),
                    Text('Version 1.0.0', style: AppTheme.bodySmall),
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
