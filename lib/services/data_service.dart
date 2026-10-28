import 'package:hive/hive.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/recurring_transaction.dart';
import '../models/budget.dart';
import '../models/payment_card.dart';
import '../theme/app_theme.dart';
import '../i18n/s.dart';

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  static const Map<String, double> _staticExchangeRates = {
    'SGD': 1.0,
    'MYR': 3.19,
    'USD': 0.77,
    'CNY': 5.23,
    'EUR': 0.67,
    'HKD': 6.04,
  };

  Box<Transaction>? _transactionsBox;
  Box<Category>? _categoriesBox;
  Box<RecurringTransaction>? _recurringBox;
  Box<Budget>? _budgetsBox;
  Box<PaymentCard>? _paymentCardsBox;
  Box? _settingsBox;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _transactionsBox = Hive.isBoxOpen('transactions')
        ? Hive.box<Transaction>('transactions')
        : await Hive.openBox<Transaction>('transactions');

    _categoriesBox = Hive.isBoxOpen('categories')
        ? Hive.box<Category>('categories')
        : await Hive.openBox<Category>('categories');

    _recurringBox = Hive.isBoxOpen('recurring_transactions')
        ? Hive.box<RecurringTransaction>('recurring_transactions')
        : await Hive.openBox<RecurringTransaction>('recurring_transactions');

    _budgetsBox = Hive.isBoxOpen('budgets')
        ? Hive.box<Budget>('budgets')
        : await Hive.openBox<Budget>('budgets');

    _paymentCardsBox = Hive.isBoxOpen('payment_cards')
        ? Hive.box<PaymentCard>('payment_cards')
        : await Hive.openBox<PaymentCard>('payment_cards');

    _settingsBox = Hive.isBoxOpen('settings')
        ? Hive.box('settings')
        : await Hive.openBox('settings');

    _isInitialized = true;
    await _initializeDefaultCategories();
    await generateDueRecurringTransactions();
  }

  Box<Transaction> get _transactionsBoxSafe {
    if (_transactionsBox == null || !_transactionsBox!.isOpen) {
      throw Exception('Transactions box not initialized. Call DataService().initialize() first.');
    }
    return _transactionsBox!;
  }

  Box<Category> get _categoriesBoxSafe {
    if (_categoriesBox == null || !_categoriesBox!.isOpen) {
      throw Exception('Categories box not initialized. Call DataService().initialize() first.');
    }
    return _categoriesBox!;
  }

  Box get _settingsBoxSafe {
    if (_settingsBox == null || !_settingsBox!.isOpen) {
      throw Exception('Settings box not initialized. Call DataService().initialize() first.');
    }
    return _settingsBox!;
  }

  Box<RecurringTransaction> get _recurringBoxSafe {
    if (_recurringBox == null || !_recurringBox!.isOpen) {
      throw Exception('Recurring box not initialized. Call DataService().initialize() first.');
    }
    return _recurringBox!;
  }

  Box<Budget> get _budgetsBoxSafe {
    if (_budgetsBox == null || !_budgetsBox!.isOpen) {
      throw Exception('Budgets box not initialized. Call DataService().initialize() first.');
    }
    return _budgetsBox!;
  }

  Box<PaymentCard> get _paymentCardsBoxSafe {
    if (_paymentCardsBox == null || !_paymentCardsBox!.isOpen) {
      throw Exception('Payment cards box not initialized. Call DataService().initialize() first.');
    }
    return _paymentCardsBox!;
  }

  bool get isInitialized => _isInitialized;

  // ---- Settings ----

  String get baseCurrency => _settingsBoxSafe.get('baseCurrency', defaultValue: 'SGD');
  set baseCurrency(String value) => _settingsBoxSafe.put('baseCurrency', value);

  /// 'system' | 'light' | 'dark'. A per-device display preference, so it is
  /// intentionally not included in exportAllData()/importAllData().
  String? getThemeMode() => _settingsBoxSafe.get('themeMode');
  void setThemeMode(String mode) => _settingsBoxSafe.put('themeMode', mode);

  String? getSelectedLanguage() => _settingsBoxSafe.get('language');
  void setSelectedLanguage(String code) => _settingsBoxSafe.put('language', code);

  /// Ad-free flag — flip when a premium purchase is later wired up.
  bool get isPremium => _settingsBoxSafe.get('isPremium', defaultValue: false);
  set isPremium(bool value) => _settingsBoxSafe.put('isPremium', value);

  // ---- Categories ----

  Future<void> _initializeDefaultCategories() async {
    if (_categoriesBoxSafe.isNotEmpty) return;
    for (final c in Category.defaultExpenseCategories()) {
      await _categoriesBoxSafe.put(c.id, c);
    }
    for (final c in Category.defaultIncomeCategories()) {
      await _categoriesBoxSafe.put(c.id, c);
    }
  }

  List<Category> getCategories({TransactionType? type}) {
    final all = _categoriesBoxSafe.values.toList();
    if (type == null) return all;
    return all.where((c) => c.type == type).toList();
  }

  Category? getCategoryById(String id) => _categoriesBoxSafe.get(id);

  Future<Category> addCategory(Category category) async {
    await _categoriesBoxSafe.put(category.id, category);
    return category;
  }

  Future<void> updateCategory(Category category) async {
    await _categoriesBoxSafe.put(category.id, category);
  }

  Future<void> deleteCategory(String id) async {
    final category = _categoriesBoxSafe.get(id);
    if (category != null && category.isDefault) {
      throw Exception('Cannot delete a default category');
    }
    await _categoriesBoxSafe.delete(id);
  }

  // ---- Transactions ----

  List<Transaction> getTransactions({
    TransactionScope? scope,
    TransactionType? type,
    DateTime? from,
    DateTime? to,
    String? categoryId,
    Iterable<String>? categoryIds,
    String? currency,
    String? searchQuery,
    String? tag,
    Iterable<String>? tags,
    Iterable<String>? paymentCardIds,
    Iterable<PaymentMethod>? paymentMethods,
  }) {
    var items = _transactionsBoxSafe.values.toList();
    if (scope != null) items = items.where((t) => t.scope == scope).toList();
    if (type != null) items = items.where((t) => t.type == type).toList();
    if (from != null) items = items.where((t) => !t.date.isBefore(from)).toList();
    if (to != null) items = items.where((t) => !t.date.isAfter(to)).toList();
    if (categoryId != null) items = items.where((t) => t.categoryId == categoryId).toList();
    if (categoryIds != null && categoryIds.isNotEmpty) {
      final idSet = categoryIds.toSet();
      items = items.where((t) => idSet.contains(t.categoryId)).toList();
    }
    if (currency != null) items = items.where((t) => t.currency == currency).toList();
    if (tag != null) {
      final lower = tag.toLowerCase();
      items = items.where((t) => t.tags.any((x) => x.toLowerCase() == lower)).toList();
    }
    if (tags != null && tags.isNotEmpty) {
      final tagSet = tags.map((t) => t.toLowerCase()).toSet();
      items = items.where((t) => t.tags.any((x) => tagSet.contains(x.toLowerCase()))).toList();
    }
    final cardIdSet = paymentCardIds?.toSet() ?? const <String>{};
    final methodSet = paymentMethods?.toSet() ?? const <PaymentMethod>{};
    if (cardIdSet.isNotEmpty || methodSet.isNotEmpty) {
      items = items.where((t) {
        if (t.paymentCardId != null && cardIdSet.contains(t.paymentCardId)) return true;
        if (t.paymentMethod != null && methodSet.contains(t.paymentMethod)) return true;
        return false;
      }).toList();
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      items = items.where((t) {
        final category = getCategoryById(t.categoryId);
        return t.description.toLowerCase().contains(q) ||
            (t.note ?? '').toLowerCase().contains(q) ||
            t.tags.any((x) => x.toLowerCase().contains(q)) ||
            (category?.name.toLowerCase().contains(q) ?? false) ||
            (category?.displayName.toLowerCase().contains(q) ?? false) ||
            t.amount.toStringAsFixed(2).contains(q);
      }).toList();
    }
    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  Future<Transaction> addTransaction({
    required double amount,
    required String currency,
    required TransactionType type,
    required TransactionScope scope,
    required String categoryId,
    required DateTime date,
    required String description,
    String? note,
    String? photoPath,
    PaymentMethod? paymentMethod,
    List<String>? tags,
    String? paymentCardId,
  }) async {
    final now = DateTime.now();
    final txn = Transaction(
      id: const Uuid().v4(),
      amount: amount,
      currency: currency,
      type: type,
      scope: scope,
      categoryId: categoryId,
      date: date,
      description: description,
      note: note,
      photoPath: photoPath,
      paymentMethod: paymentMethod,
      createdAt: now,
      updatedAt: now,
      tags: tags ?? suggestTags(description),
      paymentCardId: paymentCardId,
    );
    await _transactionsBoxSafe.put(txn.id, txn);
    return txn;
  }

  Future<void> updateTransaction(Transaction transaction) async {
    await _transactionsBoxSafe.put(transaction.id, transaction.copyWith(updatedAt: DateTime.now()));
  }

  Future<void> deleteTransaction(String id) async {
    await _transactionsBoxSafe.delete(id);
  }

  // ---- Currency conversion ----

  double convertToBase(double amount, String currency) {
    final rates = _staticExchangeRates;
    final fromRate = rates[currency] ?? 1.0;
    final toRate = rates[baseCurrency] ?? 1.0;
    // rates are relative to SGD=1.0, so amount in SGD = amount / fromRate
    final amountInSgd = amount / fromRate;
    return amountInSgd * toRate;
  }

  // ---- Analytics helpers ----

  // Aggregates below make ONE pass over the box with no intermediate lists
  // and no sorting (getTransactions() copies + filters + sorts, which is what
  // the lists need but the totals don't). Trend/breakdown helpers that used to
  // call monthlyTotals() 6–12 times now scan once and bucket by month.

  /// Unsorted single-pass range scan used by the aggregate helpers.
  Iterable<Transaction> _scan({TransactionScope? scope, DateTime? from, DateTime? to}) {
    return _transactionsBoxSafe.values.where((t) {
      if (scope != null && t.scope != scope) return false;
      if (from != null && t.date.isBefore(from)) return false;
      if (to != null && t.date.isAfter(to)) return false;
      return true;
    });
  }

  /// Same maths as [convertToBase], but reads the base currency once instead
  /// of once per transaction (it's a Hive lookup).
  double Function(double amount, String currency) _baseConverter() {
    final toRate = _staticExchangeRates[baseCurrency] ?? 1.0;
    return (amount, currency) => amount / (_staticExchangeRates[currency] ?? 1.0) * toRate;
  }

  Map<String, double> _incomeExpenseTotals(DateTime from, DateTime to, TransactionScope? scope) {
    final convert = _baseConverter();
    double income = 0;
    double expense = 0;
    for (final t in _scan(scope: scope, from: from, to: to)) {
      final converted = convert(t.amount, t.currency);
      if (t.isIncome) {
        income += converted;
      } else {
        expense += converted;
      }
    }
    return {'income': income, 'expense': expense};
  }

  Map<String, double> _categoryTotals(DateTime from, DateTime to, TransactionScope? scope, TransactionType type) {
    final convert = _baseConverter();
    final breakdown = <String, double>{};
    for (final t in _scan(scope: scope, from: from, to: to)) {
      if (t.type != type) continue;
      breakdown[t.categoryId] = (breakdown[t.categoryId] ?? 0) + convert(t.amount, t.currency);
    }
    return breakdown;
  }

  /// income/expense per calendar month in [from]..[to], in ONE pass.
  /// Key = year * 12 + (month - 1); value = [income, expense].
  Map<int, List<double>> _incomeExpenseByMonth(DateTime from, DateTime to, TransactionScope? scope) {
    final convert = _baseConverter();
    final buckets = <int, List<double>>{};
    for (final t in _scan(scope: scope, from: from, to: to)) {
      final bucket = buckets.putIfAbsent(t.date.year * 12 + (t.date.month - 1), () => [0.0, 0.0]);
      final converted = convert(t.amount, t.currency);
      if (t.isIncome) {
        bucket[0] += converted;
      } else {
        bucket[1] += converted;
      }
    }
    return buckets;
  }

  /// Total income/expense for a given month, converted to base currency.
  Map<String, double> monthlyTotals(int year, int month, {TransactionScope? scope}) {
    return _incomeExpenseTotals(DateTime(year, month, 1), DateTime(year, month + 1, 0, 23, 59, 59), scope);
  }

  /// Last [months] months of income/expense totals, oldest first.
  List<Map<String, dynamic>> monthlyTrend(int months, {TransactionScope? scope}) {
    final now = DateTime.now();
    final buckets = _incomeExpenseByMonth(
      DateTime(now.year, now.month - (months - 1), 1),
      DateTime(now.year, now.month + 1, 0, 23, 59, 59),
      scope,
    );
    final result = <Map<String, dynamic>>[];
    for (int i = months - 1; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final b = buckets[date.year * 12 + (date.month - 1)];
      result.add({
        'year': date.year,
        'month': date.month,
        'income': b?[0] ?? 0.0,
        'expense': b?[1] ?? 0.0,
      });
    }
    return result;
  }

  /// Expense breakdown by category for a given month, converted to base currency.
  Map<String, double> categoryBreakdown(int year, int month, {TransactionScope? scope, TransactionType type = TransactionType.expense}) {
    return _categoryTotals(DateTime(year, month, 1), DateTime(year, month + 1, 0, 23, 59, 59), scope, type);
  }

  /// Expense breakdown by category for a whole year, converted to base currency.
  Map<String, double> yearlyCategoryBreakdown(int year, {TransactionScope? scope, TransactionType type = TransactionType.expense}) {
    return _categoryTotals(DateTime(year, 1, 1), DateTime(year, 12, 31, 23, 59, 59), scope, type);
  }

  /// Income/expense totals for a whole year, converted to base currency.
  Map<String, double> yearlyTotals(int year, {TransactionScope? scope}) {
    return _incomeExpenseTotals(DateTime(year, 1, 1), DateTime(year, 12, 31, 23, 59, 59), scope);
  }

  /// Per-month totals for a given year, Jan through Dec (one pass, not 12).
  List<Map<String, dynamic>> yearlyMonthlyBreakdown(int year, {TransactionScope? scope}) {
    final buckets = _incomeExpenseByMonth(DateTime(year, 1, 1), DateTime(year, 12, 31, 23, 59, 59), scope);
    return List.generate(12, (i) {
      final month = i + 1;
      final b = buckets[year * 12 + (month - 1)];
      return {'year': year, 'month': month, 'income': b?[0] ?? 0.0, 'expense': b?[1] ?? 0.0};
    });
  }

  // ---- Recurring transactions ----

  List<RecurringTransaction> getRecurringTransactions({bool activeOnly = false}) {
    var items = _recurringBoxSafe.values.toList();
    if (activeOnly) items = items.where((r) => r.isActive).toList();
    items.sort((a, b) => (a.nextDueDate ?? a.startDate).compareTo(b.nextDueDate ?? b.startDate));
    return items;
  }

  Future<RecurringTransaction> addRecurringTransaction({
    required double amount,
    required String currency,
    required TransactionType type,
    required TransactionScope scope,
    required String categoryId,
    required String description,
    String? note,
    required RecurrenceFrequency frequency,
    required DateTime startDate,
    DateTime? endDate,
    PaymentMethod? paymentMethod,
    List<String>? tags,
    String? paymentCardId,
  }) async {
    final recurring = RecurringTransaction(
      id: const Uuid().v4(),
      amount: amount,
      currency: currency,
      type: type,
      scope: scope,
      categoryId: categoryId,
      description: description,
      note: note,
      frequency: frequency,
      startDate: startDate,
      nextDueDate: startDate,
      endDate: endDate,
      paymentMethod: paymentMethod,
      tags: tags ?? [],
      paymentCardId: paymentCardId,
    );
    await _recurringBoxSafe.put(recurring.id, recurring);
    return recurring;
  }

  Future<void> updateRecurringTransaction(RecurringTransaction recurring) async {
    await _recurringBoxSafe.put(recurring.id, recurring);
  }

  Future<void> deleteRecurringTransaction(String id) async {
    await _recurringBoxSafe.delete(id);
  }

  /// Walks all active recurring rules and materializes any transactions
  /// that have come due since the last check (call on app start / resume).
  Future<int> generateDueRecurringTransactions() async {
    int created = 0;
    for (final recurring in _recurringBoxSafe.values.toList()) {
      while (recurring.isDue) {
        final dueDate = recurring.nextDueDate ?? recurring.startDate;
        // A stable ID makes each scheduled occurrence idempotent. If the app
        // closes after saving the transaction but before advancing the rule,
        // the next launch will recognize it instead of creating a duplicate.
        final occurrenceId = 'recurring:${recurring.id}:${dueDate.toIso8601String()}';
        if (!_transactionsBoxSafe.containsKey(occurrenceId)) {
          final now = DateTime.now();
          final transaction = Transaction(
            id: occurrenceId,
            amount: recurring.amount,
            currency: recurring.currency,
            type: recurring.type,
            scope: recurring.scope,
            categoryId: recurring.categoryId,
            date: dueDate,
            description: recurring.description,
            note: recurring.note,
            paymentMethod: recurring.paymentMethod,
            createdAt: now,
            updatedAt: now,
            tags: recurring.tags.isEmpty
                ? suggestTags(recurring.description)
                : List<String>.from(recurring.tags),
            paymentCardId: recurring.paymentCardId,
          );
          await _transactionsBoxSafe.put(occurrenceId, transaction);
          created++;
        }
        final next = recurring.computeNextDate(dueDate);
        recurring.nextDueDate = next;
        await recurring.save();
      }
    }
    return created;
  }

  // ---- Tags ----

  /// Default keyword → tag map, used to auto-suggest tags from a
  /// transaction's description (e.g. "Shopee order" -> "Shopee").
  /// Stored in settings so the user can add their own keywords later.
  static const Map<String, String> _defaultTagKeywords = {
    'shopee': 'Shopee',
    'lazada': 'Lazada',
    'grab': 'Grab',
    'foodpanda': 'Foodpanda',
    'kopi': 'Coffee/Tea',
    'teh': 'Coffee/Tea',
    'coffee': 'Coffee/Tea',
    'bubble tea': 'Bubble tea',
    'boba': 'Bubble tea',
    'milk tea': 'Bubble tea',
    'netflix': 'Subscriptions',
    'spotify': 'Subscriptions',
    'disney': 'Subscriptions',
    'grocery': 'Groceries',
    'ntuc': 'Groceries',
    'cold storage': 'Groceries',
  };

  Map<String, String> get _tagKeywords {
    final stored = _settingsBoxSafe.get('tagKeywords');
    if (stored is Map) {
      return stored.map((k, v) => MapEntry(k.toString(), v.toString()));
    }
    return _defaultTagKeywords;
  }

  void addTagKeyword(String keyword, String tag) {
    final current = Map<String, String>.from(_tagKeywords);
    current[keyword.toLowerCase()] = tag;
    _settingsBoxSafe.put('tagKeywords', current);
  }

  /// Suggests tags for a description by matching against known keywords.
  List<String> suggestTags(String description) {
    final lower = description.toLowerCase();
    final matches = <String>{};
    _tagKeywords.forEach((keyword, tag) {
      if (lower.contains(keyword)) matches.add(tag);
    });
    return matches.toList();
  }

  /// All distinct tags currently used across transactions, plus known keyword tags.
  List<String> getAllTags() {
    final tags = <String>{};
    for (final t in _transactionsBoxSafe.values) {
      tags.addAll(t.tags);
    }
    tags.addAll(_tagKeywords.values);
    final list = tags.toList()..sort();
    return list;
  }

  /// Total expense per tag for a date range, converted to base currency.
  Map<String, double> tagBreakdown({DateTime? from, DateTime? to, TransactionScope? scope}) {
    final items = getTransactions(scope: scope, from: from, to: to).where((t) => t.isExpense);
    final breakdown = <String, double>{};
    for (final t in items) {
      if (t.tags.isEmpty) continue;
      final converted = convertToBase(t.amount, t.currency);
      for (final tag in t.tags) {
        breakdown[tag] = (breakdown[tag] ?? 0) + converted;
      }
    }
    return breakdown;
  }

  // ---- Budgets ----

  List<Budget> getBudgets({TransactionScope? scope}) {
    var items = _budgetsBoxSafe.values.toList();
    if (scope != null) items = items.where((b) => b.scope == scope).toList();
    return items;
  }

  Budget? getBudgetForCategory(String categoryId, {TransactionScope scope = TransactionScope.personal}) {
    try {
      return _budgetsBoxSafe.values.firstWhere((b) => b.categoryId == categoryId && b.scope == scope);
    } catch (_) {
      return null;
    }
  }

  Future<Budget> setBudget({
    required String categoryId,
    required double monthlyLimit,
    TransactionScope scope = TransactionScope.personal,
  }) async {
    final existing = getBudgetForCategory(categoryId, scope: scope);
    final budget = (existing ?? Budget(id: const Uuid().v4(), categoryId: categoryId, monthlyLimit: monthlyLimit, scope: scope))
        .copyWith(monthlyLimit: monthlyLimit);
    await _budgetsBoxSafe.put(budget.id, budget);
    return budget;
  }

  Future<void> deleteBudget(String id) async {
    await _budgetsBoxSafe.delete(id);
  }

  /// Spent-vs-limit for every budget in [month] (defaults to the current
  /// month), converted to base currency. Each budget is compared against
  /// spend filtered by *that budget's own* scope (not the outer scope
  /// filter) — otherwise a Personal-only budget could be flagged as over
  /// limit by combined Personal+Family spending.
  List<Map<String, dynamic>> budgetProgress({TransactionScope? scope, DateTime? month}) {
    final target = month ?? DateTime.now();
    final budgets = getBudgets(scope: scope);
    final spendCache = <TransactionScope, Map<String, double>>{};

    return budgets.map((b) {
      final spendByCategory = spendCache.putIfAbsent(
        b.scope,
        () => categoryBreakdown(target.year, target.month, scope: b.scope),
      );
      final spent = spendByCategory[b.categoryId] ?? 0;
      return {
        'budget': b,
        'spent': spent,
        'remaining': b.monthlyLimit - spent,
        'percent': b.monthlyLimit <= 0 ? 0.0 : (spent / b.monthlyLimit).clamp(0, 999).toDouble(),
      };
    }).toList();
  }

  /// Aggregate across all budgets for [month] (defaults to current month):
  /// total budgeted, total spent against budgeted categories, spend outside
  /// any budgeted category, and how many are over/near limit.
  Map<String, dynamic> budgetSummary({TransactionScope? scope, double nearThreshold = 0.8, DateTime? month}) {
    final target = month ?? DateTime.now();
    final progress = budgetProgress(scope: scope, month: target);
    double totalBudget = 0;
    double totalSpent = 0;
    int overCount = 0;
    int nearCount = 0;
    for (final p in progress) {
      final budget = p['budget'] as Budget;
      final spent = p['spent'] as double;
      final pct = p['percent'] as double;
      totalBudget += budget.monthlyLimit;
      totalSpent += spent;
      if (pct >= 1.0) {
        overCount++;
      } else if (pct >= nearThreshold) {
        nearCount++;
      }
    }

    final allCategorySpend = categoryBreakdown(target.year, target.month, scope: scope);
    final totalSpentAll = allCategorySpend.values.fold<double>(0, (a, b) => a + b);
    final unbudgetedSpend = (totalSpentAll - totalSpent).clamp(0, double.infinity);

    return {
      'totalBudget': totalBudget,
      'totalSpent': totalSpent,
      'totalSpentAll': totalSpentAll,
      'unbudgetedSpend': unbudgetedSpend,
      'remaining': totalBudget - totalSpentAll,
      'percentAll': totalBudget <= 0 ? 0.0 : (totalSpentAll / totalBudget),
      'overCount': overCount,
      'nearCount': nearCount,
      'budgetCount': progress.length,
    };
  }

  /// Biggest expense category and the single highest-spending month for a
  /// given year — used for the Analytics "highlights" cards.
  Map<String, dynamic> yearHighlights(int year, {TransactionScope? scope}) {
    final catBreakdown = yearlyCategoryBreakdown(year, scope: scope);
    String? topCategoryId;
    double topCategoryAmount = 0;
    catBreakdown.forEach((catId, amount) {
      if (amount > topCategoryAmount) {
        topCategoryAmount = amount;
        topCategoryId = catId;
      }
    });

    int? topMonth;
    double topMonthAmount = 0;
    for (var m = 1; m <= 12; m++) {
      final totals = monthlyTotals(year, m, scope: scope);
      final expense = totals['expense'] ?? 0;
      if (expense > topMonthAmount) {
        topMonthAmount = expense;
        topMonth = m;
      }
    }

    return {
      'topCategoryId': topCategoryId,
      'topCategoryAmount': topCategoryAmount,
      'topMonth': topMonth,
      'topMonthAmount': topMonthAmount,
    };
  }

  /// Short, on-device "insights" comparing the given month against the
  /// previous one and calling out the single biggest expense — all rule
  /// based, no network calls. Returns up to 3 short sentences.
  List<String> monthlyInsights({DateTime? month, TransactionScope? scope}) {
    final target = month ?? DateTime.now();
    final prevMonth = DateTime(target.year, target.month - 1, 1);
    final base = baseCurrency;
    final insights = <String>[];

    final thisBreakdown = categoryBreakdown(target.year, target.month, scope: scope);
    final lastBreakdown = categoryBreakdown(prevMonth.year, prevMonth.month, scope: scope);

    // 1. Category with the biggest % jump vs last month (ignore tiny/no-baseline amounts).
    String? risingCategoryId;
    double risingPct = 0;
    double risingThisAmount = 0;
    double risingLastAmount = 0;
    thisBreakdown.forEach((catId, amount) {
      final last = lastBreakdown[catId] ?? 0;
      if (amount < 20 || last <= 0) return;
      final pct = (amount - last) / last;
      if (pct > risingPct) {
        risingPct = pct;
        risingCategoryId = catId;
        risingThisAmount = amount;
        risingLastAmount = last;
      }
    });
    if (risingCategoryId != null && risingPct >= 0.2) {
      final cat = getCategoryById(risingCategoryId!);
      insights.add(
        S.t.insightRising(cat?.displayName ?? S.t.thisCategory, (risingPct * 100).toStringAsFixed(0), base, risingLastAmount.toStringAsFixed(0), risingThisAmount.toStringAsFixed(0)),
      );
    }

    // 2. Overall spend vs last month.
    final thisTotal = thisBreakdown.values.fold<double>(0, (a, b) => a + b);
    final lastTotal = lastBreakdown.values.fold<double>(0, (a, b) => a + b);
    if (lastTotal > 0) {
      final pct = (thisTotal - lastTotal) / lastTotal;
      if (pct.abs() >= 0.1) {
        insights.add(
          S.t.insightOverall((pct.abs() * 100).toStringAsFixed(0), pct >= 0),
        );
      }
    }

    // 3. Biggest single expense this month.
    final from = DateTime(target.year, target.month, 1);
    final to = DateTime(target.year, target.month + 1, 0, 23, 59, 59);
    final items = getTransactions(scope: scope, from: from, to: to, type: TransactionType.expense).toList()
      ..sort((a, b) => convertToBase(b.amount, b.currency).compareTo(convertToBase(a.amount, a.currency)));
    if (items.isNotEmpty) {
      final biggest = items.first;
      final amount = convertToBase(biggest.amount, biggest.currency);
      if (amount >= 50) {
        final cat = getCategoryById(biggest.categoryId);
        insights.add(
          S.t.insightBiggest(base, amount.toStringAsFixed(0), biggest.description, cat?.displayName),
        );
      }
    }

    return insights;
  }

  // ---- Payment cards ----

  List<PaymentCard> getPaymentCards({bool activeOnly = false}) {
    var items = _paymentCardsBoxSafe.values.toList();
    if (activeOnly) items = items.where((c) => c.isActive).toList();
    items.sort((a, b) => a.name.compareTo(b.name));
    return items;
  }

  PaymentCard? getPaymentCardById(String id) => _paymentCardsBoxSafe.get(id);

  Future<PaymentCard> addPaymentCard({
    required String name,
    required String iconName,
    required int colorValue,
  }) async {
    final card = PaymentCard(
      id: const Uuid().v4(),
      name: name,
      iconName: iconName,
      colorValue: colorValue,
      createdAt: DateTime.now(),
    );
    await _paymentCardsBoxSafe.put(card.id, card);
    return card;
  }

  Future<void> updatePaymentCard(PaymentCard card) async {
    await _paymentCardsBoxSafe.put(card.id, card);
  }

  Future<void> deletePaymentCard(String id) async {
    await _paymentCardsBoxSafe.delete(id);
  }

  String paymentMethodLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return S.t.cash;
      case PaymentMethod.card:
        return S.t.cardUnspecified;
      case PaymentMethod.eWallet:
        return S.t.eWallet;
      case PaymentMethod.bankTransfer:
        return S.t.bankTransfer;
      case PaymentMethod.other:
        return S.t.other;
    }
  }

  /// Expense breakdown by "where did the money go from" — named payment
  /// cards (Trust Card, Mari Card, ...) plus generic Cash/E-wallet/Bank
  /// transfer/Other for transactions without a named card, for Analytics.
  /// Transactions with neither set are grouped under 'Not set'.
  List<Map<String, dynamic>> paymentSourceBreakdown({DateTime? from, DateTime? to, TransactionScope? scope}) {
    final items = getTransactions(scope: scope, from: from, to: to).where((t) => t.isExpense);

    final amounts = <String, double>{};
    final meta = <String, Map<String, dynamic>>{}; // label -> {color}

    for (final t in items) {
      final converted = convertToBase(t.amount, t.currency);
      String label;
      Color color;

      final card = t.paymentCardId != null ? getPaymentCardById(t.paymentCardId!) : null;
      if (card != null) {
        label = card.name;
        color = card.color;
      } else if (t.paymentMethod != null) {
        label = paymentMethodLabel(t.paymentMethod!);
        color = _paymentMethodColor(t.paymentMethod!);
      } else {
        label = S.t.notSet;
        color = AppTheme.otherColor;
      }

      amounts[label] = (amounts[label] ?? 0) + converted;
      meta[label] = {'color': color};
    }

    final result = amounts.entries
        .map((e) => {'label': e.key, 'amount': e.value, 'color': meta[e.key]!['color'] as Color})
        .toList();
    result.sort((a, b) => (b['amount'] as double).compareTo(a['amount'] as double));
    return result;
  }

  Color _paymentMethodColor(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return AppTheme.successColor;
      case PaymentMethod.card:
        return AppTheme.primaryCoral;
      case PaymentMethod.eWallet:
        return const Color(0xFF3B82F6);
      case PaymentMethod.bankTransfer:
        return const Color(0xFF8B5CF6);
      case PaymentMethod.other:
        return AppTheme.otherColor;
    }
  }

  // ---- Month-over-month / year-over-year comparison ----

  /// Compares one month's totals against the previous month (or same month last year).
  Map<String, dynamic> compareMonth(int year, int month, {TransactionScope? scope, bool vsLastYear = false}) {
    final current = monthlyTotals(year, month, scope: scope);
    final prevDate = vsLastYear ? DateTime(year - 1, month) : DateTime(year, month - 1);
    final previous = monthlyTotals(prevDate.year, prevDate.month, scope: scope);

    double pctChange(double curr, double prev) {
      if (prev == 0) return curr == 0 ? 0 : 100;
      return ((curr - prev) / prev) * 100;
    }

    return {
      'current': current,
      'previous': previous,
      'previousYear': prevDate.year,
      'previousMonth': prevDate.month,
      'incomeChangePct': pctChange(current['income'] ?? 0, previous['income'] ?? 0),
      'expenseChangePct': pctChange(current['expense'] ?? 0, previous['expense'] ?? 0),
    };
  }

  // ---- Full data backup / restore ----
  // Note: photo files themselves are NOT included, only their stored local
  // path — receipt photos won't carry over to a new device, only the
  // transaction data. Transactions will just show without a photo after
  // restoring elsewhere.

  Map<String, dynamic> exportAllData() {
    return {
      'exportVersion': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'transactions': _transactionsBoxSafe.values.map((t) => {
            'id': t.id,
            'amount': t.amount,
            'currency': t.currency,
            'type': t.type.toJson(),
            'scope': t.scope.toJson(),
            'categoryId': t.categoryId,
            'date': t.date.toIso8601String(),
            'description': t.description,
            'note': t.note,
            'photoPath': t.photoPath,
            'paymentMethod': t.paymentMethod?.toJson(),
            'createdAt': t.createdAt.toIso8601String(),
            'updatedAt': t.updatedAt.toIso8601String(),
            'tags': t.tags,
            'paymentCardId': t.paymentCardId,
          }).toList(),
      'categories': _categoriesBoxSafe.values.map((c) => {
            'id': c.id,
            'name': c.name,
            'iconName': c.iconName,
            'colorValue': c.colorValue,
            'type': c.type.toJson(),
            'isDefault': c.isDefault,
          }).toList(),
      'recurringTransactions': _recurringBoxSafe.values.map((r) => {
            'id': r.id,
            'amount': r.amount,
            'currency': r.currency,
            'type': r.type.toJson(),
            'scope': r.scope.toJson(),
            'categoryId': r.categoryId,
            'description': r.description,
            'note': r.note,
            'frequency': r.frequency.name,
            'startDate': r.startDate.toIso8601String(),
            'nextDueDate': r.nextDueDate?.toIso8601String(),
            'endDate': r.endDate?.toIso8601String(),
            'isActive': r.isActive,
            'paymentMethod': r.paymentMethod?.toJson(),
            'tags': r.tags,
            'paymentCardId': r.paymentCardId,
          }).toList(),
      'budgets': _budgetsBoxSafe.values.map((b) => {
            'id': b.id,
            'categoryId': b.categoryId,
            'monthlyLimit': b.monthlyLimit,
            'scope': b.scope.toJson(),
          }).toList(),
      'paymentCards': _paymentCardsBoxSafe.values.map((c) => {
            'id': c.id,
            'name': c.name,
            'iconName': c.iconName,
            'colorValue': c.colorValue,
            'isActive': c.isActive,
            'createdAt': c.createdAt.toIso8601String(),
          }).toList(),
      'settings': {
        'baseCurrency': baseCurrency,
        'tagKeywords': _tagKeywords,
      },
    };
  }

  /// Validates a backup map has the expected top-level shape before import.
  bool isValidBackup(Map<String, dynamic> data) {
    return data.containsKey('exportVersion') &&
        data['transactions'] is List &&
        data['categories'] is List;
  }

  /// Replaces ALL local data with the contents of a backup. Irreversible —
  /// callers should confirm with the user first.
  ///
  /// Two phases so a bad file can never leave the user with no data:
  ///  1. Parse + validate the WHOLE backup into memory. Any problem throws a
  ///     [FormatException] before a single box is touched.
  ///  2. Snapshot the current boxes, swap in the new data, and if the write
  ///     itself fails (disk full, etc.) restore the snapshot and rethrow.
  Future<void> importAllData(Map<String, dynamic> data) async {
    // ---- Phase 1: parse (no writes) ----
    final categories = <String, Category>{};
    final transactions = <String, Transaction>{};
    final paymentCards = <String, PaymentCard>{};
    final recurring = <String, RecurringTransaction>{};
    final budgets = <String, Budget>{};
    String? newBaseCurrency;
    Map<String, String>? newTagKeywords;

    try {
      for (final raw in (data['categories'] as List? ?? [])) {
        final c = Map<String, dynamic>.from(raw as Map);
        final category = Category(
          id: c['id'],
          name: c['name'],
          iconName: c['iconName'],
          colorValue: c['colorValue'],
          type: TransactionType.fromJson(c['type']),
          isDefault: c['isDefault'] ?? false,
        );
        categories[category.id] = category;
      }

      for (final raw in (data['transactions'] as List? ?? [])) {
        final t = Map<String, dynamic>.from(raw as Map);
        final txn = Transaction(
          id: t['id'],
          amount: (t['amount'] as num).toDouble(),
          currency: t['currency'],
          type: TransactionType.fromJson(t['type']),
          scope: TransactionScope.fromJson(t['scope']),
          categoryId: t['categoryId'],
          date: DateTime.parse(t['date']),
          description: t['description'],
          note: t['note'],
          photoPath: t['photoPath'],
          paymentMethod: t['paymentMethod'] != null ? PaymentMethod.fromJson(t['paymentMethod']) : null,
          createdAt: DateTime.parse(t['createdAt']),
          updatedAt: DateTime.parse(t['updatedAt']),
          tags: (t['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
          paymentCardId: t['paymentCardId'],
        );
        transactions[txn.id] = txn;
      }

      for (final raw in (data['paymentCards'] as List? ?? [])) {
        final c = Map<String, dynamic>.from(raw as Map);
        final card = PaymentCard(
          id: c['id'],
          name: c['name'],
          iconName: c['iconName'],
          colorValue: c['colorValue'],
          isActive: c['isActive'] ?? true,
          createdAt: DateTime.parse(c['createdAt']),
        );
        paymentCards[card.id] = card;
      }

      for (final raw in (data['recurringTransactions'] as List? ?? [])) {
        final r = Map<String, dynamic>.from(raw as Map);
        final rec = RecurringTransaction(
          id: r['id'],
          amount: (r['amount'] as num).toDouble(),
          currency: r['currency'],
          type: TransactionType.fromJson(r['type']),
          scope: TransactionScope.fromJson(r['scope']),
          categoryId: r['categoryId'],
          description: r['description'],
          note: r['note'],
          frequency: RecurrenceFrequency.values.firstWhere(
            (f) => f.name == r['frequency'],
            orElse: () => RecurrenceFrequency.monthly,
          ),
          startDate: DateTime.parse(r['startDate']),
          nextDueDate: r['nextDueDate'] != null ? DateTime.parse(r['nextDueDate']) : null,
          endDate: r['endDate'] != null ? DateTime.parse(r['endDate']) : null,
          isActive: r['isActive'] ?? true,
          paymentMethod: r['paymentMethod'] != null ? PaymentMethod.fromJson(r['paymentMethod']) : null,
          tags: (r['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
          paymentCardId: r['paymentCardId'],
        );
        recurring[rec.id] = rec;
      }

      for (final raw in (data['budgets'] as List? ?? [])) {
        final b = Map<String, dynamic>.from(raw as Map);
        final budget = Budget(
          id: b['id'],
          categoryId: b['categoryId'],
          monthlyLimit: (b['monthlyLimit'] as num).toDouble(),
          scope: TransactionScope.fromJson(b['scope'] ?? 'personal'),
        );
        budgets[budget.id] = budget;
      }

      final settings = Map<String, dynamic>.from(data['settings'] as Map? ?? {});
      if (settings['baseCurrency'] is String) newBaseCurrency = settings['baseCurrency'] as String;
      if (settings['tagKeywords'] is Map) {
        newTagKeywords = Map<String, String>.from(
          (settings['tagKeywords'] as Map).map((k, v) => MapEntry(k.toString(), v.toString())),
        );
      }
    } catch (e) {
      throw FormatException(S.t.backupDamaged(e));
    }

    // ---- Phase 2: snapshot, swap, roll back on failure ----
    final oldTransactions = _transactionsBoxSafe.toMap();
    final oldCategories = _categoriesBoxSafe.toMap();
    final oldRecurring = _recurringBoxSafe.toMap();
    final oldBudgets = _budgetsBoxSafe.toMap();
    final oldCards = _paymentCardsBoxSafe.toMap();
    final oldBaseCurrency = baseCurrency;
    final oldTagKeywords = _settingsBoxSafe.get('tagKeywords');

    try {
      await _transactionsBoxSafe.clear();
      await _categoriesBoxSafe.clear();
      await _recurringBoxSafe.clear();
      await _budgetsBoxSafe.clear();
      await _paymentCardsBoxSafe.clear();

      await _categoriesBoxSafe.putAll(categories);
      await _transactionsBoxSafe.putAll(transactions);
      await _paymentCardsBoxSafe.putAll(paymentCards);
      await _recurringBoxSafe.putAll(recurring);
      await _budgetsBoxSafe.putAll(budgets);

      if (newBaseCurrency != null) baseCurrency = newBaseCurrency;
      if (newTagKeywords != null) await _settingsBoxSafe.put('tagKeywords', newTagKeywords);
    } catch (_) {
      await _transactionsBoxSafe.clear();
      await _categoriesBoxSafe.clear();
      await _recurringBoxSafe.clear();
      await _budgetsBoxSafe.clear();
      await _paymentCardsBoxSafe.clear();
      await _transactionsBoxSafe.putAll(oldTransactions);
      await _categoriesBoxSafe.putAll(oldCategories);
      await _recurringBoxSafe.putAll(oldRecurring);
      await _budgetsBoxSafe.putAll(oldBudgets);
      await _paymentCardsBoxSafe.putAll(oldCards);
      baseCurrency = oldBaseCurrency;
      if (oldTagKeywords != null) await _settingsBoxSafe.put('tagKeywords', oldTagKeywords);
      rethrow;
    }
  }
}
