import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/scope_toggle.dart';
import 'tag_insights_screen.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

enum _RangeView { month, year }

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _dataService = DataService();
  TransactionScope? _scopeFilter;
  _RangeView _range = _RangeView.month;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool _vsLastYear = false;

  void _shiftMonth(int delta) {
    setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + delta));
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final trend = _range == _RangeView.month
        ? _dataService.monthlyTrend(6, scope: _scopeFilter)
        : _dataService.yearlyMonthlyBreakdown(now.year, scope: _scopeFilter);
    final breakdown = _range == _RangeView.month
        ? _dataService.categoryBreakdown(_selectedMonth.year, _selectedMonth.month, scope: _scopeFilter)
        : _dataService.yearlyCategoryBreakdown(now.year, scope: _scopeFilter);
    final incomeBreakdown = _range == _RangeView.month
        ? _dataService.categoryBreakdown(_selectedMonth.year, _selectedMonth.month, scope: _scopeFilter, type: TransactionType.income)
        : _dataService.yearlyCategoryBreakdown(now.year, scope: _scopeFilter, type: TransactionType.income);
    final base = _dataService.baseCurrency;
    final comparison = _dataService.compareMonth(_selectedMonth.year, _selectedMonth.month, scope: _scopeFilter, vsLastYear: _vsLastYear);
    final isCurrentMonth = _selectedMonth.year == now.year && _selectedMonth.month == now.month;

    final sortedBreakdown = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final totalExpense = breakdown.values.fold<double>(0, (a, b) => a + b);
    final sortedIncomeBreakdown = incomeBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final totalIncome = incomeBreakdown.values.fold<double>(0, (a, b) => a + b);

    final maxY = trend
        .map((m) => [m['income'] as double, m['expense'] as double])
        .expand((e) => e)
        .fold<double>(0, (a, b) => a > b ? a : b);

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
                  Text('Analytics', style: AppTheme.headingMedium),
                ],
              ),
              const SizedBox(height: 8),

              ScopeToggle(value: _scopeFilter, onChanged: (v) => setState(() => _scopeFilter = v)),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.glassBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.glassBorder),
                ),
                child: Row(
                  children: [
                    _rangeTab('This month', _RangeView.month),
                    _rangeTab('This year', _RangeView.year),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              if (_range == _RangeView.year) ...[
                GlassCard(
                  child: Builder(builder: (context) {
                    final yearTotals = _dataService.yearlyTotals(now.year, scope: _scopeFilter);
                    return Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${now.year} income', style: AppTheme.bodySmall),
                              Text('$base ${(yearTotals['income'] ?? 0).toStringAsFixed(2)}',
                                  style: AppTheme.headingSmall.copyWith(color: AppTheme.successColor)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${now.year} expense', style: AppTheme.bodySmall),
                              Text('$base ${(yearTotals['expense'] ?? 0).toStringAsFixed(2)}',
                                  style: AppTheme.headingSmall.copyWith(color: AppTheme.primaryCoral)),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                ),
                const SizedBox(height: 20),
              ],

              if (_range == _RangeView.month) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, color: AppTheme.textSecondary),
                      onPressed: () => _shiftMonth(-1),
                    ),
                    Text(
                      isCurrentMonth ? 'This month · ${DateFormat('MMM yyyy').format(_selectedMonth)}' : DateFormat('MMMM yyyy').format(_selectedMonth),
                      style: AppTheme.headingSmall,
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                      onPressed: isCurrentMonth ? null : () => _shiftMonth(1),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Income', style: AppTheme.bodySmall),
                                Text(
                                  '$base ${(comparison['current']['income'] ?? 0).toStringAsFixed(2)}',
                                  style: AppTheme.headingSmall.copyWith(color: AppTheme.successColor),
                                ),
                                _changeLabel(comparison['incomeChangePct'] as double),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Expense', style: AppTheme.bodySmall),
                                Text(
                                  '$base ${(comparison['current']['expense'] ?? 0).toStringAsFixed(2)}',
                                  style: AppTheme.headingSmall.copyWith(color: AppTheme.primaryCoral),
                                ),
                                _changeLabel(comparison['expenseChangePct'] as double, higherIsBad: true),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'vs ${DateFormat('MMM yyyy').format(DateTime(comparison['previousYear'], comparison['previousMonth']))}',
                            style: AppTheme.caption,
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _vsLastYear = !_vsLastYear),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.glassBackground,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.glassBorder),
                              ),
                              child: Text(
                                _vsLastYear ? 'Compare: last year' : 'Compare: last month',
                                style: AppTheme.caption.copyWith(color: AppTheme.accentAmber),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              Text(
                _range == _RangeView.month ? 'Income vs expense (6 months)' : 'Income vs expense (${now.year})',
                style: AppTheme.headingSmall,
              ),
              const SizedBox(height: 12),
              GlassCard(
                child: SizedBox(
                  height: 220,
                  child: maxY == 0
                      ? Center(child: Text('No data yet', style: AppTheme.bodyMedium))
                      : BarChart(
                          BarChartData(
                            maxY: maxY * 1.2,
                            barTouchData: BarTouchData(enabled: true),
                            titlesData: FlTitlesData(
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final i = value.toInt();
                                    if (i < 0 || i >= trend.length) return const SizedBox();
                                    final m = trend[i];
                                    final label = DateFormat('MMM').format(DateTime(m['year'], m['month']));
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(label, style: AppTheme.caption),
                                    );
                                  },
                                ),
                              ),
                            ),
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                            barGroups: List.generate(trend.length, (i) {
                              final m = trend[i];
                              return BarChartGroupData(
                                x: i,
                                barRods: [
                                  BarChartRodData(
                                    toY: m['income'] as double,
                                    color: AppTheme.successColor,
                                    width: 8,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  BarChartRodData(
                                    toY: m['expense'] as double,
                                    color: AppTheme.primaryCoral,
                                    width: 8,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _legendDot(AppTheme.successColor, 'Income'),
                  const SizedBox(width: 16),
                  _legendDot(AppTheme.primaryCoral, 'Expense'),
                ],
              ),
              const SizedBox(height: 24),

              Text(
                _range == _RangeView.month
                    ? 'Spending by category (${DateFormat('MMM yyyy').format(_selectedMonth)})'
                    : 'Spending by category (${now.year})',
                style: AppTheme.headingSmall,
              ),
              const SizedBox(height: 12),
              GlassCard(
                child: sortedBreakdown.isEmpty
                    ? Center(child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _range == _RangeView.month ? 'No expenses recorded that month' : 'No expenses recorded this year',
                          style: AppTheme.bodyMedium,
                        ),
                      ))
                    : Column(
                        children: [
                          SizedBox(
                            height: 180,
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 40,
                                sections: sortedBreakdown.map((entry) {
                                  final category = _dataService.getCategoryById(entry.key);
                                  final pct = totalExpense == 0 ? 0 : (entry.value / totalExpense * 100);
                                  return PieChartSectionData(
                                    value: entry.value,
                                    color: category?.color ?? AppTheme.otherColor,
                                    title: '${pct.toStringAsFixed(0)}%',
                                    radius: 45,
                                    titleStyle: AppTheme.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...sortedBreakdown.map((entry) {
                            final category = _dataService.getCategoryById(entry.key);
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: category?.color ?? AppTheme.otherColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(category?.name ?? 'Other', style: AppTheme.bodyMedium)),
                                  Text('$base ${entry.value.toStringAsFixed(2)}', style: AppTheme.bodyMedium),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
              ),
              const SizedBox(height: 24),

              Text(
                _range == _RangeView.month
                    ? 'Income by category (${DateFormat('MMM yyyy').format(_selectedMonth)})'
                    : 'Income by category (${now.year})',
                style: AppTheme.headingSmall,
              ),
              const SizedBox(height: 12),
              GlassCard(
                child: sortedIncomeBreakdown.isEmpty
                    ? Center(child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _range == _RangeView.month ? 'No income recorded that month' : 'No income recorded this year',
                          style: AppTheme.bodyMedium,
                        ),
                      ))
                    : Column(
                        children: [
                          SizedBox(
                            height: 180,
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 40,
                                sections: sortedIncomeBreakdown.map((entry) {
                                  final category = _dataService.getCategoryById(entry.key);
                                  final pct = totalIncome == 0 ? 0 : (entry.value / totalIncome * 100);
                                  return PieChartSectionData(
                                    value: entry.value,
                                    color: category?.color ?? AppTheme.otherColor,
                                    title: '${pct.toStringAsFixed(0)}%',
                                    radius: 45,
                                    titleStyle: AppTheme.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...sortedIncomeBreakdown.map((entry) {
                            final category = _dataService.getCategoryById(entry.key);
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: category?.color ?? AppTheme.otherColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(category?.name ?? 'Other', style: AppTheme.bodyMedium)),
                                  Text('$base ${entry.value.toStringAsFixed(2)}', style: AppTheme.bodyMedium),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
              ),
              const SizedBox(height: 24),

              Builder(builder: (context) {
                final tagFrom = _range == _RangeView.month
                    ? DateTime(_selectedMonth.year, _selectedMonth.month, 1)
                    : DateTime(now.year, 1, 1);
                final tagTo = _range == _RangeView.month
                    ? DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0, 23, 59, 59)
                    : DateTime(now.year, 12, 31, 23, 59, 59);
                final tagData = _dataService.tagBreakdown(from: tagFrom, to: tagTo, scope: _scopeFilter);
                final sortedTags = tagData.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
                final topTags = sortedTags.take(5).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Top tags', style: AppTheme.headingSmall),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const TagInsightsScreen()),
                          ),
                          child: Text('See all', style: AppTheme.bodySmall.copyWith(color: AppTheme.primaryCoral)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GlassCard(
                      child: topTags.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                'No tagged expenses in this period yet.',
                                style: AppTheme.bodyMedium,
                              ),
                            )
                          : Column(
                              children: topTags.map((entry) {
                                final pct = tagData.values.fold<double>(0, (a, b) => a + b) == 0
                                    ? 0.0
                                    : entry.value / tagData.values.fold<double>(0, (a, b) => a + b);
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(child: Text(entry.key, style: AppTheme.bodyMedium)),
                                          Text('$base ${entry.value.toStringAsFixed(2)}', style: AppTheme.bodyMedium),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(3),
                                        child: LinearProgressIndicator(
                                          value: pct,
                                          minHeight: 4,
                                          backgroundColor: AppTheme.glassBackground,
                                          valueColor: const AlwaysStoppedAnimation(AppTheme.accentAmber),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                    ),
                  ],
                );
              }),
              const SizedBox(height: 24),

              Builder(builder: (context) {
                final srcFrom = _range == _RangeView.month
                    ? DateTime(_selectedMonth.year, _selectedMonth.month, 1)
                    : DateTime(now.year, 1, 1);
                final srcTo = _range == _RangeView.month
                    ? DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0, 23, 59, 59)
                    : DateTime(now.year, 12, 31, 23, 59, 59);
                final sources = _dataService.paymentSourceBreakdown(from: srcFrom, to: srcTo, scope: _scopeFilter);
                final sourceTotal = sources.fold<double>(0, (a, b) => a + (b['amount'] as double));

                if (sources.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Spent by payment method', style: AppTheme.headingSmall),
                    const SizedBox(height: 12),
                    GlassCard(
                      child: Column(
                        children: sources.map((s) {
                          final label = s['label'] as String;
                          final amount = s['amount'] as double;
                          final color = s['color'] as Color;
                          final pct = sourceTotal == 0 ? 0.0 : amount / sourceTotal;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(label, style: AppTheme.bodyMedium)),
                                    Text('$base ${amount.toStringAsFixed(2)}', style: AppTheme.bodyMedium),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: LinearProgressIndicator(
                                    value: pct,
                                    minHeight: 4,
                                    backgroundColor: AppTheme.glassBackground,
                                    valueColor: AlwaysStoppedAnimation(color),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                );
              }),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rangeTab(String label, _RangeView view) {
    final selected = _range == view;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _range = view),
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
            style: AppTheme.bodyMedium.copyWith(
              color: selected ? Colors.white : AppTheme.textSecondary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _changeLabel(double pct, {bool higherIsBad = false}) {
    final isUp = pct >= 0;
    final isGood = higherIsBad ? !isUp : isUp;
    final color = pct == 0 ? AppTheme.textTertiary : (isGood ? AppTheme.successColor : AppTheme.errorColor);
    final arrow = pct == 0 ? '' : (isUp ? '▲ ' : '▼ ');
    final period = _vsLastYear ? 'last year' : 'last month';
    return Text(
      '$arrow${pct.abs().toStringAsFixed(0)}% vs $period',
      style: AppTheme.caption.copyWith(color: color),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: AppTheme.caption),
      ],
    );
  }
}
