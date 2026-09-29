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
                Text('ByeLui', style: AppTheme.headingLarge),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _QuickAction(
                      icon: Icons.bar_chart_rounded,
                      label: 'Analytics',
                      onTap: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsScreen()));
                        _refresh();
                      },
                    ),
                    _QuickAction(
                      icon: Icons.pie_chart_outline_rounded,
                      label: 'Budget',
                      onTap: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetsScreen()));
                        _refresh();
                      },
                    ),
                    _QuickAction(
                      icon: Icons.receipt_long_outlined,
                      label: 'All',
                      onTap: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => const AllTransactionsScreen()));
                        _refresh();
                      },
                    ),
                    _QuickAction(
                      icon: Icons.settings_outlined,
                      label: 'Settings',
                      onTap: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                        _refresh();
                      },
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
                                  style: AppTheme.numeral(size: 18, weight: FontWeight.w600, color: AppTheme.successColor),
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
                                  style: AppTheme.numeral(size: 18, weight: FontWeight.w600, color: AppTheme.stampText),
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

                Builder(builder: (context) {
                  final summary = _dataService.budgetSummary(scope: _scopeFilter);
                  final budgetCount = summary['budgetCount'] as int;
                  final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
                  final daysLeft = daysInMonth - now.day + 1;

                  if (budgetCount == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GlassCard(
                        onTap: () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetsScreen()));
                          _refresh();
                        },
                        child: Row(
                          children: [
                            const Icon(Icons.add_chart_outlined, color: AppTheme.accentAmber),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text('Set a monthly budget to see how much you can still spend', style: AppTheme.bodyMedium),
                            ),
                            const Icon(Icons.chevron_right, color: AppTheme.textTertiary),
                          ],
                        ),
                      ),
                    );
                  }

                  final totalBudget = summary['totalBudget'] as double;
                  final remaining = summary['remaining'] as double;
                  final isOverBudget = remaining < 0;
                  final pct = totalBudget <= 0 ? 0.0 : ((summary['totalSpent'] as double) / totalBudget).clamp(0, 1).toDouble();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GlassCard(
                      onTap: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetsScreen()));
                        _refresh();
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isOverBudget ? 'Over budget this month' : 'Left to spend this month',
                            style: AppTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$base ${remaining.abs().toStringAsFixed(2)}',
                            style: AppTheme.numeral(size: 30, weight: FontWeight.w700).copyWith(
                              color: isOverBudget ? AppTheme.errorColor : AppTheme.successColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 6,
                              backgroundColor: AppTheme.glassBackground,
                              valueColor: AlwaysStoppedAnimation(isOverBudget ? AppTheme.errorColor : AppTheme.accentAmber),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text('$daysLeft day${daysLeft == 1 ? '' : 's'} left this month', style: AppTheme.caption),
                        ],
                      ),
                    ),
                  );
                }),

                Builder(builder: (context) {
                  final insights = _dataService.monthlyInsights(scope: _scopeFilter).take(2).toList();
                  if (insights.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.auto_awesome, size: 16, color: AppTheme.accentAmber),
                              const SizedBox(width: 6),
                              Text('Insights', style: AppTheme.bodySmall),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...insights.map((text) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('💡 '),
                                    Expanded(child: Text(text, style: AppTheme.bodyMedium)),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                  );
                }),

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
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AllTransactionsScreen()),
                        );
                        _refresh();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.stamp.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('See all', style: AppTheme.bodySmall.copyWith(color: AppTheme.stampText, fontWeight: FontWeight.w600)),
                            const Icon(Icons.chevron_right, size: 16, color: AppTheme.stampText),
                          ],
                        ),
                      ),
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
          child: const Icon(Icons.add, color: AppTheme.ink),
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

/// A round, tinted icon button with a caption — used for the top-of-home
/// shortcuts to Analytics / Budget / All transactions, so they're obvious
/// at a glance instead of buried as text links further down the page.
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.stamp.withOpacity(0.25),
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.stamp.withOpacity(0.4)),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: AppTheme.stampText, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label, style: AppTheme.bodySmall),
        ],
      ),
    );
  }
}
