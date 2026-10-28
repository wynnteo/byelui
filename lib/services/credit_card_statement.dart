import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import 'data_service.dart';

/// A statement reminder, NOT an income/expense transaction.
/// Recording a credit-card repayment here never changes spending totals.
class CreditCardStatement {
  final String id;
  final String cardName;
  final String? paymentCardId;
  final TransactionScope scope;
  final String currency;
  final double statementAmount;
  final double minimumPayment;
  final DateTime dueDate;
  final DateTime? paidAt;
  final String? note;

  const CreditCardStatement({
    required this.id,
    required this.cardName,
    required this.scope,
    required this.currency,
    required this.statementAmount,
    required this.minimumPayment,
    required this.dueDate,
    this.paymentCardId,
    this.paidAt,
    this.note,
  });

  bool get isPaid => paidAt != null;
  bool get isOverdue {
    final now = DateTime.now();
    return !isPaid && DateTime(dueDate.year, dueDate.month, dueDate.day)
        .isBefore(DateTime(now.year, now.month, now.day));
  }

  CreditCardStatement copyWith({bool? paid, DateTime? paidAt}) =>
      CreditCardStatement(
        id: id,
        cardName: cardName,
        paymentCardId: paymentCardId,
        scope: scope,
        currency: currency,
        statementAmount: statementAmount,
        minimumPayment: minimumPayment,
        dueDate: dueDate,
        paidAt: paid == false ? null : (paidAt ?? this.paidAt),
        note: note,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'cardName': cardName,
    'paymentCardId': paymentCardId,
    'scope': scope.name,
    'currency': currency,
    'statementAmount': statementAmount,
    'minimumPayment': minimumPayment,
    'dueDate': dueDate.toIso8601String(),
    'paidAt': paidAt?.toIso8601String(),
    'note': note,
  };

  factory CreditCardStatement.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final cardName = json['cardName'] as String;
    final amount = (json['statementAmount'] as num).toDouble();
    final minimum = (json['minimumPayment'] as num).toDouble();
    if (id.isEmpty || cardName.trim().isEmpty || !amount.isFinite ||
        !minimum.isFinite || amount < 0 || minimum < 0 || minimum > amount) {
      throw const FormatException('Invalid credit card statement');
    }
    return CreditCardStatement(
      id: id,
      cardName: cardName,
      paymentCardId: json['paymentCardId'] as String?,
      scope: TransactionScope.fromJson(json['scope'] as String),
      currency: json['currency'] as String,
      statementAmount: amount,
      minimumPayment: minimum,
      dueDate: DateTime.parse(json['dueDate'] as String),
      paidAt: json['paidAt'] == null ? null : DateTime.parse(json['paidAt'] as String),
      note: json['note'] as String?,
    );
  }

  static CreditCardStatement create({
    required String cardName,
    required TransactionScope scope,
    required String currency,
    required double statementAmount,
    required double minimumPayment,
    required DateTime dueDate,
    String? paymentCardId,
    String? note,
  }) => CreditCardStatement(
    id: const Uuid().v4(),
    cardName: cardName,
    scope: scope,
    currency: currency,
    statementAmount: statementAmount,
    minimumPayment: minimumPayment,
    dueDate: dueDate,
    paymentCardId: paymentCardId,
    note: note,
  );
}

/// Uses the existing settings Hive box: no new Hive adapter or migration.
/// Keep writes sequential and use the same service for backups.
class CreditCardStatementStore {
  final DataService _data = DataService();

  List<CreditCardStatement> all({TransactionScope? scope}) {
    final statements = _data.getCardStatements();
    return (scope == null ? statements : statements.where((s) => s.scope == scope).toList())
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  Future<void> save(CreditCardStatement statement) => _data.saveCardStatement(statement);
  Future<void> delete(String id) => _data.deleteCardStatement(id);
}
