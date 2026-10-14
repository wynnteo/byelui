import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/category.dart';
import '../theme/app_theme.dart';
import '../i18n/s.dart';

const List<Color> kCategoryColorOptions = [
  Color(0xFFFF6B4A), // coral
  Color(0xFFF59E0B), // amber
  Color(0xFFEAB308), // yellow
  Color(0xFF84CC16), // lime
  Color(0xFF10B981), // emerald
  Color(0xFF14B8A6), // teal
  Color(0xFF06B6D4), // cyan
  Color(0xFF0EA5E9), // sky
  Color(0xFF3B82F6), // blue
  Color(0xFF6366F1), // indigo
  Color(0xFF8B5CF6), // violet
  Color(0xFFA855F7), // purple
  Color(0xFFD946EF), // fuchsia
  Color(0xFFEC4899), // pink
  Color(0xFFF43F5E), // rose
  Color(0xFFEF4444), // red
  Color(0xFF64748B), // slate — good for "Other" / misc
];

/// Shows a dialog to create a new category, or edit an existing one, with a
/// name, icon, and color. Returns the created/edited Category, or null if cancelled.
Future<Category?> showCreateCategoryDialog(
  BuildContext context, {
  required TransactionType type,
  Category? existing,
}) async {
  final controller = TextEditingController(text: existing?.displayName ?? '');
  String selectedIcon = existing?.iconName ?? Category.selectableIconNames.first;
  Color selectedColor = existing != null ? Color(existing.colorValue) : kCategoryColorOptions.first;

  final result = await showDialog<Category>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        backgroundColor: AppTheme.primaryCharcoal,
        title: Text(existing != null ? S.t.editCategory : S.t.newCategory, style: AppTheme.headingSmall),
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
                  decoration: AppTheme.glassInputDecoration(hintText: S.t.categoryName),
                ),
                const SizedBox(height: 16),
                Text(S.t.icon, style: AppTheme.bodySmall),
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
                Text(S.t.color, style: AppTheme.bodySmall),
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(S.t.cancel)),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              if (existing != null) {
                Navigator.pop(
                  ctx,
                  existing.copyWith(name: name == existing.displayName ? existing.name : name, iconName: selectedIcon, colorValue: selectedColor.value),
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
            child: Text(existing != null ? S.t.save : S.t.add),
          ),
        ],
      ),
    ),
  );

  return result;
}
