import 'package:hive/hive.dart';
import 'category.dart';

part 'transaction.g.dart';

@HiveType(typeId: 22)
enum TransactionScope {
  @HiveField(0)
  personal,
  @HiveField(1)
  family;

  String toJson() => name;

  static TransactionScope fromJson(String json) {
    return TransactionScope.values.firstWhere(
      (e) => e.name == json,
      orElse: () => TransactionScope.personal,
    );
  }
}

@HiveType(typeId: 23)
enum PaymentMethod {
  @HiveField(0)
  cash,
  @HiveField(1)
  card,
  @HiveField(2)
  eWallet,
  @HiveField(3)
  bankTransfer,
  @HiveField(4)
  other;

  String toJson() => name;

  static PaymentMethod fromJson(String json) {
    return PaymentMethod.values.firstWhere(
      (e) => e.name == json,
      orElse: () => PaymentMethod.other,
    );
  }
}

@HiveType(typeId: 24)
class Transaction extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  double amount;

  @HiveField(2)
  String currency; // e.g. 'MYR', 'SGD'

  @HiveField(3)
  TransactionType type; // expense / income

  @HiveField(4)
  TransactionScope scope; // personal / family

  @HiveField(5)
  String categoryId;

  @HiveField(6)
  DateTime date;

  @HiveField(7)
  String description;

  @HiveField(8)
  String? note;

  @HiveField(9)
  String? photoPath; // local file path to captured/selected receipt photo

  @HiveField(10)
  PaymentMethod? paymentMethod;

  @HiveField(11)
  DateTime createdAt;

  @HiveField(12)
  DateTime updatedAt;

  @HiveField(13, defaultValue: <String>[])
  List<String> tags;

  Transaction({
    required this.id,
    required this.amount,
    required this.currency,
    required this.type,
    required this.scope,
    required this.categoryId,
    required this.date,
    required this.description,
    this.note,
    this.photoPath,
    this.paymentMethod,
    required this.createdAt,
    required this.updatedAt,
    List<String>? tags,
  }) : tags = tags ?? [];

  bool get isExpense => type == TransactionType.expense;
  bool get isIncome => type == TransactionType.income;
  bool get hasPhoto => photoPath != null && photoPath!.isNotEmpty;

  /// Signed amount for totals: expenses negative, income positive.
  double get signedAmount => isExpense ? -amount.abs() : amount.abs();

  Transaction copyWith({
    String? id,
    double? amount,
    String? currency,
    TransactionType? type,
    TransactionScope? scope,
    String? categoryId,
    DateTime? date,
    String? description,
    String? note,
    String? photoPath,
    bool clearPhoto = false,
    PaymentMethod? paymentMethod,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
  }) {
    return Transaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      type: type ?? this.type,
      scope: scope ?? this.scope,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      description: description ?? this.description,
      note: note ?? this.note,
      photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      tags: tags ?? this.tags,
    );
  }
}
