import 'package:flutter_test/flutter_test.dart';
import 'package:byelui/i18n/s.dart';
import 'package:byelui/models/category.dart';
import 'package:byelui/models/transaction.dart';

void main() {
  group('Billing dates', () {
    test('display day-month with leading zeros and no year', () {
      expect(S.billingDate(DateTime(2026, 3, 5)), '05-03');
      expect(S.billingDate(DateTime(2026, 11, 28)), '28-11');
    });
  });

  group('Transaction model', () {
    late Transaction expense;

    setUp(() {
      expense = Transaction(
        id: 'test-expense',
        amount: 12.50,
        currency: 'SGD',
        type: TransactionType.expense,
        scope: TransactionScope.personal,
        categoryId: 'groceries',
        date: DateTime(2026, 11, 9),
        description: 'Lunch',
        tags: ['Food'],
        createdAt: DateTime(2026, 11, 9),
        updatedAt: DateTime(2026, 11, 9),
      );
    });

    test('expense is negative, income is positive in cash-flow totals', () {
      expect(expense.signedAmount, -12.50);
      expect(expense.copyWith(type: TransactionType.income).signedAmount, 12.50);
    });

    test('switching Personal to Family preserves existing entry fields', () {
      final familyExpense = expense.copyWith(scope: TransactionScope.family);
      expect(familyExpense.scope, TransactionScope.family);
      expect(familyExpense.amount, 12.50);
      expect(familyExpense.description, 'Lunch');
      expect(familyExpense.tags, ['Food']);
    });

    test('clearing optional receipt and notes does not discard other fields', () {
      final entry = expense.copyWith(note: 'Receipt', photoPath: '/tmp/receipt.jpg');
      final cleared = entry.copyWith(clearPhoto: true, clearNote: true);
      expect(cleared.photoPath, isNull);
      expect(cleared.note, isNull);
      expect(cleared.categoryId, 'groceries');
    });
  });
}
