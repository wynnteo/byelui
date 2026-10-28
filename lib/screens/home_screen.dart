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
import '../i18n/s.dart';

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
    final transactions = _dataService.getTransactions(scope: _scopeFilter, from: from).take(5).toList();

    return Scaffold(
      backgroundColor: AppTheme.primaryCharcoal,
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(S.t.appName, style: AppTheme.headingLarge),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _QuickAction(
                      icon: Icons.bar_chart_rounded,
                      label: S.t.analytics,
                      onTap: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsScreen()));
                        _refresh();
                      },
                    ),
                    _QuickAction(
                      icon: Icons.pie_chart_outline_rounded,
                      label: S.t.budget,
                      onTap: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetsScreen()));
                        _refresh();
                      },
                    ),
                    _QuickAction(
                      icon: Icons.receipt_long_outlined,
                      label: S.t.all,
                      onTap: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => const AllTransactionsScreen()));
                        _refresh();
                      },
                    ),
                    _QuickAction(
                      icon: Icons.settings_outlined,
                      label: S.t.settings,
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

                // The hero always follows the selected Personal/Family/All filter.
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(S.t.thisMonth, style: AppTheme.bodySmall),
                      const SizedBox(height: 4),
                      Text(S.t.netCashFlow, style: AppTheme.bodyMedium),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${income - expense >= 0 ? '+' : '-'}$base ${(income - expense).abs().toStringAsFixed(2)}',
                          style: AppTheme.numeral(
                            size: 30,
                            weight: FontWeight.w700,
                            color: income >= expense ? AppTheme.successColor : AppTheme.errorColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _CashFlowMetric(
                              label: S.t.income,
                              amount: income,
                              currency: base,
                              color: AppTheme.successColor,
                              icon: Icons.arrow_downward_rounded,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _CashFlowMetric(
                              label: S.t.expense,
                              amount: expense,
                              currency: base,
                              color: AppTheme.stampText,
                              icon: Icons.arrow_upward_rounded,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Budget alerts are retained below, but the full budget card
                // and analytics insights belong to their respective screens.
                Builder(builder: (context) {
                  final summary = _dataService.budgetSummary(scope: _scopeFilter);
                  final overCount = summary['overCount'] as int;
                  final nearCount = summary['nearCount'] as int;
                  if (overCount == 0 && nearCount == 0) return const SizedBox.shrink();
                  final isOver = overCount > 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GlassCard(
                      onTap: () async {
                        await Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const BudgetsScreen(),
                        ));
                        _refresh();
                      },
                      child: Row(children: [
                        Icon(Icons.warning_amber_rounded,
                            color: isOver ? AppTheme.errorColor : AppTheme.accentAmber),
                        const SizedBox(width: 10),
                        Expanded(child: Text(
                          isOver ? S.t.budgetsOverLimit(overCount)
                              : S.t.budgetsNearLimit(nearCount),
                          style: AppTheme.bodyMedium,
                        )),
                        Icon(Icons.chevron_right, color: AppTheme.textTertiary),
                      ]),
                    ),
                  );
                }),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(S.t.recentTransactions, style: AppTheme.headingSmall),
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
                            Text(S.t.seeAll, style: AppTheme.bodySmall.copyWith(color: AppTheme.stampText, fontWeight: FontWeight.w600)),
                            Icon(Icons.chevron_right, size: 16, color: AppTheme.stampText),
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
                      child: Text(S.t.noTransactionsYetThisMonth, style: AppTheme.bodyMedium),
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
              MaterialPageRoute(builder: (_) => TransactionFormScreen(initialScope: _scopeFilter)),
            );
            _refresh();
          },
          child: Icon(Icons.add, color: AppTheme.onStamp),
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

class _CashFlowMetric extends StatelessWidget {
  final String label;
  final double amount;
  final String currency;
  final Color color;
  final IconData icon;
  const _CashFlowMetric({
    required this.label,
    required this.amount,
    required this.currency,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 4),
        Flexible(child: Text(label, style: AppTheme.bodySmall,
          maxLines: 1, overflow: TextOverflow.ellipsis)),
      ]),
      const SizedBox(height: 4),
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text('$currency ${amount.toStringAsFixed(2)}',
          style: AppTheme.numeral(size: 18, color: color, weight: FontWeight.w600)),
      ),
    ],
  );
}

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
