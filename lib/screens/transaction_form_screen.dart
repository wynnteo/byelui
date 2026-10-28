import 'dart:io';
import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/recurring_transaction.dart';
import '../models/payment_card.dart';
import '../services/data_service.dart';
import '../services/photo_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/scope_toggle.dart';
import '../widgets/category_picker_dialog.dart';
import 'payment_cards_screen.dart';
import '../i18n/s.dart';

class TransactionFormScreen extends StatefulWidget {
  final Transaction? existing;
  final TransactionScope? initialScope;

  const TransactionFormScreen({super.key, this.existing, this.initialScope});

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _dataService = DataService();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _noteController = TextEditingController();
  final _tagController = TextEditingController();

  TransactionType _type = TransactionType.expense;
  TransactionScope _scope = TransactionScope.personal;
  String _currency = 'SGD';
  DateTime _date = DateTime.now();
  Category? _selectedCategory;
  String? _photoPath;
  bool _saving = false;
  List<String> _tags = [];
  List<String> _suggestedTags = [];
  List<String> _matchingExistingTags = [];
  bool _isRecurring = false;
  RecurrenceFrequency _recurFrequency = RecurrenceFrequency.monthly;
  PaymentMethod? _paymentMethod;
  String? _paymentCardId;

  static const _currencies = ['SGD', 'MYR', 'USD'];

  @override
  void initState() {
    super.initState();
    _scope = widget.initialScope ?? TransactionScope.personal;
    final t = widget.existing;
    if (t != null) {
      _amountController.text = t.amount.toStringAsFixed(2);
      _descriptionController.text = t.description;
      _noteController.text = t.note ?? '';
      _type = t.type;
      _scope = t.scope;
      _currency = t.currency;
      _date = t.date;
      _photoPath = t.photoPath;
      _tags = List.from(t.tags);
      _selectedCategory = _dataService.getCategoryById(t.categoryId);
      _paymentMethod = t.paymentMethod;
      _paymentCardId = t.paymentCardId;
    } else {
      final cats = _dataService.getCategories(type: _type);
      _selectedCategory = cats.isNotEmpty ? cats.first : null;
    }
    _descriptionController.addListener(_onDescriptionChanged);
    _tagController.addListener(_onTagInputChanged);
  }

  void _onDescriptionChanged() {
    final suggestions = _dataService.suggestTags(_descriptionController.text)
        .where((s) => !_tags.contains(s))
        .toList();
    if (suggestions.toString() != _suggestedTags.toString()) {
      setState(() => _suggestedTags = suggestions);
    }
  }

  void _onTagInputChanged() {
    final query = _tagController.text.trim().toLowerCase();
    if (query.isEmpty) {
      if (_matchingExistingTags.isNotEmpty) setState(() => _matchingExistingTags = []);
      return;
    }
    final matches = _dataService.getAllTags()
        .where((t) => t.toLowerCase().contains(query) && !_tags.contains(t))
        .toList();
    if (matches.toString() != _matchingExistingTags.toString()) {
      setState(() => _matchingExistingTags = matches);
    }
  }

