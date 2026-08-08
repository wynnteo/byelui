import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/scope_toggle.dart';
import '../widgets/transaction_card.dart';
import '../widgets/swipeable_transaction_card.dart';
import '../widgets/banner_ad.dart';
import 'transaction_form_screen.dart';
import 'analytics_screen.dart';
import 'settings_screen.dart';
import 'recurring_screen.dart';
import 'all_transactions_screen.dart';
import 'budgets_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _dataService = DataService();
  TransactionScope? _scopeFilter;

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final totals = _dataService.monthlyTotals(now.year, now.month, scope: _scopeFilter);
    final income = totals['income'] ?? 0;
    final expense = totals['expense'] ?? 0;
    final base = _dataService.baseCurrency;

    final from = DateTime(now.year, now.month, 1);
    final transactions = _dataService.getTransactions(scope: _scopeFilter, from: from).take(10).toList();

    return Scaffold(
      backgroundColor: AppTheme.primaryCharcoal,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('ByeLui', style: AppTheme.headingLarge),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.repeat, color: AppTheme.textSecondary),
                          tooltip: 'Recurring',
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const RecurringScreen()),
                            );
                            _refresh();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings_outlined, color: AppTheme.textSecondary),
                          tooltip: 'Settings',
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SettingsScreen()),
                            );
                            _refresh();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                ScopeToggle(
                  value: _scopeFilter,
                  onChanged: (v) => setState(() => _scopeFilter = v),
                ),
                const SizedBox(height: 16),

                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('This month', style: AppTheme.bodySmall),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Income', style: AppTheme.bodySmall),
                                Text(
                                  '$base ${income.toStringAsFixed(2)}',
                                  style: AppTheme.headingSmall.copyWith(color: AppTheme.successColor),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Expense', style: AppTheme.bodySmall),
                                Text(
                                  '$base ${expense.toStringAsFixed(2)}',
                                  style: AppTheme.headingSmall.copyWith(color: AppTheme.primaryCoral),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                GlassCard(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
                    );
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.bar_chart, color: AppTheme.accentAmber),
                      const SizedBox(width: 10),
                      Expanded(child: Text('View analytics', style: AppTheme.bodyLarge)),
                      const Icon(Icons.chevron_right, color: AppTheme.textTertiary),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Builder(builder: (context) {
                  final summary = _dataService.budgetSummary(scope: _scopeFilter);
                  final overCount = summary['overCount'] as int;
                  final nearCount = summary['nearCount'] as int;
                  if (overCount == 0 && nearCount == 0) return const SizedBox.shrink();

                  final isOver = overCount > 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: GlassCard(
                      onTap: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetsScreen()));
                        _refresh();
                      },
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: isOver ? AppTheme.errorColor : AppTheme.accentAmber),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isOver
                                  ? '$overCount budget${overCount > 1 ? 's' : ''} over limit this month'
                                  : '$nearCount budget${nearCount > 1 ? 's' : ''} close to limit',
                              style: AppTheme.bodyMedium.copyWith(color: isOver ? AppTheme.errorColor : AppTheme.accentAmber),
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: AppTheme.textTertiary),
                        ],
                      ),
                    ),
                  );
                }),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recent transactions', style: AppTheme.headingSmall),
                    GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AllTransactionsScreen()),
                        );
                        _refresh();
                      },
                      child: Text('See all', style: AppTheme.bodySmall.copyWith(color: AppTheme.primaryCoral)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (transactions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text('No transactions yet this month', style: AppTheme.bodyMedium),
                    ),
                  )
                else
                  ...transactions.map((t) => Padding(
                        key: ValueKey(t.id),
                        padding: const EdgeInsets.only(bottom: 10),
                        child: SwipeableTransactionCard(
                          transaction: t,
                          category: _dataService.getCategoryById(t.categoryId),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => TransactionFormScreen(existing: t)),
                            );
                            _refresh();
                          },
                          onChanged: _refresh,
                        ),
                      )),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.buttonGradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.transparent,
          elevation: 0,
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TransactionFormScreen()),
            );
            _refresh();
          },
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: AppTheme.primaryCharcoal,
          child: const BannerAdWidget(),
        ),
      ),
    );
  }
}
