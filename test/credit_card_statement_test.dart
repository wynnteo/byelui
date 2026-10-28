import 'package:flutter_test/flutter_test.dart';
import 'package:byelui/models/transaction.dart';
import 'package:byelui/services/credit_card_statement.dart';

void main() {
  test('card statement JSON roundtrip preserves scope, due date, and paid status', () {
    final statement = CreditCardStatement.create(
      cardName: 'UOB Credit',
      scope: TransactionScope.family,
      currency: 'SGD',
      statementAmount: 1250,
      minimumPayment: 50,
      dueDate: DateTime(2026, 11, 5),
    );
    final restored = CreditCardStatement.fromJson(statement.toJson());
    expect(restored.id, statement.id);
    expect(restored.scope, TransactionScope.family);
    expect(restored.minimumPayment, 50);
    expect(restored.isPaid, isFalse);

    final paid = CreditCardStatement.fromJson(
      restored.copyWith(paid: true, paidAt: DateTime(2026, 11, 4)).toJson(),
    );
    expect(paid.isPaid, isTrue);
    expect(paid.copyWith(paid: false).isPaid, isFalse);
  });

  test('rejects minimum amount greater than statement balance', () {
    final data = CreditCardStatement.create(
      cardName: 'Card',
      scope: TransactionScope.personal,
      currency: 'SGD',
      statementAmount: 10,
      minimumPayment: 2,
      dueDate: DateTime(2026, 11, 5),
    ).toJson();
    data['minimumPayment'] = 20;
    expect(() => CreditCardStatement.fromJson(data), throwsFormatException);
  });
}
