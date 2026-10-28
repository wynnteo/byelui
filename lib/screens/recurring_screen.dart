import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/recurring_transaction.dart';
import '../services/data_service.dart';
import '../services/bill_notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/scope_toggle.dart';
import '../i18n/s.dart';

class RecurringScreen extends StatefulWidget {
  const RecurringScreen({super.key});

  @override
  State<RecurringScreen> createState() => _RecurringScreenState();
}

class _RecurringScreenState extends State<RecurringScreen> {
  final _dataService = DataService();

  void _refresh() => setState(() {});

  /// "Trust Card · Netflix, Rent" — the payment source and tags this rule applies.
  String? _detailsLine(RecurringTransaction r) {
    final parts = <String>[];
    final card = r.paymentCardId != null ? _dataService.getPaymentCardById(r.paymentCardId!) : null;
    if (card != null) {
      parts.add(card.name);
    } else if (r.paymentMethod != null) {
      parts.add(_dataService.paymentMethodLabel(r.paymentMethod!));
    }
    if (r.tags.isNotEmpty) parts.add(r.tags.join(', '));
    return parts.isEmpty ? null : parts.join(' · ');
  }

  Future<void> _toggleActive(RecurringTransaction r) async {
    await _dataService.updateRecurringTransaction(r.copyWith(isActive: !r.isActive));
    await BillNotificationService.instance.syncSafely();
    _refresh();
  }

