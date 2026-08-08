import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/recurring_transaction.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/scope_toggle.dart';

class RecurringScreen extends StatefulWidget {
  const RecurringScreen({super.key});

  @override
  State<RecurringScreen> createState() => _RecurringScreenState();
}

class _RecurringScreenState extends State<RecurringScreen> {
  final _dataService = DataService();

  void _refresh() => setState(() {});

  Future<void> _toggleActive(RecurringTransaction r) async {
    await _dataService.updateRecurringTransaction(r.copyWith(isActive: !r.isActive));
    _refresh();
  }

  Future<void> _delete(RecurringTransaction r) async {
    await _dataService.deleteRecurringTransaction(r.id);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final items = _dataService.getRecurringTransactions();
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
                    Text('Recurring', style: AppTheme.headingMedium),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.add, color: AppTheme.primaryCoral),
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
                            'No recurring transactions yet.\nUse + to add rent, subscriptions, or salary.',
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
                                        '${r.frequency.label} · Next ${DateFormat('d MMM').format(r.nextDueDate ?? r.startDate)}',
                                        style: AppTheme.bodySmall,
                                      ),
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
    } else {
      final cats = _dataService.getCategories(type: _type);
      _selectedCategory = cats.isNotEmpty ? cats.first : null;
    }
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0 || _descriptionController.text.trim().isEmpty || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill in amount, description, and category')),
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
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(widget.existing != null ? 'Edit recurring' : 'Add recurring', style: AppTheme.headingMedium),
                    const Spacer(),
                    if (widget.existing != null)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
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
                        decoration: AppTheme.glassInputDecoration(hintText: 'e.g. Rent, Netflix, Salary'),
                      ),
                      const SizedBox(height: 16),

                      Text('Category', style: AppTheme.bodySmall),
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
                              child: Text(c.name, style: AppTheme.bodySmall.copyWith(color: AppTheme.textPrimary)),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      Text('Frequency', style: AppTheme.bodySmall),
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
                              color: selected ? Colors.white : AppTheme.textSecondary,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      Text('Who is this for', style: AppTheme.bodySmall),
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
                      child: const Text('Save'),
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
