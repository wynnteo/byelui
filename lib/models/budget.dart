import 'package:hive/hive.dart';
import 'transaction.dart';

part 'budget.g.dart';

@HiveType(typeId: 27)
class Budget extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String categoryId;

  @HiveField(2)
  double monthlyLimit; // stored in base currency

  @HiveField(3)
  TransactionScope scope;

  Budget({
    required this.id,
    required this.categoryId,
    required this.monthlyLimit,
    this.scope = TransactionScope.personal,
  });

  Budget copyWith({double? monthlyLimit, TransactionScope? scope}) {
    return Budget(
      id: id,
      categoryId: categoryId,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      scope: scope ?? this.scope,
    );
  }
}
