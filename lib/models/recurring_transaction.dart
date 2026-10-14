import 'package:hive/hive.dart';
import 'transaction.dart';
import 'category.dart';
import '../i18n/s.dart';

part 'recurring_transaction.g.dart';

@HiveType(typeId: 25)
enum RecurrenceFrequency {
  @HiveField(0)
  daily,
  @HiveField(1)
  weekly,
  @HiveField(2)
  monthly,
  @HiveField(3)
  yearly;

  String get label {
    switch (this) {
      case RecurrenceFrequency.daily:
        return S.t.daily;
      case RecurrenceFrequency.weekly:
        return S.t.weekly;
      case RecurrenceFrequency.monthly:
        return S.t.monthly;
      case RecurrenceFrequency.yearly:
        return S.t.yearly;
    }
  }
}

@HiveType(typeId: 26)
class RecurringTransaction extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  double amount;

  @HiveField(2)
  String currency;

  @HiveField(3)
  TransactionType type;

  @HiveField(4)
  TransactionScope scope;

  @HiveField(5)
  String categoryId;

  @HiveField(6)
  String description;

  @HiveField(7)
  String? note;

  @HiveField(8)
  RecurrenceFrequency frequency;

  @HiveField(9)
  DateTime startDate;

  @HiveField(10)
  DateTime? nextDueDate;

  @HiveField(11)
  DateTime? endDate;

  @HiveField(12, defaultValue: true)
  bool isActive;

  @HiveField(13)
  PaymentMethod? paymentMethod;

  @HiveField(14, defaultValue: <String>[])
  List<String> tags;

  @HiveField(15)
  String? paymentCardId;

  RecurringTransaction({
    required this.id,
    required this.amount,
    required this.currency,
    required this.type,
    required this.scope,
    required this.categoryId,
    required this.description,
    this.note,
    required this.frequency,
    required this.startDate,
    this.nextDueDate,
    this.endDate,
    this.isActive = true,
    this.paymentMethod,
    List<String>? tags,
    this.paymentCardId,
  }) : tags = tags ?? [];

  DateTime computeNextDate(DateTime from) {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return from.add(const Duration(days: 1));
      case RecurrenceFrequency.weekly:
        return from.add(const Duration(days: 7));
      case RecurrenceFrequency.monthly:
        return DateTime(from.year, from.month + 1, from.day);
      case RecurrenceFrequency.yearly:
        return DateTime(from.year + 1, from.month, from.day);
    }
  }

  bool get isDue {
    if (!isActive) return false;
    final due = nextDueDate ?? startDate;
    if (endDate != null && due.isAfter(endDate!)) return false;
    return !due.isAfter(DateTime.now());
  }

  RecurringTransaction copyWith({
    double? amount,
    String? currency,
    TransactionType? type,
    TransactionScope? scope,
    String? categoryId,
    String? description,
    String? note,
    bool clearNote = false,
    RecurrenceFrequency? frequency,
    DateTime? startDate,
    DateTime? nextDueDate,
    DateTime? endDate,
    bool? isActive,
    PaymentMethod? paymentMethod,
    bool clearPaymentMethod = false,
    List<String>? tags,
    String? paymentCardId,
    bool clearPaymentCard = false,
  }) {
    return RecurringTransaction(
      id: id,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      type: type ?? this.type,
      scope: scope ?? this.scope,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      note: clearNote ? null : (note ?? this.note),
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      paymentMethod: clearPaymentMethod ? null : (paymentMethod ?? this.paymentMethod),
      tags: tags ?? this.tags,
      paymentCardId: clearPaymentCard ? null : (paymentCardId ?? this.paymentCardId),
    );
  }
}