  Future<void> _delete(RecurringTransaction r) async {
    await _dataService.deleteRecurringTransaction(r.id);
    await BillNotificationService.instance.syncSafely();
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final items = _dataService.getRecurringTransactions();
    final base = _dataService.baseCurrency;

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
                      icon: Icon(Icons.arrow_back, color: AppTheme.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(S.t.recurring, style: AppTheme.headingMedium),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.add, color: AppTheme.stampText),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RecurringFormScreen()),
                        );
                        _refresh();
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            S.t.noRecurringYet,
                            textAlign: TextAlign.center,
                            style: AppTheme.bodyMedium,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (ctx, i) {
                          final r = items[i];
                          final category = _dataService.getCategoryById(r.categoryId);
                          return GlassCard(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => RecurringFormScreen(existing: r)),
                              );
                              _refresh();
                            },
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: (category?.color ?? AppTheme.otherColor).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(category?.icon ?? Icons.label, color: category?.color ?? AppTheme.otherColor, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(r.description, style: AppTheme.bodyLarge),
                                      const SizedBox(height: 2),
                                      Text(
                                        S.t.frequencyNext(r.frequency.label, S.dayMonth(r.nextDueDate ?? r.startDate)),
                                        style: AppTheme.bodySmall,
                                      ),
                                      if (_detailsLine(r) != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          _detailsLine(r)!,
                                          style: AppTheme.caption,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Text(
                                  '${r.currency} ${r.amount.toStringAsFixed(2)}',
                                  style: AppTheme.bodyMedium,
                                ),
                                Switch(
                                  value: r.isActive,
                                  activeColor: AppTheme.primaryCoral,
                                  onChanged: (_) => _toggleActive(r),
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
}

class RecurringFormScreen extends StatefulWidget {
  final RecurringTransaction? existing;
  const RecurringFormScreen({super.key, this.existing});

  @override
  State<RecurringFormScreen> createState() => _RecurringFormScreenState();
}

class _RecurringFormScreenState extends State<RecurringFormScreen> {
  final _dataService = DataService();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  TransactionType _type = TransactionType.expense;
  TransactionScope _scope = TransactionScope.personal;
  String _currency = 'SGD';
  RecurrenceFrequency _frequency = RecurrenceFrequency.monthly;
  DateTime _startDate = DateTime.now();
  Category? _selectedCategory;

  final _tagController = TextEditingController();
  List<String> _tags = [];
  List<String> _suggestedTags = [];
  List<String> _matchingExistingTags = [];
  PaymentMethod? _paymentMethod;
  String? _paymentCardId;

  static const _currencies = ['SGD', 'MYR', 'USD'];

  @override
  void initState() {
    super.initState();
    final r = widget.existing;
    if (r != null) {
      _amountController.text = r.amount.toStringAsFixed(2);
      _descriptionController.text = r.description;
      _type = r.type;
      _scope = r.scope;
      _currency = r.currency;
      _frequency = r.frequency;
      _startDate = r.startDate;
      _selectedCategory = _dataService.getCategoryById(r.categoryId);
      _tags = List.from(r.tags);
      _paymentMethod = r.paymentMethod;
      _paymentCardId = r.paymentCardId;
    } else {
      final cats = _dataService.getCategories(type: _type);
      _selectedCategory = cats.isNotEmpty ? cats.first : null;
    }
    _descriptionController.addListener(_onDescriptionChanged);
    _tagController.addListener(_onTagInputChanged);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _onDescriptionChanged() {
    final suggestions = _dataService.suggestTags(_descriptionController.text).where((s) => !_tags.contains(s)).toList();
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
    final matches = _dataService
        .getAllTags()
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

  void _removeTag(String tag) => setState(() => _tags.remove(tag));

  // Tapping the selected chip again clears it - paying method is optional.
  void _toggleCard(String cardId) {
    setState(() {
      _paymentCardId = _paymentCardId == cardId ? null : cardId;
      _paymentMethod = null;
    });
  }

  void _toggleMethod(PaymentMethod method) {
    setState(() {
      _paymentMethod = _paymentMethod == method ? null : method;
      _paymentCardId = null;
    });
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0 || _descriptionController.text.trim().isEmpty || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.t.fillInRecurring)),
      );
      return;
    }

    if (widget.existing != null) {
      await _dataService.updateRecurringTransaction(widget.existing!.copyWith(
        amount: amount,
        currency: _currency,
        type: _type,
        scope: _scope,
        categoryId: _selectedCategory!.id,
        description: _descriptionController.text.trim(),
        frequency: _frequency,
        startDate: _startDate,
        tags: _tags,
        paymentMethod: _paymentMethod,
        clearPaymentMethod: _paymentMethod == null,
        paymentCardId: _paymentCardId,
        clearPaymentCard: _paymentCardId == null,
      ));
    } else {
      await _dataService.addRecurringTransaction(
        amount: amount,
        currency: _currency,
        type: _type,
        scope: _scope,
        categoryId: _selectedCategory!.id,
        description: _descriptionController.text.trim(),
        frequency: _frequency,
        startDate: _startDate,
        tags: _tags,
        paymentMethod: _paymentMethod,
        paymentCardId: _paymentCardId,
      );
    }
    if (mounted) Navigator.pop(context);
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
                    Text(widget.existing != null ? S.t.editRecurring : S.t.addRecurring, style: AppTheme.headingMedium),
                    const Spacer(),
                    if (widget.existing != null)
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: AppTheme.errorColor),
                        onPressed: () async {
                          await _dataService.deleteRecurringTransaction(widget.existing!.id);
                          if (mounted) Navigator.pop(context);
                        },
                      ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GlassCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _amountController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: AppTheme.headingLarge,
                                decoration: const InputDecoration(hintText: '0.00', border: InputBorder.none),
                              ),
                            ),
                            DropdownButton<String>(
                              value: _currency,
                              dropdownColor: AppTheme.primaryCharcoal,
                              underline: const SizedBox(),
                              items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                              onChanged: (v) => setState(() => _currency = v ?? _currency),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _descriptionController,
                        style: AppTheme.bodyLarge,
                        decoration: AppTheme.glassInputDecoration(hintText: S.t.recurringDescHint),
                      ),
                      const SizedBox(height: 16),

                      Text(S.t.category, style: AppTheme.bodySmall),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: categories.map((c) {
                          final selected = c.id == _selectedCategory?.id;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedCategory = c),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: selected ? c.color.withOpacity(0.2) : AppTheme.glassBackground,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: selected ? c.color : AppTheme.glassBorder),
                              ),
                              child: Text(c.displayName, style: AppTheme.bodySmall.copyWith(color: AppTheme.textPrimary)),
                            ),
                          );
                        }).toList(),
                      ),
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
                              onTap: () => _toggleCard(card.id),
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
                          ...[PaymentMethod.cash, PaymentMethod.eWallet, PaymentMethod.bankTransfer, PaymentMethod.other].map((method) {
                            final selected = method == _paymentMethod;
                            return GestureDetector(
                              onTap: () => _toggleMethod(method),
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
                        ],
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
                          hintText: S.t.recurringTagHint,
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

                      Text(S.t.frequency, style: AppTheme.bodySmall),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: RecurrenceFrequency.values.map((f) {
                          final selected = f == _frequency;
                          return ChoiceChip(
                            label: Text(f.label),
                            selected: selected,
                            onSelected: (_) => setState(() => _frequency = f),
                            selectedColor: AppTheme.primaryCoral,
                            backgroundColor: AppTheme.glassBackground,
                            labelStyle: AppTheme.bodySmall.copyWith(
                              color: selected ? AppTheme.onStamp : AppTheme.textSecondary,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      Text(S.t.whoIsThisFor, style: AppTheme.bodySmall),
                      const SizedBox(height: 8),
                      ScopeToggle(
                        value: _scope,
                        includeAllOption: false,
                        onChanged: (v) => setState(() => _scope = v ?? TransactionScope.personal),
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
                    decoration: BoxDecoration(gradient: AppTheme.buttonGradient, borderRadius: BorderRadius.circular(16)),
                    child: ElevatedButton(
                      style: AppTheme.primaryButtonStyle,
                      onPressed: _save,
                      child: Text(S.t.save),
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
}
