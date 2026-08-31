import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/scope_toggle.dart';
import '../widgets/swipeable_transaction_card.dart';
import 'transaction_form_screen.dart';

enum _Period { today, thisWeek, thisMonth, thisYear, allTime, custom }

class AllTransactionsScreen extends StatefulWidget {
  const AllTransactionsScreen({super.key});

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  final _dataService = DataService();
  final _searchController = TextEditingController();
  String _search = '';

  TransactionType? _typeFilter;
  TransactionScope? _scopeFilter;
  String? _categoryFilter;
  _Period _period = _Period.thisMonth;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTimeRange? _customRange;

  bool get _isSearching => _search.trim().isNotEmpty;

  bool get _hasActiveFilters =>
      _typeFilter != null || _scopeFilter != null || _categoryFilter != null || _period != _Period.thisMonth;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  void _clearFilters() {
    setState(() {
      _typeFilter = null;
      _scopeFilter = null;
      _categoryFilter = null;
      _period = _Period.thisMonth;
      _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
      _customRange = null;
    });
  }

  void _shiftMonth(int delta) {
    setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + delta));
  }

  ({DateTime? from, DateTime? to}) _resolvedRange() {
    if (_isSearching) return (from: null, to: null);
    final now = DateTime.now();
    switch (_period) {
      case _Period.today:
        final start = DateTime(now.year, now.month, now.day);
        return (from: start, to: DateTime(now.year, now.month, now.day, 23, 59, 59));
      case _Period.thisWeek:
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
        final end = start.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
        return (from: start, to: end);
      case _Period.thisMonth:
        return (
        from: DateTime(_selectedMonth.year, _selectedMonth.month, 1),
        to: DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0, 23, 59, 59),
        );
      case _Period.thisYear:
        return (from: DateTime(now.year, 1, 1), to: DateTime(now.year, 12, 31, 23, 59, 59));
      case _Period.allTime:
        return (from: null, to: null);
      case _Period.custom:
        if (_customRange == null) return (from: null, to: null);
        return (
        from: _customRange!.start,
        to: DateTime(_customRange!.end.year, _customRange!.end.month, _customRange!.end.day, 23, 59, 59),
        );
    }
  }

  String get _periodLabel {
    final now = DateTime.now();
    switch (_period) {
      case _Period.today:
        return 'Today · ${DateFormat('EEE, d MMM').format(now)}';
      case _Period.thisWeek:
        return 'This week';
      case _Period.thisMonth:
        final isCurrentMonth = _selectedMonth.year == now.year && _selectedMonth.month == now.month;
        return isCurrentMonth ? 'This month' : DateFormat('MMMM yyyy').format(_selectedMonth);
      case _Period.thisYear:
        return 'This year (${now.year})';
      case _Period.allTime:
        return 'All time';
      case _Period.custom:
        if (_customRange == null) return 'Custom range';
        return '${DateFormat('d MMM').format(_customRange!.start)} – ${DateFormat('d MMM yyyy').format(_customRange!.end)}';
    }
  }

  Future<void> _openFilterSheet() async {
    TransactionType? tempType = _typeFilter;
    TransactionScope? tempScope = _scopeFilter;
    String? tempCategory = _categoryFilter;
    _Period tempPeriod = _period;
    DateTimeRange? tempCustomRange = _customRange;
    final categories = _dataService.getCategories();

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.primaryCharcoal,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Filters', style: AppTheme.headingMedium),
                          TextButton(
                            onPressed: () => setSheetState(() {
                              tempType = null;
                              tempScope = null;
                              tempCategory = null;
                              tempPeriod = _Period.thisMonth;
                              tempCustomRange = null;
                            }),
                            child: Text('Reset', style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Text('Type', style: AppTheme.bodySmall),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          _sheetChip('All', tempType == null, () => setSheetState(() => tempType = null)),
                          _sheetChip('Income', tempType == TransactionType.income,
                                  () => setSheetState(() => tempType = TransactionType.income)),
                          _sheetChip('Expense', tempType == TransactionType.expense,
                                  () => setSheetState(() => tempType = TransactionType.expense)),
                        ],
                      ),
                      const SizedBox(height: 20),

                      Text('Who', style: AppTheme.bodySmall),
                      const SizedBox(height: 8),
                      ScopeToggle(value: tempScope, onChanged: (v) => setSheetState(() => tempScope = v)),
                      const SizedBox(height: 20),

                      Text('Period', style: AppTheme.bodySmall),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _sheetChip('Today', tempPeriod == _Period.today, () => setSheetState(() => tempPeriod = _Period.today)),
                          _sheetChip('This week', tempPeriod == _Period.thisWeek, () => setSheetState(() => tempPeriod = _Period.thisWeek)),
                          _sheetChip('This month', tempPeriod == _Period.thisMonth, () => setSheetState(() => tempPeriod = _Period.thisMonth)),
                          _sheetChip('This year', tempPeriod == _Period.thisYear, () => setSheetState(() => tempPeriod = _Period.thisYear)),
                          _sheetChip('All time', tempPeriod == _Period.allTime, () => setSheetState(() => tempPeriod = _Period.allTime)),
                          GestureDetector(
                            onTap: () async {
                              final picked = await showDateRangePicker(
                                context: ctx,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now().add(const Duration(days: 1)),
                                initialDateRange: tempCustomRange,
                              );
                              if (picked != null) {
                                setSheetState(() {
                                  tempCustomRange = picked;
                                  tempPeriod = _Period.custom;
                                });
                              }
                            },
                            child: _sheetChipStatic(
                              tempPeriod == _Period.custom && tempCustomRange != null ? 'Custom ✓' : 'Custom range',
                              tempPeriod == _Period.custom,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      Text('Category', style: AppTheme.bodySmall),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _sheetChip('All categories', tempCategory == null, () => setSheetState(() => tempCategory = null)),
                          ...categories.map((c) => _sheetChip(
                            c.name,
                            tempCategory == c.id,
                                () => setSheetState(() => tempCategory = c.id),
                          )),
                        ],
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: Container(
                          decoration: BoxDecoration(gradient: AppTheme.buttonGradient, borderRadius: BorderRadius.circular(16)),
                          child: ElevatedButton(
                            style: AppTheme.primaryButtonStyle,
                            onPressed: () {
                              setState(() {
                                _typeFilter = tempType;
                                _scopeFilter = tempScope;
                                _categoryFilter = tempCategory;
                                _period = tempPeriod;
                                _customRange = tempCustomRange;
                              });
                              Navigator.pop(ctx);
                            },
                            child: const Text('Apply filters'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _sheetChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: _sheetChipStatic(label, selected));
  }

  Widget _sheetChipStatic(String label, bool selected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? AppTheme.primaryCoral : AppTheme.glassBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: selected ? AppTheme.primaryCoral : AppTheme.glassBorder),
      ),
      child: Text(label, style: AppTheme.bodySmall.copyWith(color: selected ? Colors.white : AppTheme.textSecondary)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final range = _resolvedRange();
    final transactions = _dataService.getTransactions(
      scope: _scopeFilter,
      type: _typeFilter,
      categoryId: _categoryFilter,
      searchQuery: _search,
      from: range.from,
      to: range.to,
    );

    double income = 0, expense = 0;
    for (final t in transactions) {
      final converted = _dataService.convertToBase(t.amount, t.currency);
      if (t.isIncome) {
        income += converted;
      } else {
        expense += converted;
      }
    }
    final base = _dataService.baseCurrency;
    final now = DateTime.now();
    final isCurrentMonth = _selectedMonth.year == now.year && _selectedMonth.month == now.month;

    return Scaffold(
      backgroundColor: AppTheme.primaryCharcoal,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text('All transactions', style: AppTheme.headingMedium),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  style: AppTheme.bodyLarge,
                  onChanged: (v) => setState(() => _search = v),
                  decoration: AppTheme.glassInputDecoration(
                    hintText: 'Search description, note, tag...',
                    prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary, size: 20),
                    suffixIcon: _search.isEmpty
                        ? null
                        : IconButton(
                      icon: const Icon(Icons.clear, color: AppTheme.textSecondary, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _search = '');
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              if (!_isSearching) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _openFilterSheet,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _hasActiveFilters ? AppTheme.primaryCoral.withOpacity(0.2) : AppTheme.glassBackground,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _hasActiveFilters ? AppTheme.primaryCoral : AppTheme.glassBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.tune, size: 16, color: _hasActiveFilters ? AppTheme.primaryCoral : AppTheme.textSecondary),
                              const SizedBox(width: 6),
                              Text(
                                'Filters',
                                style: AppTheme.bodySmall.copyWith(color: _hasActiveFilters ? AppTheme.primaryCoral : AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _period == _Period.thisMonth
                            ? Row(
                          children: [
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(Icons.chevron_left, size: 20, color: AppTheme.textSecondary),
                              onPressed: () => _shiftMonth(-1),
                            ),
                            Expanded(
                              child: Text(_periodLabel, style: AppTheme.bodyMedium, textAlign: TextAlign.center),
                            ),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(Icons.chevron_right, size: 20, color: AppTheme.textSecondary),
                              onPressed: isCurrentMonth ? null : () => _shiftMonth(1),
                            ),
                          ],
                        )
                            : Text(_periodLabel, style: AppTheme.bodyMedium, textAlign: TextAlign.center),
                      ),
                      if (_hasActiveFilters)
                        GestureDetector(
                          onTap: _clearFilters,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Icon(Icons.close, size: 18, color: AppTheme.textTertiary),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Income $base ${income.toStringAsFixed(2)}',
                          style: AppTheme.bodySmall.copyWith(color: AppTheme.successColor),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Expense $base ${expense.toStringAsFixed(2)}',
                          style: AppTheme.bodySmall.copyWith(color: AppTheme.primaryCoral),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ] else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('${transactions.length} result(s) across all time', style: AppTheme.bodySmall),
                  ),
                ),

              Expanded(
                child: transactions.isEmpty
                    ? Center(
                  child: Text(
                    _isSearching ? 'No matching transactions' : 'No transactions match these filters',
                    style: AppTheme.bodyMedium,
                  ),
                )
                    : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: transactions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final t = transactions[i];
                    return SwipeableTransactionCard(
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
