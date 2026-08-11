import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/recurring_transaction.dart';
import '../models/budget.dart';

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

  bool get isInitialized => _isInitialized;

  // ---- Settings ----

  String get baseCurrency => _settingsBoxSafe.get('baseCurrency', defaultValue: 'SGD');
  set baseCurrency(String value) => _settingsBoxSafe.put('baseCurrency', value);

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
    DateTime? from,
    DateTime? to,
    String? categoryId,
    String? currency,
    String? searchQuery,
    String? tag,
  }) {
    var items = _transactionsBoxSafe.values.toList();
    if (scope != null) items = items.where((t) => t.scope == scope).toList();
    if (from != null) items = items.where((t) => !t.date.isBefore(from)).toList();
    if (to != null) items = items.where((t) => !t.date.isAfter(to)).toList();
    if (categoryId != null) items = items.where((t) => t.categoryId == categoryId).toList();
    if (currency != null) items = items.where((t) => t.currency == currency).toList();
    if (tag != null) {
      final lower = tag.toLowerCase();
      items = items.where((t) => t.tags.any((x) => x.toLowerCase() == lower)).toList();
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      items = items.where((t) {
        final category = getCategoryById(t.categoryId);
        return t.description.toLowerCase().contains(q) ||
            (t.note ?? '').toLowerCase().contains(q) ||
            t.tags.any((x) => x.toLowerCase().contains(q)) ||
            (category?.name.toLowerCase().contains(q) ?? false) ||
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

  /// Total income/expense for a given month, converted to base currency.
  Map<String, double> monthlyTotals(int year, int month, {TransactionScope? scope}) {
    final from = DateTime(year, month, 1);
    final to = DateTime(year, month + 1, 0, 23, 59, 59);
    final items = getTransactions(scope: scope, from: from, to: to);

    double income = 0;
    double expense = 0;
    for (final t in items) {
      final converted = convertToBase(t.amount, t.currency);
      if (t.isIncome) {
        income += converted;
      } else {
        expense += converted;
      }
    }
    return {'income': income, 'expense': expense};
  }

  /// Last [months] months of income/expense totals, oldest first.
  List<Map<String, dynamic>> monthlyTrend(int months, {TransactionScope? scope}) {
    final now = DateTime.now();
    final result = <Map<String, dynamic>>[];
    for (int i = months - 1; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final totals = monthlyTotals(date.year, date.month, scope: scope);
      result.add({
        'year': date.year,
        'month': date.month,
        'income': totals['income'],
        'expense': totals['expense'],
      });
    }
    return result;
  }

  /// Expense breakdown by category for a given month, converted to base currency.
  Map<String, double> categoryBreakdown(int year, int month, {TransactionScope? scope}) {
    final from = DateTime(year, month, 1);
    final to = DateTime(year, month + 1, 0, 23, 59, 59);
    final items = getTransactions(scope: scope, from: from, to: to)
        .where((t) => t.isExpense);

    final breakdown = <String, double>{};
    for (final t in items) {
      final converted = convertToBase(t.amount, t.currency);
      breakdown[t.categoryId] = (breakdown[t.categoryId] ?? 0) + converted;
    }
    return breakdown;
  }

  /// Expense breakdown by category for a whole year, converted to base currency.
  Map<String, double> yearlyCategoryBreakdown(int year, {TransactionScope? scope}) {
    final from = DateTime(year, 1, 1);
    final to = DateTime(year, 12, 31, 23, 59, 59);
    final items = getTransactions(scope: scope, from: from, to: to).where((t) => t.isExpense);

    final breakdown = <String, double>{};
    for (final t in items) {
      final converted = convertToBase(t.amount, t.currency);
      breakdown[t.categoryId] = (breakdown[t.categoryId] ?? 0) + converted;
    }
    return breakdown;
  }

  /// Income/expense totals for a whole year, converted to base currency.
  Map<String, double> yearlyTotals(int year, {TransactionScope? scope}) {
    final from = DateTime(year, 1, 1);
    final to = DateTime(year, 12, 31, 23, 59, 59);
    final items = getTransactions(scope: scope, from: from, to: to);

    double income = 0;
    double expense = 0;
    for (final t in items) {
      final converted = convertToBase(t.amount, t.currency);
      if (t.isIncome) {
        income += converted;
      } else {
        expense += converted;
      }
    }
    return {'income': income, 'expense': expense};
  }

  /// Per-month totals for a given year, Jan through Dec.
  List<Map<String, dynamic>> yearlyMonthlyBreakdown(int year, {TransactionScope? scope}) {
    return List.generate(12, (i) {
      final month = i + 1;
      final totals = monthlyTotals(year, month, scope: scope);
      return {'year': year, 'month': month, 'income': totals['income'], 'expense': totals['expense']};
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
        await addTransaction(
          amount: recurring.amount,
          currency: recurring.currency,
          type: recurring.type,
          scope: recurring.scope,
          categoryId: recurring.categoryId,
          date: dueDate,
          description: recurring.description,
          note: recurring.note,
          paymentMethod: recurring.paymentMethod,
        );
        created++;
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

  /// Spent-vs-limit for every budget in the current month, converted to base currency.
  /// Each budget is compared against spend filtered by *that budget's own*
  /// scope (not the outer scope filter) — otherwise a Personal-only budget
  /// could be flagged as over limit by combined Personal+Family spending.
  List<Map<String, dynamic>> budgetProgress({TransactionScope? scope}) {
    final now = DateTime.now();
    final budgets = getBudgets(scope: scope);
    final spendCache = <TransactionScope, Map<String, double>>{};

    return budgets.map((b) {
      final spendByCategory = spendCache.putIfAbsent(
        b.scope,
        () => categoryBreakdown(now.year, now.month, scope: b.scope),
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

  /// Aggregate across all budgets for the current month: total budgeted,
  /// total spent against budgeted categories, and how many are over/near limit.
  Map<String, dynamic> budgetSummary({TransactionScope? scope, double nearThreshold = 0.8}) {
    final progress = budgetProgress(scope: scope);
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
    return {
      'totalBudget': totalBudget,
      'totalSpent': totalSpent,
      'remaining': totalBudget - totalSpent,
      'overCount': overCount,
      'nearCount': nearCount,
      'budgetCount': progress.length,
    };
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
          }).toList(),
      'budgets': _budgetsBoxSafe.values.map((b) => {
            'id': b.id,
            'categoryId': b.categoryId,
            'monthlyLimit': b.monthlyLimit,
            'scope': b.scope.toJson(),
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
  Future<void> importAllData(Map<String, dynamic> data) async {
    await _transactionsBoxSafe.clear();
    await _categoriesBoxSafe.clear();
    await _recurringBoxSafe.clear();
    await _budgetsBoxSafe.clear();

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
      await _categoriesBoxSafe.put(category.id, category);
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
      );
      await _transactionsBoxSafe.put(txn.id, txn);
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
      );
      await _recurringBoxSafe.put(rec.id, rec);
    }

    for (final raw in (data['budgets'] as List? ?? [])) {
      final b = Map<String, dynamic>.from(raw as Map);
      final budget = Budget(
        id: b['id'],
        categoryId: b['categoryId'],
        monthlyLimit: (b['monthlyLimit'] as num).toDouble(),
        scope: TransactionScope.fromJson(b['scope'] ?? 'personal'),
      );
      await _budgetsBoxSafe.put(budget.id, budget);
    }

    final settings = Map<String, dynamic>.from(data['settings'] as Map? ?? {});
    if (settings['baseCurrency'] != null) baseCurrency = settings['baseCurrency'];
    if (settings['tagKeywords'] is Map) {
      await _settingsBoxSafe.put(
        'tagKeywords',
        Map<String, String>.from((settings['tagKeywords'] as Map).map((k, v) => MapEntry(k.toString(), v.toString()))),
      );
    }
  }
}
