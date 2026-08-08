import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/category.dart';
import '../theme/app_theme.dart';

const List<Color> kCategoryColorOptions = [
  AppTheme.primaryCoral,
  AppTheme.accentAmber,
  AppTheme.foodColor,
  AppTheme.transportColor,
  AppTheme.groceriesColor,
  AppTheme.billsColor,
  AppTheme.healthColor,
  AppTheme.shoppingColor,
  AppTheme.entertainmentColor,
  AppTheme.incomeColor,
  Color(0xFF6366F1),
  Color(0xFFEC4899),
  AppTheme.otherColor,
];

/// Shows a dialog to create a new category, or edit an existing one, with a
/// name, icon, and color. Returns the created/edited Category, or null if cancelled.
Future<Category?> showCreateCategoryDialog(
  BuildContext context, {
  required TransactionType type,
  Category? existing,
}) async {
  final controller = TextEditingController(text: existing?.name ?? '');
  String selectedIcon = existing?.iconName ?? Category.selectableIconNames.first;
  Color selectedColor = existing != null ? Color(existing.colorValue) : kCategoryColorOptions.first;

  final result = await showDialog<Category>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        backgroundColor: AppTheme.primaryCharcoal,
        title: Text(existing != null ? 'Edit category' : 'New category', style: AppTheme.headingSmall),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  style: AppTheme.bodyLarge,
                  decoration: AppTheme.glassInputDecoration(hintText: 'Category name'),
                ),
                const SizedBox(height: 16),
                Text('Icon', style: AppTheme.bodySmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: Category.selectableIconNames.map((name) {
                    final tempCategory = Category(id: '', name: '', iconName: name, colorValue: selectedColor.value, type: type);
                    final selected = name == selectedIcon;
                    return GestureDetector(
                      onTap: () => setState(() => selectedIcon = name),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: selected ? selectedColor.withOpacity(0.25) : AppTheme.glassBackground,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: selected ? selectedColor : AppTheme.glassBorder),
                        ),
                        alignment: Alignment.center,
                        child: Icon(tempCategory.icon, size: 18, color: selected ? selectedColor : AppTheme.textSecondary),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text('Color', style: AppTheme.bodySmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: kCategoryColorOptions.map((color) {
                    final selected = color.value == selectedColor.value;
                    return GestureDetector(
                      onTap: () => setState(() => selectedColor = color),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: selected ? Border.all(color: Colors.white, width: 2) : null,
                        ),
                        child: selected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              if (existing != null) {
                Navigator.pop(
                  ctx,
                  existing.copyWith(name: name, iconName: selectedIcon, colorValue: selectedColor.value),
                );
              } else {
                Navigator.pop(
                  ctx,
                  Category(
                    id: const Uuid().v4(),
                    name: name,
                    iconName: selectedIcon,
                    colorValue: selectedColor.value,
                    type: type,
                    isDefault: false,
                  ),
                );
              }
            },
            child: Text(existing != null ? 'Save' : 'Add'),
          ),
        ],
      ),
    ),
  );

  return result;
}