  void _addTag(String tag) {
    final trimmed = tag.trim();
    if (trimmed.isEmpty || _tags.contains(trimmed)) return;
    setState(() {
      _tags.add(trimmed);
      _suggestedTags.remove(trimmed);
      _matchingExistingTags = [];
      _tagController.clear();
    });
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _noteController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _createCategory() async {
    final category = await showCreateCategoryDialog(context, type: _type);
    if (category == null) return;
    await _dataService.addCategory(category);
    setState(() => _selectedCategory = category);
  }

  Future<void> _manageCategory(Category category) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppTheme.primaryCharcoal,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(category.icon, color: category.color),
              title: Text(category.displayName, style: AppTheme.headingSmall),
            ),
            ListTile(
              leading: Icon(Icons.edit_outlined, color: AppTheme.textPrimary),
              title: Text(S.t.edit, style: AppTheme.bodyLarge),
              onTap: () => Navigator.pop(ctx, 'edit'),
            ),
            if (!category.isDefault)
              ListTile(
                leading: Icon(Icons.delete_outline, color: AppTheme.errorColor),
                title: Text(S.t.delete, style: TextStyle(color: AppTheme.errorColor)),
                onTap: () => Navigator.pop(ctx, 'delete'),
              ),
          ],
        ),
      ),
    );

    if (action == 'edit') {
      final updated = await showCreateCategoryDialog(context, type: _type, existing: category);
      if (updated == null) return;
      await _dataService.updateCategory(updated);
      setState(() {
        if (_selectedCategory?.id == updated.id) _selectedCategory = updated;
      });
    } else if (action == 'delete') {
      final affectedCount = _dataService.getTransactions(categoryId: category.id).length;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.primaryCharcoal,
          title: Text(S.t.deleteNamedQ(category.displayName), style: AppTheme.headingSmall),
          content: Text(
            affectedCount > 0
                ? S.t.categoryUsedByShort(affectedCount)
                : S.t.categoryHasNoTransactions,
            style: AppTheme.bodyMedium,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(S.t.cancel)),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(S.t.delete, style: TextStyle(color: AppTheme.errorColor)),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      await _dataService.deleteCategory(category.id);
      setState(() {
        if (_selectedCategory?.id == category.id) {
          final remaining = _dataService.getCategories(type: _type);
          _selectedCategory = remaining.isNotEmpty ? remaining.first : null;
        }
      });
    }
  }

  void _onTypeChanged(TransactionType type) {
    setState(() {
      _type = type;
      final cats = _dataService.getCategories(type: type);
      _selectedCategory = cats.isNotEmpty ? cats.first : null;
    });
  }

  void _selectCard(String cardId) {
    setState(() {
      _paymentCardId = cardId;
      _paymentMethod = null;
    });
  }

  void _selectGenericMethod(PaymentMethod method) {
    setState(() {
      _paymentMethod = method;
      _paymentCardId = null;
    });
  }

  Future<void> _managePaymentCards() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentCardsScreen()));
    if (mounted) setState(() {}); // refresh card list on return
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => _date = DateTime(picked.year, picked.month, picked.day, _date.hour, _date.minute));
    }
  }

  Future<void> _showPhotoOptions() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.primaryCharcoal,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt, color: AppTheme.textPrimary),
              title: Text(S.t.takePhoto, style: AppTheme.bodyLarge),
              onTap: () async {
                Navigator.pop(ctx);
                final path = await PhotoService.captureFromCamera();
                if (path != null) setState(() => _photoPath = path);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: AppTheme.textPrimary),
              title: Text(S.t.chooseFromGallery, style: AppTheme.bodyLarge),
              onTap: () async {
                Navigator.pop(ctx);
                final path = await PhotoService.pickFromGallery();
                if (path != null) setState(() => _photoPath = path);
              },
            ),
            if (_photoPath != null)
              ListTile(
                leading: Icon(Icons.delete_outline, color: AppTheme.errorColor),
                title: Text(S.t.removePhoto, style: TextStyle(color: AppTheme.errorColor)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _photoPath = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveRecurringRule(Transaction transaction) async {
    // An inline rule belongs to its source transaction. Repeated edits must
    // update that rule rather than silently creating additional schedules.
    final ruleId = 'transaction:${transaction.id}';
    final existingRule = _dataService.getRecurringTransactionById(ruleId);
    final description = _descriptionController.text.trim();
    final note = _noteController.text.trim();
    final start = _date;

    if (existingRule != null) {
      await _dataService.updateRecurringTransaction(existingRule.copyWith(
        amount: transaction.amount,
        currency: transaction.currency,
        type: transaction.type,
        scope: transaction.scope,
        categoryId: transaction.categoryId,
        description: description,
        note: note,
        clearNote: note.isEmpty,
        frequency: _recurFrequency,
        startDate: start,
        // Editing the original transaction starts future occurrences one
        // cycle later. No duplicate of the current entry is generated.
        nextDueDate: existingRule.copyWith(frequency: _recurFrequency).computeNextDate(start),
        paymentMethod: _paymentMethod,
        clearPaymentMethod: _paymentMethod == null,
        paymentCardId: _paymentCardId,
        clearPaymentCard: _paymentCardId == null,
        tags: List<String>.from(_tags),
      ));
      return;
    }

    // Migrate rules created from inline transactions by older releases where
    // possible, without touching unrelated manually-created schedules.
    final legacyMatches = _dataService.getRecurringTransactions().where((r) =>
      r.startDate.isAtSameMomentAs(start) &&
      r.scope == transaction.scope &&
      r.type == transaction.type &&
      r.categoryId == transaction.categoryId &&
      r.description == description &&
      r.amount == transaction.amount &&
      r.currency == transaction.currency &&
      r.frequency == _recurFrequency).toList();
    if (legacyMatches.isNotEmpty) {
      // A matching legacy rule already exists; do not create another.
      return;
    }

    final recurring = await _dataService.addRecurringTransaction(
      id: ruleId,
      amount: transaction.amount,
      currency: transaction.currency,
      type: transaction.type,
      scope: transaction.scope,
      categoryId: transaction.categoryId,
      description: description,
      note: note.isEmpty ? null : note,
      frequency: _recurFrequency,
      startDate: start,
      paymentMethod: _paymentMethod,
      paymentCardId: _paymentCardId,
      tags: List<String>.from(_tags),
    );
    recurring.nextDueDate = recurring.computeNextDate(start);
    await _dataService.updateRecurringTransaction(recurring);
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.t.enterValidAmount)),
      );
      return;
    }
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.t.enterDescription)),
      );
      return;
    }
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.t.selectCategory)),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      if (widget.existing != null) {
        final updated = widget.existing!.copyWith(
          amount: amount,
          currency: _currency,
          type: _type,
          scope: _scope,
          categoryId: _selectedCategory!.id,
          date: _date,
          description: _descriptionController.text.trim(),
          note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
          clearNote: _noteController.text.trim().isEmpty,
          photoPath: _photoPath,
          clearPhoto: _photoPath == null,
          tags: _tags,
          paymentMethod: _paymentMethod,
          clearPaymentMethod: _paymentMethod == null,
          paymentCardId: _paymentCardId,
          clearPaymentCard: _paymentCardId == null,
        );
        await _dataService.updateTransaction(updated);

        if (_isRecurring) {
          await _saveRecurringRule(updated);
        }
      } else {
        final created = await _dataService.addTransaction(
          amount: amount,
          currency: _currency,
          type: _type,
          scope: _scope,
          categoryId: _selectedCategory!.id,
          date: _date,
          description: _descriptionController.text.trim(),
          note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
          photoPath: _photoPath,
          tags: _tags,
          paymentMethod: _paymentMethod,
          paymentCardId: _paymentCardId,
        );

        if (_isRecurring) {
          await _saveRecurringRule(created);
        }
      }
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.primaryCharcoal,
        title: Text(S.t.deleteTransactionQ, style: AppTheme.headingSmall),
        content: Text(S.t.cantBeUndone, style: AppTheme.bodyMedium),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(S.t.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(S.t.delete, style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
    if (confirmed != true || widget.existing == null) return;

    await PhotoService.deletePhoto(widget.existing!.photoPath);
    await _dataService.deleteTransaction(widget.existing!.id);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final categories = _dataService.getCategories(type: _type);

    return Scaffold(
      backgroundColor: AppTheme.primaryCharcoal,
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.close, color: AppTheme.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        widget.existing != null ? S.t.editTransaction : S.t.addTransaction,
                        style: AppTheme.headingMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (widget.existing != null)
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: AppTheme.errorColor),
                        onPressed: _delete,
                      )
                    else
                      const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Expense / Income toggle
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppTheme.glassBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.glassBorder),
                        ),
                        child: Row(
                          children: [
                            _typeTab(S.t.expense, TransactionType.expense),
                            _typeTab(S.t.income, TransactionType.income),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Amount + currency
                      GlassCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _amountController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: AppTheme.headingLarge,
                                decoration: InputDecoration(
                                  hintText: '0.00',
                                  hintStyle: AppTheme.headingLarge,
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            DropdownButton<String>(
                              value: _currency,
                              dropdownColor: AppTheme.primaryCharcoal,
                              underline: const SizedBox(),
                              style: AppTheme.bodyLarge,
                              items: _currencies
                                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                  .toList(),
                              onChanged: (v) => setState(() => _currency = v ?? _currency),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text(S.t.category, style: AppTheme.bodySmall),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ...categories.map((c) {
                            final selected = c.id == _selectedCategory?.id;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedCategory = c),
                              onLongPress: () => _manageCategory(c),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: selected ? c.color.withOpacity(0.2) : AppTheme.glassBackground,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: selected ? c.color : AppTheme.glassBorder),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(c.icon, size: 16, color: c.color),
                                    const SizedBox(width: 6),
                                    Text(c.displayName, style: AppTheme.bodySmall.copyWith(color: AppTheme.textPrimary)),
                                  ],
                                ),
                              ),
                            );
                          }),
                          GestureDetector(
                            onTap: _createCategory,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.glassBackground,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppTheme.glassBorder, style: BorderStyle.solid),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.add, size: 16, color: AppTheme.accentAmber),
                                  const SizedBox(width: 4),
                                  Text(S.t.newItem, style: AppTheme.bodySmall.copyWith(color: AppTheme.accentAmber)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(S.t.longPressCategoryHint, style: AppTheme.caption),
                      const SizedBox(height: 16),

                      Text(S.t.paidWith, style: AppTheme.bodySmall),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ..._dataService.getPaymentCards(activeOnly: true).map((card) {
                            final selected = card.id == _paymentCardId;
                            return GestureDetector(
                              onTap: () => _selectCard(card.id),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: selected ? card.color.withOpacity(0.2) : AppTheme.glassBackground,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: selected ? card.color : AppTheme.glassBorder),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(card.icon, size: 16, color: card.color),
                                    const SizedBox(width: 6),
                                    Text(card.name, style: AppTheme.bodySmall.copyWith(color: AppTheme.textPrimary)),
                                  ],
                                ),
                              ),
                            );
                          }),
                          ...[PaymentMethod.cash, PaymentMethod.eWallet, PaymentMethod.bankTransfer, PaymentMethod.other]
                              .map((method) {
                            final selected = method == _paymentMethod;
                            return GestureDetector(
                              onTap: () => _selectGenericMethod(method),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: selected ? AppTheme.accentAmber.withOpacity(0.2) : AppTheme.glassBackground,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: selected ? AppTheme.accentAmber : AppTheme.glassBorder),
                                ),
                                child: Text(
                                  _dataService.paymentMethodLabel(method),
                                  style: AppTheme.bodySmall.copyWith(color: AppTheme.textPrimary),
                                ),
                              ),
                            );
                          }),
                          GestureDetector(
                            onTap: _managePaymentCards,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.glassBackground,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppTheme.glassBorder),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.add, size: 16, color: AppTheme.accentAmber),
                                  const SizedBox(width: 4),
                                  Text(S.t.newCard, style: AppTheme.bodySmall.copyWith(color: AppTheme.accentAmber)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Text(S.t.whoIsThisFor, style: AppTheme.bodySmall),
                      const SizedBox(height: 8),
                      ScopeToggle(
                        value: _scope,
                        includeAllOption: false,
                        onChanged: (v) => setState(() => _scope = v ?? TransactionScope.personal),
                      ),
                      const SizedBox(height: 16),

                      GlassCard(
                        onTap: _pickDate,
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, size: 18, color: AppTheme.textSecondary),
                            const SizedBox(width: 10),
                            Text(S.dateFull(_date), style: AppTheme.bodyLarge),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.repeat, color: AppTheme.accentAmber),
                                const SizedBox(width: 10),
                                Expanded(child: Text(S.t.makeRecurring, style: AppTheme.bodyLarge)),
                                Switch(
                                  value: _isRecurring,
                                  activeColor: AppTheme.primaryCoral,
                                  onChanged: (v) => setState(() => _isRecurring = v),
                                ),
                              ],
                            ),
                            if (_isRecurring) ...[
                              const SizedBox(height: 8),
                              Text(S.t.repeats, style: AppTheme.bodySmall),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: RecurrenceFrequency.values.map((f) {
                                  final selected = f == _recurFrequency;
                                  return ChoiceChip(
                                    label: Text(f.label),
                                    selected: selected,
                                    onSelected: (_) => setState(() => _recurFrequency = f),
                                    selectedColor: AppTheme.primaryCoral,
                                    backgroundColor: AppTheme.glassBackground,
                                    labelStyle: AppTheme.bodySmall.copyWith(
                                      color: selected ? AppTheme.onStamp : AppTheme.textSecondary,
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.existing == null
                                    ? S.t.firstOccurrenceNote
                                    : S.t.newRuleNote,
                                style: AppTheme.caption,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: _descriptionController,
                        style: AppTheme.bodyLarge,
                        decoration: AppTheme.glassInputDecoration(hintText: S.t.descriptionHint),
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: _noteController,
                        style: AppTheme.bodyLarge,
                        maxLines: 3,
                        decoration: AppTheme.glassInputDecoration(hintText: S.t.noteOptional),
                      ),
                      const SizedBox(height: 16),

                      Text(S.t.tags, style: AppTheme.bodySmall),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _tagController,
                        style: AppTheme.bodyLarge,
                        textInputAction: TextInputAction.done,
                        onSubmitted: _addTag,
                        decoration: AppTheme.glassInputDecoration(
                          hintText: S.t.addTagHint,
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.add, color: AppTheme.accentAmber),
                            onPressed: () => _addTag(_tagController.text),
                          ),
                        ),
                      ),
                      if (_matchingExistingTags.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.glassBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.glassBorder),
                          ),
                          constraints: const BoxConstraints(maxHeight: 160),
                          child: ListView.builder(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            itemCount: _matchingExistingTags.length,
                            itemBuilder: (ctx, i) {
                              final tag = _matchingExistingTags[i];
                              return ListTile(
                                dense: true,
                                leading: Icon(Icons.sell_outlined, size: 16, color: AppTheme.textSecondary),
                                title: Text(tag, style: AppTheme.bodyMedium),
                                onTap: () => _addTag(tag),
                              );
                            },
                          ),
                        ),
                      ],
                      if (_tags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _tags.map((tag) {
                            return Chip(
                              label: Text(tag, style: AppTheme.bodySmall.copyWith(color: AppTheme.ink)),
                              backgroundColor: AppTheme.primaryCoral.withOpacity(0.35),
                              deleteIcon: Icon(Icons.close, size: 14, color: AppTheme.ink),
                              onDeleted: () => _removeTag(tag),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            );
                          }).toList(),
                        ),
                      ],
                      if (_suggestedTags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(S.t.suggested, style: AppTheme.caption),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _suggestedTags.map((tag) {
                            return GestureDetector(
                              onTap: () => _addTag(tag),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.glassBackground,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppTheme.accentAmber.withOpacity(0.5)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.auto_awesome, size: 12, color: AppTheme.accentAmber),
                                    const SizedBox(width: 4),
                                    Text(tag, style: AppTheme.bodySmall),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 16),

                      Text(S.t.photo, style: AppTheme.bodySmall),
                      const SizedBox(height: 8),
                      GlassCard(
                        onTap: _showPhotoOptions,
                        child: _photoPath != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  File(_photoPath!),
                                  height: 160,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo, color: AppTheme.textSecondary),
                                  const SizedBox(width: 8),
                                  Text(S.t.attachReceiptPhoto, style: AppTheme.bodyMedium),
                                ],
                              ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.buttonGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ElevatedButton(
                      style: AppTheme.primaryButtonStyle,
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.onStamp),
                            )
                          : Text(S.t.saveTransaction),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeTab(String label, TransactionType type) {
    final selected = _type == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTypeChanged(type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primaryCoral : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTheme.bodyLarge.copyWith(
              color: selected ? AppTheme.onStamp : AppTheme.textSecondary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
