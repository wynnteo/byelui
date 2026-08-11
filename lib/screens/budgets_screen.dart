import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../models/budget.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  final _dataService = DataService();
  TransactionScope _scope = TransactionScope.personal;

  Widget _statusPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
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
        title: const Text('Monthly budget', style: AppTheme.headingSmall),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: AppTheme.bodyLarge,
          decoration: AppTheme.glassInputDecoration(hintText: '$base amount, e.g. 300'),
        ),
        actions: [
          if (currentLimit > 0)
            TextButton(
              onPressed: () => Navigator.pop(ctx, 0.0),
              child: const Text('Remove', style: TextStyle(color: AppTheme.errorColor)),
            ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, double.tryParse(controller.text.trim())),
            child: const Text('Save'),
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
    final progress = _dataService.budgetProgress(scope: _scope);
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
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text('Budgets', style: AppTheme.headingMedium),
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
                              s == TransactionScope.personal ? 'Personal' : 'Family',
                              style: AppTheme.bodyMedium.copyWith(
                                color: selected ? Colors.white : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Builder(builder: (context) {
                final summary = _dataService.budgetSummary(scope: _scope);
                final base = _dataService.baseCurrency;
                final totalBudget = summary['totalBudget'] as double;
                final totalSpent = summary['totalSpent'] as double;
                final overCount = summary['overCount'] as int;
                final nearCount = summary['nearCount'] as int;
                final budgetCount = summary['budgetCount'] as int;

                if (budgetCount == 0) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Spent this month', style: AppTheme.bodySmall),
                                  Text(
                                    '$base ${totalSpent.toStringAsFixed(0)} / ${totalBudget.toStringAsFixed(0)}',
                                    style: AppTheme.headingSmall.copyWith(
                                      color: totalSpent > totalBudget ? AppTheme.errorColor : AppTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (overCount > 0)
                              _statusPill('$overCount over', AppTheme.errorColor)
                            else if (nearCount > 0)
                              _statusPill('$nearCount close', AppTheme.accentAmber)
                            else
                              _statusPill('On track', AppTheme.successColor),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: totalBudget <= 0 ? 0 : (totalSpent / totalBudget).clamp(0, 1),
                            minHeight: 6,
                            backgroundColor: AppTheme.glassBackground,
                            valueColor: AlwaysStoppedAnimation(totalSpent > totalBudget ? AppTheme.errorColor : AppTheme.successColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
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
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: c.color.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: Icon(c.icon, color: c.color, size: 16),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: Text(c.name, style: AppTheme.bodyLarge)),
                              if (limit > 0)
                                Text(
                                  '$base ${spent.toStringAsFixed(0)} / ${limit.toStringAsFixed(0)}',
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: over ? AppTheme.errorColor : AppTheme.textSecondary,
                                  ),
                                )
                              else
                                Text('Set budget', style: AppTheme.bodySmall.copyWith(color: AppTheme.accentAmber)),
                            ],
                          ),
                          if (limit > 0) ...[
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: pct.clamp(0, 1),
                                minHeight: 6,
                                backgroundColor: AppTheme.glassBackground,
                                valueColor: AlwaysStoppedAnimation(over ? AppTheme.errorColor : c.color),
                              ),
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
