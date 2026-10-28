import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../i18n/s.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  final _dataService = DataService();
  TransactionScope _scope = TransactionScope.personal;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  void _shiftMonth(int delta) {
    setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + delta));
  }

  Widget _statusPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: AppTheme.bodySmall.copyWith(color: color, fontWeight: FontWeight.w600)),
    );
  }

  Future<void> _editBudget(String categoryId, double currentLimit) async {
    final controller = TextEditingController(text: currentLimit > 0 ? currentLimit.toStringAsFixed(0) : '');
    final base = _dataService.baseCurrency;
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.primaryCharcoal,
        title: Text(S.t.monthlyBudget, style: AppTheme.headingSmall),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: AppTheme.bodyLarge,
          decoration: AppTheme.glassInputDecoration(hintText: S.t.budgetAmountHint(base)),
        ),
        actions: [
          if (currentLimit > 0)
            TextButton(
              onPressed: () => Navigator.pop(ctx, 0.0),
              child: Text(S.t.remove, style: TextStyle(color: AppTheme.errorColor)),
            ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(S.t.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, double.tryParse(controller.text.trim())),
            child: Text(S.t.save),
          ),
        ],
      ),
    );
    if (result == null) return;

    if (result <= 0) {
      final existing = _dataService.getBudgetForCategory(categoryId, scope: _scope);
      if (existing != null) await _dataService.deleteBudget(existing.id);
    } else {
      await _dataService.setBudget(categoryId: categoryId, monthlyLimit: result, scope: _scope);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCurrentMonth = _selectedMonth.year == now.year && _selectedMonth.month == now.month;
    final progress = _dataService.budgetProgress(scope: _scope, month: _selectedMonth);
    final base = _dataService.baseCurrency;

    Map<String, dynamic>? progressFor(String categoryId) {
      for (final p in progress) {
        if (p['budget'].categoryId == categoryId) return p;
      }
      return null;
    }

    final categories = _dataService.getCategories(type: TransactionType.expense)..sort((a, b) {
      final pa = progressFor(a.id);
      final pb = progressFor(b.id);
      if (pa != null && pb == null) return -1;
      if (pa == null && pb != null) return 1;
      if (pa != null && pb != null) {
        return (pb['percent'] as double).compareTo(pa['percent'] as double);
      }
      return a.name.compareTo(b.name);
    });

    return Scaffold(
      backgroundColor: AppTheme.primaryCharcoal,
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: AppTheme.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(S.t.budgets, style: AppTheme.headingMedium),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.glassBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.glassBorder),
                  ),
                  child: Row(
                    children: [TransactionScope.personal, TransactionScope.family].map((s) {
                      final selected = s == _scope;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _scope = s),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: selected ? AppTheme.primaryCoral : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              s == TransactionScope.personal ? S.t.personal : S.t.family,
                              style: AppTheme.bodyMedium.copyWith(
                                color: selected ? AppTheme.onStamp : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.chevron_left, color: AppTheme.textSecondary),
                      onPressed: () => _shiftMonth(-1),
                    ),
                    Text(
                      isCurrentMonth ? S.t.thisMonthDot(S.monthYearShort(_selectedMonth)) : S.monthYearLong(_selectedMonth),
                      style: AppTheme.headingSmall,
                    ),
                    IconButton(
                      icon: Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                      onPressed: isCurrentMonth ? null : () => _shiftMonth(1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),

              Builder(builder: (context) {
                final summary = _dataService.budgetSummary(scope: _scope, month: _selectedMonth);
                final totalBudget = summary['totalBudget'] as double;
                final budgetedSpend = summary['totalSpent'] as double;
                final unbudgetedSpend = summary['unbudgetedSpend'] as double;
                final budgetCount = summary['budgetCount'] as int;
                final percentAll = summary['percentAll'] as double;
                final over = totalBudget > 0 && budgetedSpend > totalBudget;

                if (budgetCount == 0) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GlassCard(
                      child: Row(
                        children: [
                          const Icon(Icons.add_chart_outlined, color: AppTheme.accentAmber),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(S.t.setBudgetOnCategoryHint, style: AppTheme.bodyMedium),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final ringColor = over ? AppTheme.errorColor : AppTheme.stamp;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 84,
                              height: 84,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 84,
                                    height: 84,
                                    child: CircularProgressIndicator(
                                      value: 1,
                                      strokeWidth: 8,
                                      color: AppTheme.paperLine,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 84,
                                    height: 84,
                                    child: CircularProgressIndicator(
                                      value: percentAll.clamp(0, 1),
                                      strokeWidth: 8,
                                      backgroundColor: Colors.transparent,
                                      valueColor: AlwaysStoppedAnimation(ringColor),
                                    ),
                                  ),
                                  Text('${(percentAll * 100).toStringAsFixed(0)}%', style: AppTheme.numeral(size: 15, color: ringColor)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$base ${budgetedSpend.toStringAsFixed(2)}',
                                    style: AppTheme.numeral(size: 22, weight: FontWeight.w700),
                                  ),
                                  Text('/ $base ${totalBudget.toStringAsFixed(2)}', style: AppTheme.bodyMedium),
                                  const SizedBox(height: 8),
                                  _statusPill(
                                    over
                                        ? S.t.overBudgetBy('$base ${(budgetedSpend - totalBudget).toStringAsFixed(2)}')
                                        : S.t.amountLeft('$base ${(totalBudget - budgetedSpend).toStringAsFixed(2)}'),
                                    over ? AppTheme.errorColor : AppTheme.income,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Divider(height: 1, color: AppTheme.paperLine),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(S.t.budgetedSpend, style: AppTheme.caption.copyWith(letterSpacing: 0.5)),
                                  const SizedBox(height: 4),
                                  Text('$base ${budgetedSpend.toStringAsFixed(2)}', style: AppTheme.numeral(size: 16)),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(S.t.unbudgetedSpend, style: AppTheme.caption.copyWith(letterSpacing: 0.5)),
                                  const SizedBox(height: 4),
                                  Text('$base ${unbudgetedSpend.toStringAsFixed(2)}', style: AppTheme.numeral(size: 16)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),

              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final c = categories[i];
                    final p = progressFor(c.id);
                    final limit = p != null ? (p['budget'].monthlyLimit as double) : 0.0;
                    final spent = p != null ? (p['spent'] as double) : 0.0;
                    final pct = p != null ? (p['percent'] as double) : 0.0;
                    final over = limit > 0 && spent > limit;

                    return GlassCard(
                      onTap: () => _editBudget(c.id, limit),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(width: 8, height: 8, decoration: BoxDecoration(color: c.color, shape: BoxShape.circle)),
                              const SizedBox(width: 10),
                              Expanded(child: Text(c.displayName, style: AppTheme.bodyLarge)),
                              if (limit > 0 && over)
                                Text(
                                  S.t.amountOver('$base ${(spent - limit).toStringAsFixed(2)}'),
                                  style: AppTheme.bodyMedium.copyWith(color: AppTheme.errorColor, fontWeight: FontWeight.w600),
                                )
                              else if (limit == 0)
                                Text(S.t.setBudget, style: AppTheme.bodySmall.copyWith(color: AppTheme.accentAmber)),
                            ],
                          ),
                          if (limit > 0) ...[
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: pct.clamp(0, 1),
                                minHeight: 6,
                                backgroundColor: AppTheme.paperLine,
                                valueColor: AlwaysStoppedAnimation(over ? AppTheme.errorColor : c.color),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$base ${spent.toStringAsFixed(2)} / ${limit.toStringAsFixed(2)}',
                                  style: AppTheme.numeral(size: 12, color: AppTheme.inkFaded),
                                ),
                                _statusPill('${(pct * 100).toStringAsFixed(0)}%', over ? AppTheme.errorColor : c.color),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
