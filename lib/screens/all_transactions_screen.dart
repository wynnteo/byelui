import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../models/payment_card.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/scope_toggle.dart';
import '../widgets/swipeable_transaction_card.dart';
import 'transaction_form_screen.dart';

class AllTransactionsScreen extends StatefulWidget {
  /// Pre-selected tags, e.g. when arriving from Tag Insights with a tag
  /// already tapped. The user can still add/remove from this starting set.
  final Set<String> initialTagFilters;

  const AllTransactionsScreen({super.key, this.initialTagFilters = const {}});

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  final _dataService = DataService();
  final _searchController = TextEditingController();
  TransactionScope? _scopeFilter;
  TransactionType? _typeFilter;
  final Set<String> _categoryFilters = {};
  late Set<String> _tagFilters;
  final Set<String> _cardFilters = {};
  final Set<PaymentMethod> _methodFilters = {};
  String _search = '';
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  bool get _isSearching => _search.trim().isNotEmpty;
  bool get _hasActiveFilters =>
      _categoryFilters.isNotEmpty ||
      _tagFilters.isNotEmpty ||
      _scopeFilter != null ||
      _typeFilter != null ||
      _cardFilters.isNotEmpty ||
      _methodFilters.isNotEmpty;
  int get _activeFilterCount =>
      _categoryFilters.length +
      _tagFilters.length +
      _cardFilters.length +
      _methodFilters.length +
      (_scopeFilter != null ? 1 : 0) +
      (_typeFilter != null ? 1 : 0);

