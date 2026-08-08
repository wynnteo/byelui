import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/scope_toggle.dart';
import '../widgets/transaction_card.dart';
import '../widgets/swipeable_transaction_card.dart';
import 'transaction_form_screen.dart';

class AllTransactionsScreen extends StatefulWidget {
  const AllTransactionsScreen({super.key});

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  final _dataService = DataService();
  final _searchController = TextEditingController();
  TransactionScope? _scopeFilter;
  String? _categoryFilter;
  String _search = '';
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  bool get _isSearching => _search.trim().isNotEmpty;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  void _shiftMonth(int delta) {
    setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + delta));
  }

  @override
  Widget build(BuildContext context) {
    final categories = _dataService.getCategories();
    final now = DateTime.now();
    final isCurrentMonth = _selectedMonth.year == now.year && _selectedMonth.month == now.month;

    final from = _isSearching ? null : DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final to = _isSearching ? null : DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0, 23, 59, 59);

    final transactions = _dataService.getTransactions(
      scope: _scopeFilter,
      categoryId: _categoryFilter,
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ScopeToggle(value: _scopeFilter, onChanged: (v) => setState(() => _scopeFilter = v)),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _categoryChip(null, 'All categories'),
                    const SizedBox(width: 8),
                    ...categories.map((c) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _categoryChip(c.id, c.name),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 10),

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
                          _isSearching ? 'No matching transactions' : 'No transactions this month',
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

  Widget _categoryChip(String? categoryId, String label) {
    final selected = _categoryFilter == categoryId;
    return GestureDetector(
      onTap: () => setState(() => _categoryFilter = categoryId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryCoral : AppTheme.glassBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? AppTheme.primaryCoral : AppTheme.glassBorder),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTheme.bodySmall.copyWith(color: selected ? Colors.white : AppTheme.textSecondary),
        ),
      ),
    );
  }
}
