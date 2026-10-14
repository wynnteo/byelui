import 'package:flutter/material.dart';
import '../models/category.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/category_picker_dialog.dart';
import '../i18n/s.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _dataService = DataService();
  TransactionType _type = TransactionType.expense;

  Future<void> _addCategoryDialog() async {
    final category = await showCreateCategoryDialog(context, type: _type);
    if (category == null) return;
    await _dataService.addCategory(category);
    setState(() {});
  }

  Future<void> _editCategoryDialog(Category category) async {
    final updated = await showCreateCategoryDialog(context, type: _type, existing: category);
    if (updated == null) return;
    await _dataService.updateCategory(updated);
    setState(() {});
  }

  Future<void> _deleteCategory(Category category) async {
    if (category.isDefault) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.t.defaultCategoriesCantDelete)),
      );
      return;
    }

    final affectedCount = _dataService.getTransactions(categoryId: category.id).length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.primaryCharcoal,
        title: Text(S.t.deleteNamedQ(category.displayName), style: AppTheme.headingSmall),
        content: Text(
          affectedCount > 0
              ? S.t.categoryUsedByLong(affectedCount)
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
    setState(() {});
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
                      icon: Icon(Icons.arrow_back, color: AppTheme.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(S.t.categories, style: AppTheme.headingMedium),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.add, color: AppTheme.stampText),
                      onPressed: _addCategoryDialog,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(S.t.categoriesHint, style: AppTheme.caption),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.glassBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.glassBorder),
                  ),
                  child: Row(
                    children: [TransactionType.expense, TransactionType.income].map((t) {
                      final selected = t == _type;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _type = t),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: selected ? AppTheme.primaryCoral : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              t == TransactionType.expense ? S.t.expense : S.t.income,
                              style: AppTheme.bodyMedium.copyWith(
                                color: selected ? AppTheme.onStamp : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final c = categories[i];
                    return GlassCard(
                      onTap: () => _editCategoryDialog(c),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: c.color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            alignment: Alignment.center,
                            child: Icon(c.icon, color: c.color, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(c.displayName, style: AppTheme.bodyLarge)),
                          if (c.isDefault)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Text(S.t.defaultLabel, style: AppTheme.caption),
                            ),
                          IconButton(
                            icon: Icon(Icons.edit_outlined, color: AppTheme.textTertiary, size: 20),
                            onPressed: () => _editCategoryDialog(c),
                          ),
                          if (!c.isDefault)
                            IconButton(
                              icon: Icon(Icons.delete_outline, color: AppTheme.errorColor, size: 20),
                              onPressed: () => _deleteCategory(c),
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
