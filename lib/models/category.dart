import 'package:hive/hive.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

part 'category.g.dart';

@HiveType(typeId: 20)
enum TransactionType {
  @HiveField(0)
  expense,
  @HiveField(1)
  income;

  String toJson() => name;

  static TransactionType fromJson(String json) {
    return TransactionType.values.firstWhere(
      (e) => e.name == json,
      orElse: () => TransactionType.expense,
    );
  }
}

@HiveType(typeId: 21)
class Category extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String iconName;

  @HiveField(3)
  int colorValue;

  @HiveField(4)
  TransactionType type;

  @HiveField(5, defaultValue: false)
  bool isDefault;

  Category({
    required this.id,
    required this.name,
    required this.iconName,
    required this.colorValue,
    required this.type,
    this.isDefault = false,
  });

  Color get color => Color(colorValue);

  IconData get icon {
    switch (iconName) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'groceries':
        return Icons.shopping_basket;
      case 'bills':
        return Icons.receipt_long;
      case 'health':
        return Icons.medical_services;
      case 'shopping':
        return Icons.shopping_bag;
      case 'entertainment':
        return Icons.movie;
      case 'education':
        return Icons.school;
      case 'salary':
        return Icons.payments;
      case 'gift':
        return Icons.card_giftcard;
      case 'bonus':
        return Icons.star;
      case 'home':
        return Icons.home;
      case 'travel':
        return Icons.flight;
      case 'pet':
        return Icons.pets;
      case 'fitness':
        return Icons.fitness_center;
      case 'tech':
        return Icons.devices;
      case 'beauty':
        return Icons.face_retouching_natural;
      case 'kids':
        return Icons.child_care;
      case 'insurance':
        return Icons.shield;
      case 'subscriptions':
        return Icons.subscriptions;
      case 'coffee':
        return Icons.local_cafe;
      case 'investment':
        return Icons.trending_up;
      case 'other':
      default:
        return Icons.label;
    }
  }

  /// All selectable icon names, for the category creation picker.
  static const List<String> selectableIconNames = [
    'food', 'transport', 'groceries', 'bills', 'health', 'shopping',
    'entertainment', 'education', 'home', 'travel', 'pet', 'fitness',
    'tech', 'beauty', 'kids', 'insurance', 'subscriptions', 'coffee',
    'investment', 'salary', 'gift', 'bonus', 'other',
  ];

  Category copyWith({
    String? id,
    String? name,
    String? iconName,
    int? colorValue,
    TransactionType? type,
    bool? isDefault,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      colorValue: colorValue ?? this.colorValue,
      type: type ?? this.type,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  static List<Category> defaultExpenseCategories() {
    return [
      Category(id: 'exp_food', name: 'Food', iconName: 'food', colorValue: AppTheme.foodColor.value, type: TransactionType.expense, isDefault: true),
      Category(id: 'exp_transport', name: 'Transport', iconName: 'transport', colorValue: AppTheme.transportColor.value, type: TransactionType.expense, isDefault: true),
      Category(id: 'exp_groceries', name: 'Groceries', iconName: 'groceries', colorValue: AppTheme.groceriesColor.value, type: TransactionType.expense, isDefault: true),
      Category(id: 'exp_bills', name: 'Bills', iconName: 'bills', colorValue: AppTheme.billsColor.value, type: TransactionType.expense, isDefault: true),
      Category(id: 'exp_health', name: 'Health', iconName: 'health', colorValue: AppTheme.healthColor.value, type: TransactionType.expense, isDefault: true),
      Category(id: 'exp_shopping', name: 'Shopping', iconName: 'shopping', colorValue: AppTheme.shoppingColor.value, type: TransactionType.expense, isDefault: true),
      Category(id: 'exp_entertainment', name: 'Entertainment', iconName: 'entertainment', colorValue: AppTheme.entertainmentColor.value, type: TransactionType.expense, isDefault: true),
      Category(id: 'exp_education', name: 'Education', iconName: 'education', colorValue: AppTheme.shoppingColor.value, type: TransactionType.expense, isDefault: true),
      Category(id: 'exp_other', name: 'Other', iconName: 'other', colorValue: AppTheme.otherColor.value, type: TransactionType.expense, isDefault: true),
    ];
  }

  static List<Category> defaultIncomeCategories() {
    return [
      Category(id: 'inc_salary', name: 'Salary', iconName: 'salary', colorValue: AppTheme.incomeColor.value, type: TransactionType.income, isDefault: true),
      Category(id: 'inc_bonus', name: 'Bonus', iconName: 'bonus', colorValue: AppTheme.incomeColor.value, type: TransactionType.income, isDefault: true),
      Category(id: 'inc_gift', name: 'Gift', iconName: 'gift', colorValue: AppTheme.incomeColor.value, type: TransactionType.income, isDefault: true),
      Category(id: 'inc_other', name: 'Other income', iconName: 'other', colorValue: AppTheme.otherColor.value, type: TransactionType.income, isDefault: true),
    ];
  }
}
