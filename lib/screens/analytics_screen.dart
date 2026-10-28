import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/scope_toggle.dart';
import 'tag_insights_screen.dart';
import '../i18n/s.dart';

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
  int _selectedYear = DateTime.now().year;
  bool _vsLastYear = false;

  void _shiftMonth(int delta) {
    final target = DateTime(_selectedMonth.year, _selectedMonth.month + delta);
    final now = DateTime.now();
    if (target.isAfter(DateTime(now.year, now.month))) return;
    setState(() => _selectedMonth = target);
  }

  void _shiftYear(int delta) {
    final target = _selectedYear + delta;
    if (target > DateTime.now().year) return;
    setState(() => _selectedYear = target);
  }

  @override
  Widget build(BuildContext context) {
    try {
      return _buildContent(context);
    } catch (e, st) {
      debugPrint('AnalyticsScreen failed to build: $e\n$st');
      return Scaffold(
        backgroundColor: AppTheme.primaryCharcoal,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: AppTheme.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(S.t.analytics, style: AppTheme.headingMedium),
                  ],
                ),
                const SizedBox(height: 20),
                Text('Analytics couldn\'t load. Please screenshot this and send it back:', style: AppTheme.bodyLarge),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.glassBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.glassBorder),
                  ),
                  child: SelectableText('$e', style: AppTheme.bodySmall),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildContent(BuildContext context) {
    final now = DateTime.now();
    final trend = _range == _RangeView.month
        ? _dataService.monthlyTrend(6, scope: _scopeFilter, endingAt: _selectedMonth)
        : _dataService.yearlyMonthlyBreakdown(_selectedYear, scope: _scopeFilter);
    final breakdown = _range == _RangeView.month
        ? _dataService.categoryBreakdown(_selectedMonth.year, _selectedMonth.month, scope: _scopeFilter)
        : _dataService.yearlyCategoryBreakdown(_selectedYear, scope: _scopeFilter);
    final incomeBreakdown = _range == _RangeView.month
        ? _dataService.categoryBreakdown(_selectedMonth.year, _selectedMonth.month, scope: _scopeFilter, type: TransactionType.income)
        : _dataService.yearlyCategoryBreakdown(_selectedYear, scope: _scopeFilter, type: TransactionType.income);
    final base = _dataService.baseCurrency;
    final comparison = _dataService.compareMonth(_selectedMonth.year, _selectedMonth.month, scope: _scopeFilter, vsLastYear: _vsLastYear);
    final isCurrentMonth = _selectedMonth.year == now.year && _selectedMonth.month == now.month;

    final sortedBreakdown = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final totalExpense = breakdown.values.fold<double>(0, (a, b) => a + b);
    final sortedIncomeBreakdown = incomeBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final totalIncome = incomeBreakdown.values.fold<double>(0, (a, b) => a + b);
    List<String> insights = [];
    try {
      if (_range == _RangeView.month) {
        insights = _dataService.monthlyInsights(month: _selectedMonth, scope: _scopeFilter);
      }
    } catch (e, st) {
      debugPrint('monthlyInsights failed: $e\n$st');
    }

    final highlightYear = _range == _RangeView.month ? _selectedMonth.year : _selectedYear;
    Map<String, dynamic> highlights = {
      'topCategoryId': null,
      'topCategoryAmount': 0.0,
      'topMonth': null,
      'topMonthAmount': 0.0,
    };
    try {
      highlights = _dataService.yearHighlights(highlightYear, scope: _scopeFilter);
    } catch (e, st) {
      debugPrint('yearHighlights failed: $e\n$st');
    }

    final maxY = trend
        .map((m) => [m['income'] as double, m['expense'] as double])
        .expand((e) => e)
        .fold<double>(0, (a, b) => a > b ? a : b);

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
                  Text(S.t.analytics, style: AppTheme.headingMedium),
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
                    _rangeTab(S.t.thisMonth, _RangeView.month),
                    _rangeTab(S.t.thisYear, _RangeView.year),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              if (_range == _RangeView.year) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      tooltip: 'Previous year',
                      icon: Icon(Icons.chevron_left, color: AppTheme.textSecondary),
                      onPressed: () => _shiftYear(-1),
                    ),
                    Text('$_selectedYear', style: AppTheme.headingSmall),
                    IconButton(
                      tooltip: 'Next year',
                      icon: Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                      onPressed: _selectedYear >= now.year ? null : () => _shiftYear(1),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                GlassCard(
                  child: Builder(builder: (context) {
                    final yearTotals = _dataService.yearlyTotals(_selectedYear, scope: _scopeFilter);
                    return Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(S.t.yearIncome(_selectedYear), style: AppTheme.bodySmall),
                              Text('$base ${(yearTotals['income'] ?? 0).toStringAsFixed(2)}',
                                  style: AppTheme.headingSmall.copyWith(color: AppTheme.successColor)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(S.t.yearExpense(_selectedYear), style: AppTheme.bodySmall),
                              Text('$base ${(yearTotals['expense'] ?? 0).toStringAsFixed(2)}',
                                  style: AppTheme.headingSmall.copyWith(color: AppTheme.stampText)),
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
                                Text(S.t.income, style: AppTheme.bodySmall),
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
                                Text(S.t.expense, style: AppTheme.bodySmall),
                                Text(
                                  '$base ${(comparison['current']['expense'] ?? 0).toStringAsFixed(2)}',
                                  style: AppTheme.headingSmall.copyWith(color: AppTheme.stampText),
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
                            S.t.vsMonth(S.monthYearShort(DateTime(comparison['previousYear'], comparison['previousMonth']))),
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
                                _vsLastYear ? S.t.compareLastYear : S.t.compareLastMonth,
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

              if (insights.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, size: 18, color: AppTheme.accentAmber),
                    const SizedBox(width: 8),
                    Text(S.t.insights, style: AppTheme.headingSmall),
                  ],
                ),
                const SizedBox(height: 12),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: insights
                        .map((text) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('💡 '),
                                  Expanded(child: Text(text, style: AppTheme.bodyMedium)),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              if (highlights['topCategoryId'] != null || highlights['topMonth'] != null) ...[
                Row(
                  children: [
                    Icon(Icons.emoji_events_outlined, size: 18, color: AppTheme.stampText),
                    const SizedBox(width: 8),
                    Text(S.t.yearHighlights(highlightYear), style: AppTheme.headingSmall),
                  ],
                ),
                const SizedBox(height: 12),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                    if (highlights['topCategoryId'] != null)
                      Expanded(
                        child: GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(S.t.biggestCategory, style: AppTheme.caption),
                              const SizedBox(height: 4),
                              Text(
                                _dataService.getCategoryById(highlights['topCategoryId'])?.displayName ?? S.t.other,
                                style: AppTheme.bodyLarge,
                              ),
                              Text(
                                '$base ${(highlights['topCategoryAmount'] as double).toStringAsFixed(0)}',
                                style: AppTheme.bodyMedium.copyWith(color: AppTheme.stampText),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (highlights['topCategoryId'] != null && highlights['topMonth'] != null)
                      const SizedBox(width: 12),
                    if (highlights['topMonth'] != null)
                      Expanded(
                        child: GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(S.t.highestSpendingMonth, style: AppTheme.caption),
                              const SizedBox(height: 4),
                              Text(
                                S.monthLong(DateTime(highlightYear, highlights['topMonth'] as int)),
                                style: AppTheme.bodyLarge,
                              ),
                              Text(
                                '$base ${(highlights['topMonthAmount'] as double).toStringAsFixed(0)}',
                                style: AppTheme.bodyMedium.copyWith(color: AppTheme.stampText),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              Text(
                _range == _RangeView.month ? S.t.incomeVsExpense6m : S.t.incomeVsExpenseYear(_selectedYear),
                style: AppTheme.headingSmall,
              ),
              const SizedBox(height: 12),
              GlassCard(
                child: SizedBox(
                  height: 220,
                  child: maxY == 0
                      ? Center(child: Text(S.t.noDataYet, style: AppTheme.bodyMedium))
                      : BarChart(
                          BarChartData(
                            maxY: maxY * 1.2,
                            barTouchData: BarTouchData(
                              enabled: true,
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipColor: (group) => AppTheme.paperRaised,
                                tooltipBorder: BorderSide(color: AppTheme.paperLine),
                                tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                  final label = rodIndex == 0 ? S.t.income : S.t.expense;
                                  return BarTooltipItem(
                                    '$label\n',
                                    TextStyle(color: AppTheme.ink, fontWeight: FontWeight.w700, fontSize: 11),
                                    children: [
                                      TextSpan(
                                        text: '$base ${rod.toY.toStringAsFixed(2)}',
                                        style: AppTheme.numeral(size: 11, color: AppTheme.ink),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
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
                                    final label = S.monthShort(DateTime(m['year'], m['month']));
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
                                    color: AppTheme.warn,
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
                  _legendDot(AppTheme.successColor, S.t.income),
                  const SizedBox(width: 16),
                  _legendDot(AppTheme.warn, S.t.expense),
                ],
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Icon(Icons.pie_chart_outline_rounded, size: 18, color: AppTheme.stampText),
                  const SizedBox(width: 8),
                  Text(S.t.spendingByCategory, style: AppTheme.headingSmall),
                ],
              ),
              const SizedBox(height: 12),
              GlassCard(
                child: sortedBreakdown.isEmpty
                    ? Center(child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _range == _RangeView.month ? S.t.noExpensesMonth : S.t.noExpensesYear,
                          style: AppTheme.bodyMedium,
                        ),
                      ))
                    : Column(
                        children: [
                          SizedBox(
                            height: 180,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                PieChart(
                                  PieChartData(
                                    sectionsSpace: 2,
                                    centerSpaceRadius: 45,
                                    sections: sortedBreakdown.map((entry) {
                                      final category = _dataService.getCategoryById(entry.key);
                                      final pct = totalExpense == 0 ? 0 : (entry.value / totalExpense * 100);
                                      return PieChartSectionData(
                                        value: entry.value,
                                        color: category?.color ?? AppTheme.otherColor,
                                        title: '${pct.toStringAsFixed(0)}%',
                                        radius: 40,
                                        titleStyle: AppTheme.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                                      );
                                    }).toList(),
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(S.t.total, style: AppTheme.caption),
                                    Text(
                                      '$base ${totalExpense.toStringAsFixed(0)}',
                                      style: AppTheme.headingSmall.copyWith(color: AppTheme.stampText),
                                    ),
                                  ],
                                ),
                              ],
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
                                  Expanded(child: Text(category?.displayName ?? S.t.other, style: AppTheme.bodyMedium)),
                                  Text('$base ${entry.value.toStringAsFixed(2)}', style: AppTheme.bodyMedium),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Icon(Icons.savings_outlined, size: 18, color: AppTheme.successColor),
                  const SizedBox(width: 8),
                  Text(S.t.incomeByCategory, style: AppTheme.headingSmall),
                ],
              ),
              const SizedBox(height: 12),
              GlassCard(
                child: sortedIncomeBreakdown.isEmpty
                    ? Center(child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _range == _RangeView.month ? S.t.noIncomeMonth : S.t.noIncomeYear,
                          style: AppTheme.bodyMedium,
                        ),
                      ))
                    : Column(
                        children: [
                          SizedBox(
                            height: 180,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                PieChart(
                                  PieChartData(
                                    sectionsSpace: 2,
                                    centerSpaceRadius: 45,
                                    sections: sortedIncomeBreakdown.map((entry) {
                                      final category = _dataService.getCategoryById(entry.key);
                                      final pct = totalIncome == 0 ? 0 : (entry.value / totalIncome * 100);
                                      return PieChartSectionData(
                                        value: entry.value,
                                        color: category?.color ?? AppTheme.otherColor,
                                        title: '${pct.toStringAsFixed(0)}%',
                                        radius: 40,
                                        titleStyle: AppTheme.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                                      );
                                    }).toList(),
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(S.t.total, style: AppTheme.caption),
                                    Text(
                                      '$base ${totalIncome.toStringAsFixed(0)}',
                                      style: AppTheme.headingSmall.copyWith(color: AppTheme.successColor),
                                    ),
                                  ],
                                ),
                              ],
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
                                  Expanded(child: Text(category?.displayName ?? S.t.other, style: AppTheme.bodyMedium)),
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
                    : DateTime(_selectedYear, 1, 1);
                final tagTo = _range == _RangeView.month
                    ? DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0, 23, 59, 59)
                    : DateTime(_selectedYear, 12, 31, 23, 59, 59);
                final tagData = _dataService.tagBreakdown(from: tagFrom, to: tagTo, scope: _scopeFilter);
                final sortedTags = tagData.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
                final topTags = sortedTags.take(5).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(S.t.topTags, style: AppTheme.headingSmall),
                        InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const TagInsightsScreen()),
                          ),
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
                    GlassCard(
                      child: topTags.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                S.t.noTaggedExpensesPeriod,
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
                    : DateTime(_selectedYear, 1, 1);
                final srcTo = _range == _RangeView.month
                    ? DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0, 23, 59, 59)
                    : DateTime(_selectedYear, 12, 31, 23, 59, 59);
                final sources = _dataService.paymentSourceBreakdown(from: srcFrom, to: srcTo, scope: _scopeFilter);
                final sourceTotal = sources.fold<double>(0, (a, b) => a + (b['amount'] as double));

                if (sources.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(S.t.spentByPaymentMethod, style: AppTheme.headingSmall),
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
              color: selected ? AppTheme.onStamp : AppTheme.textSecondary,
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
    final period = _vsLastYear ? S.t.periodLastYear : S.t.periodLastMonth;
    return Text(
      S.t.percentVsPeriod('$arrow${pct.abs().toStringAsFixed(0)}', period),
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