  @override
  void initState() {
    super.initState();
    _tagFilters = {...widget.initialTagFilters};
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});


  void _shiftMonth(int delta) {
    setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + delta));
  }

  void _clearFilters() {
    setState(() {
      _categoryFilters.clear();
      _tagFilters.clear();
      _cardFilters.clear();
      _methodFilters.clear();
      _scopeFilter = null;
      _typeFilter = null;
    });
  }

  Future<void> _openFilterSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.primaryCharcoal,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final categories = _dataService.getCategories();
        final allTags = _dataService.getAllTags();
        final cards = _dataService.getPaymentCards(activeOnly: true);
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.4,
              maxChildSize: 0.92,
              expand: false,
              builder: (ctx, scrollController) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Filters', style: AppTheme.headingMedium),
                          TextButton(
                            onPressed: () => setSheetState(_clearFilters),
                            child: Text('Clear all', style: AppTheme.bodySmall.copyWith(color: AppTheme.stampText)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          children: [
                            Text('Scope', style: AppTheme.caption),
                            const SizedBox(height: 8),
                            ScopeToggle(
                              value: _scopeFilter,
                              onChanged: (v) => setSheetState(() => _scopeFilter = v),
                            ),
                            const SizedBox(height: 20),

                            Text('Type', style: AppTheme.caption),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _TypeOption(label: 'All', selected: _typeFilter == null, onTap: () => setSheetState(() => _typeFilter = null)),
                                const SizedBox(width: 8),
                                _TypeOption(
                                  label: 'Income',
                                  selected: _typeFilter == TransactionType.income,
                                  color: AppTheme.successColor,
                                  onTap: () => setSheetState(() => _typeFilter = TransactionType.income),
                                ),
                                const SizedBox(width: 8),
                                _TypeOption(
                                  label: 'Expense',
                                  selected: _typeFilter == TransactionType.expense,
                                  color: AppTheme.warn,
                                  onTap: () => setSheetState(() => _typeFilter = TransactionType.expense),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            Row(
                              children: [
                                Text('Paid with', style: AppTheme.caption),
                                if (_cardFilters.isNotEmpty || _methodFilters.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    '(${_cardFilters.length + _methodFilters.length})',
                                    style: AppTheme.caption.copyWith(color: AppTheme.stampText),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ...cards.map((c) => _toggleChip(
                                      label: c.name,
                                      selected: _cardFilters.contains(c.id),
                                      onTap: () => setSheetState(() {
                                        if (!_cardFilters.remove(c.id)) _cardFilters.add(c.id);
                                      }),
                                    )),
                                ...[PaymentMethod.cash, PaymentMethod.eWallet, PaymentMethod.bankTransfer, PaymentMethod.other]
                                    .map((m) => _toggleChip(
                                          label: _dataService.paymentMethodLabel(m),
                                          selected: _methodFilters.contains(m),
                                          onTap: () => setSheetState(() {
                                            if (!_methodFilters.remove(m)) _methodFilters.add(m);
                                          }),
                                        )),
                              ],
                            ),
                            const SizedBox(height: 20),

                            Row(
                              children: [
                                Text('Categories', style: AppTheme.caption),
                                if (_categoryFilters.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  Text('(${_categoryFilters.length})', style: AppTheme.caption.copyWith(color: AppTheme.stampText)),
                                ],
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: categories
                                  .map((c) => _toggleChip(
                                        label: c.name,
                                        selected: _categoryFilters.contains(c.id),
                                        onTap: () => setSheetState(() {
                                          if (!_categoryFilters.remove(c.id)) _categoryFilters.add(c.id);
                                        }),
                                      ))
                                  .toList(),
                            ),

                            if (allTags.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Text('Tags', style: AppTheme.caption),
                                  if (_tagFilters.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    Text('(${_tagFilters.length})', style: AppTheme.caption.copyWith(color: AppTheme.stampText)),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: allTags
                                    .map((tg) => _toggleChip(
                                          label: '#$tg',
                                          selected: _tagFilters.contains(tg),
                                          onTap: () => setSheetState(() {
                                            if (!_tagFilters.remove(tg)) _tagFilters.add(tg);
                                          }),
                                        ))
                                    .toList(),
                              ),
                            ],
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: AppTheme.primaryButtonStyle,
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Show results'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
    // Sheet mutated our fields directly (same State instance); refresh the list.
    _refresh();
  }

  Widget _toggleChip({required String label, required bool selected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryCoral : AppTheme.glassBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? AppTheme.primaryCoral : AppTheme.glassBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check, size: 13, color: AppTheme.ink),
              const SizedBox(width: 4),
            ],
            Text(label, style: AppTheme.bodySmall.copyWith(color: selected ? AppTheme.ink : AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  /// Small removable chips summarizing the currently active filters, shown
  /// below the search bar so the user can see (and undo) filters at a
  /// glance without reopening the sheet.
  Widget _activeFilterSummary() {
    final categories = _dataService.getCategories();
    final chips = <Widget>[];

    if (_scopeFilter != null) {
      chips.add(_removableChip(
        _scopeFilter == TransactionScope.personal ? 'Personal' : 'Family',
        () => setState(() => _scopeFilter = null),
      ));
    }
    if (_typeFilter != null) {
      chips.add(_removableChip(
        _typeFilter == TransactionType.income ? 'Income' : 'Expense',
        () => setState(() => _typeFilter = null),
      ));
    }
    for (final id in _categoryFilters) {
      final matches = categories.where((c) => c.id == id);
      final name = matches.isNotEmpty ? matches.first.name : 'Category';
      chips.add(_removableChip(name, () => setState(() => _categoryFilters.remove(id))));
    }
    for (final tg in _tagFilters) {
      chips.add(_removableChip('#$tg', () => setState(() => _tagFilters.remove(tg))));
    }
    for (final id in _cardFilters) {
      final cards = _dataService.getPaymentCards();
      final matches = cards.where((c) => c.id == id);
      final name = matches.isNotEmpty ? matches.first.name : 'Card';
      chips.add(_removableChip(name, () => setState(() => _cardFilters.remove(id))));
    }
    for (final m in _methodFilters) {
      chips.add(_removableChip(_dataService.paymentMethodLabel(m), () => setState(() => _methodFilters.remove(m))));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (ctx, i) => chips[i],
      ),
    );
  }

  Widget _removableChip(String label, VoidCallback onRemove) {
    return GestureDetector(
      onTap: onRemove,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.primaryCoral.withOpacity(0.25),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: AppTheme.bodySmall.copyWith(color: AppTheme.stampText)),
            const SizedBox(width: 4),
            const Icon(Icons.close, size: 13, color: AppTheme.stampText),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCurrentMonth = _selectedMonth.year == now.year && _selectedMonth.month == now.month;

    final from = _isSearching ? null : DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final to = _isSearching ? null : DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0, 23, 59, 59);

    final transactions = _dataService.getTransactions(
      scope: _scopeFilter,
      type: _typeFilter,
      categoryIds: _categoryFilters,
      tags: _tagFilters,
      paymentCardIds: _cardFilters,
      paymentMethods: _methodFilters,
      searchQuery: _search,
      from: from,
      to: to,
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
                    Expanded(child: Text('All transactions', style: AppTheme.headingMedium)),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.tune, color: AppTheme.textPrimary),
                          onPressed: _openFilterSheet,
                        ),
                        if (_hasActiveFilters)
                          Positioned(
                            right: 6,
                            top: 6,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(color: AppTheme.primaryCoral, shape: BoxShape.circle),
                              alignment: Alignment.center,
                              child: Text(
                                '$_activeFilterCount',
                                style: AppTheme.caption.copyWith(color: AppTheme.ink, fontSize: 9, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                      ],
                    ),
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
                    hintText: 'Search all time: description, note, tag...',
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
              _activeFilterSummary(),
              if (_hasActiveFilters) const SizedBox(height: 10),

              // Month pager - hidden while actively searching, since search spans all time.
              if (!_isSearching) ...[
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
                          style: AppTheme.bodySmall.copyWith(color: AppTheme.warn),
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
                          _isSearching || _hasActiveFilters ? 'No matching transactions' : 'No transactions this month',
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

class _TypeOption extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _TypeOption({required this.label, required this.selected, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final tint = color ?? AppTheme.primaryCoral;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? tint.withOpacity(0.25) : AppTheme.glassBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? tint : AppTheme.glassBorder),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTheme.bodyMedium.copyWith(
              color: selected ? AppTheme.ink : AppTheme.textSecondary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
