import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/recurring_transaction.dart';
import '../services/data_service.dart';
import '../services/photo_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/scope_toggle.dart';
import '../widgets/category_picker_dialog.dart';

class TransactionFormScreen extends StatefulWidget {
  final Transaction? existing;

  const TransactionFormScreen({super.key, this.existing});

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
  bool _isRecurring = false;
  RecurrenceFrequency _recurFrequency = RecurrenceFrequency.monthly;

  static const _currencies = ['SGD', 'MYR', 'USD'];

  @override
  void initState() {
    super.initState();
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
    } else {
      final cats = _dataService.getCategories(type: _type);
      _selectedCategory = cats.isNotEmpty ? cats.first : null;
    }
    _descriptionController.addListener(_onDescriptionChanged);
  }

  void _onDescriptionChanged() {
    final suggestions = _dataService.suggestTags(_descriptionController.text)
        .where((s) => !_tags.contains(s))
        .toList();
    if (suggestions.toString() != _suggestedTags.toString()) {
      setState(() => _suggestedTags = suggestions);
    }
  }

  void _addTag(String tag) {
    final trimmed = tag.trim();
    if (trimmed.isEmpty || _tags.contains(trimmed)) return;
    setState(() {
      _tags.add(trimmed);
      _suggestedTags.remove(trimmed);
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
              title: Text(category.name, style: AppTheme.headingSmall),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: AppTheme.textPrimary),
              title: const Text('Edit', style: AppTheme.bodyLarge),
              onTap: () => Navigator.pop(ctx, 'edit'),
            ),
            if (!category.isDefault)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
                title: const Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
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
          title: Text('Delete "${category.name}"?', style: AppTheme.headingSmall),
          content: Text(
            affectedCount > 0
                ? '$affectedCount transaction(s) use this category and will show without a category icon.'
                : 'This category has no transactions yet.',
            style: AppTheme.bodyMedium,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
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
              leading: const Icon(Icons.camera_alt, color: AppTheme.textPrimary),
              title: const Text('Take photo', style: AppTheme.bodyLarge),
              onTap: () async {
                Navigator.pop(ctx);
                final path = await PhotoService.captureFromCamera();
                if (path != null) setState(() => _photoPath = path);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppTheme.textPrimary),
              title: const Text('Choose from gallery', style: AppTheme.bodyLarge),
              onTap: () async {
                Navigator.pop(ctx);
                final path = await PhotoService.pickFromGallery();
                if (path != null) setState(() => _photoPath = path);
              },
            ),
            if (_photoPath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
                title: const Text('Remove photo', style: TextStyle(color: AppTheme.errorColor)),
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

  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a description')),
      );
      return;
    }
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a category')),
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
          photoPath: _photoPath,
          clearPhoto: _photoPath == null,
          tags: _tags,
        );
        await _dataService.updateTransaction(updated);
      } else {
        await _dataService.addTransaction(
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
        );

        if (_isRecurring) {
          final recurring = await _dataService.addRecurringTransaction(
            amount: amount,
            currency: _currency,
            type: _type,
            scope: _scope,
            categoryId: _selectedCategory!.id,
            description: _descriptionController.text.trim(),
            note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
            frequency: _recurFrequency,
            startDate: _date,
          );
          // This transaction IS the first occurrence — push the rule's next
          // due date one cycle ahead so generateDueRecurringTransactions()
          // doesn't immediately create a duplicate for today.
          recurring.nextDueDate = recurring.computeNextDate(_date);
          await _dataService.updateRecurringTransaction(recurring);
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
        title: const Text('Delete transaction?', style: AppTheme.headingSmall),
        content: Text('This can\'t be undone.', style: AppTheme.bodyMedium),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
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
                    Expanded(
                      child: Text(
                        widget.existing != null ? 'Edit transaction' : 'Add transaction',
                        style: AppTheme.headingMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (widget.existing != null)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
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
                            _typeTab('Expense', TransactionType.expense),
                            _typeTab('Income', TransactionType.income),
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
                                decoration: const InputDecoration(
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

                      Text('Category', style: AppTheme.bodySmall),
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
                                    Text(c.name, style: AppTheme.bodySmall.copyWith(color: AppTheme.textPrimary)),
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
                                  Text('New', style: AppTheme.bodySmall.copyWith(color: AppTheme.accentAmber)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Long-press a category to edit or delete it', style: AppTheme.caption),
                      const SizedBox(height: 16),

                      Text('Who is this for', style: AppTheme.bodySmall),
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
                            const Icon(Icons.calendar_today, size: 18, color: AppTheme.textSecondary),
                            const SizedBox(width: 10),
                            Text(DateFormat('EEE, d MMM yyyy').format(_date), style: AppTheme.bodyLarge),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (widget.existing == null) ...[
                        GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.repeat, color: AppTheme.accentAmber),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text('Make this recurring', style: AppTheme.bodyLarge)),
                                  Switch(
                                    value: _isRecurring,
                                    activeColor: AppTheme.primaryCoral,
                                    onChanged: (v) => setState(() => _isRecurring = v),
                                  ),
                                ],
                              ),
                              if (_isRecurring) ...[
                                const SizedBox(height: 8),
                                Text('Repeats', style: AppTheme.bodySmall),
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
                                        color: selected ? Colors.white : AppTheme.textSecondary,
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'This transaction is the first occurrence. Manage or pause it later in Settings → Recurring.',
                                  style: AppTheme.caption,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      TextField(
                        controller: _descriptionController,
                        style: AppTheme.bodyLarge,
                        decoration: AppTheme.glassInputDecoration(hintText: 'Description, e.g. Lunch at XYZ'),
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: _noteController,
                        style: AppTheme.bodyLarge,
                        maxLines: 3,
                        decoration: AppTheme.glassInputDecoration(hintText: 'Note (optional)'),
                      ),
                      const SizedBox(height: 16),

                      Text('Tags', style: AppTheme.bodySmall),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _tagController,
                        style: AppTheme.bodyLarge,
                        textInputAction: TextInputAction.done,
                        onSubmitted: _addTag,
                        decoration: AppTheme.glassInputDecoration(
                          hintText: 'Add a tag, e.g. Shopee, Bubble tea',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.add, color: AppTheme.accentAmber),
                            onPressed: () => _addTag(_tagController.text),
                          ),
                        ),
                      ),
                      if (_tags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _tags.map((tag) {
                            return Chip(
                              label: Text(tag, style: AppTheme.bodySmall.copyWith(color: Colors.white)),
                              backgroundColor: AppTheme.primaryCoral.withOpacity(0.35),
                              deleteIcon: const Icon(Icons.close, size: 14, color: Colors.white),
                              onDeleted: () => _removeTag(tag),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            );
                          }).toList(),
                        ),
                      ],
                      if (_suggestedTags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('Suggested', style: AppTheme.caption),
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

                      Text('Photo', style: AppTheme.bodySmall),
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
                                  const Icon(Icons.add_a_photo, color: AppTheme.textSecondary),
                                  const SizedBox(width: 8),
                                  Text('Attach receipt photo', style: AppTheme.bodyMedium),
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
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Save transaction'),
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
              color: selected ? Colors.white : AppTheme.textSecondary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
