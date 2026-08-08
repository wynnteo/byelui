import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/scope_toggle.dart';

enum _TagRange { month, year, all }

class TagInsightsScreen extends StatefulWidget {
  const TagInsightsScreen({super.key});

  @override
  State<TagInsightsScreen> createState() => _TagInsightsScreenState();
}

class _TagInsightsScreenState extends State<TagInsightsScreen> {
  final _dataService = DataService();
  TransactionScope? _scopeFilter;
  _TagRange _range = _TagRange.month;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    DateTime? from;
    DateTime? to;
    if (_range == _TagRange.month) {
      from = DateTime(now.year, now.month, 1);
      to = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    } else if (_range == _TagRange.year) {
      from = DateTime(now.year, 1, 1);
      to = DateTime(now.year, 12, 31, 23, 59, 59);
    }

    final breakdown = _dataService.tagBreakdown(from: from, to: to, scope: _scopeFilter);
    final sorted = breakdown.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final total = breakdown.values.fold<double>(0, (a, b) => a + b);
    final base = _dataService.baseCurrency;

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
                    Text('Tag insights', style: AppTheme.headingMedium),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ScopeToggle(value: _scopeFilter, onChanged: (v) => setState(() => _scopeFilter = v)),
              ),
              const SizedBox(height: 10),
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
                    children: [
                      _rangeTab('This month', _TagRange.month),
                      _rangeTab('This year', _TagRange.year),
                      _rangeTab('All time', _TagRange.all),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: sorted.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'No tagged expenses yet.\nAdd tags on a transaction, or ByeLui will '
                            'suggest one automatically from the description (e.g. Shopee, Bubble tea).',
                            textAlign: TextAlign.center,
                            style: AppTheme.bodyMedium,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: sorted.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (ctx, i) {
                          final entry = sorted[i];
                          final pct = total == 0 ? 0.0 : entry.value / total;
                          return GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Text(entry.key, style: AppTheme.bodyLarge)),
                                    Text('$base ${entry.value.toStringAsFixed(2)}', style: AppTheme.bodyLarge),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: LinearProgressIndicator(
                                    value: pct,
                                    minHeight: 6,
                                    backgroundColor: AppTheme.glassBackground,
                                    valueColor: const AlwaysStoppedAnimation(AppTheme.primaryCoral),
                                  ),
                                ),
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

  Widget _rangeTab(String label, _TagRange range) {
    final selected = _range == range;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _range = range),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primaryCoral : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTheme.bodySmall.copyWith(
              color: selected ? Colors.white : AppTheme.textSecondary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
