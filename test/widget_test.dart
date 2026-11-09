import 'package:flutter_test/flutter_test.dart';
import 'package:byelui/i18n/s.dart';
import 'package:byelui/models/category.dart';
import 'package:byelui/models/transaction.dart';
import 'package:byelui/models/recurring_transaction.dart';
import 'package:byelui/services/credit_card_statement.dart';

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
  group('Recurring schedule dates', () {
    RecurringTransaction makeRecurring(
      DateTime date, RecurrenceFrequency frequency,
    ) => RecurringTransaction(
      id: 'test-rule',
      amount: 10,
      currency: 'SGD',
      type: TransactionType.expense,
      scope: TransactionScope.family,
      categoryId: 'groceries',
      description: 'Test bill',
      frequency: frequency,
      startDate: date,
    );

    test('Jan 31 monthly rule lands in February, not March', () {
      final rule = makeRecurring(
        DateTime(2026, 1, 31, 9), RecurrenceFrequency.monthly,
      );
      final feb = rule.computeNextDate(rule.startDate);
      expect(feb, DateTime(2026, 2, 28, 9));
      expect(rule.computeNextDate(feb), DateTime(2026, 3, 31, 9));
    });

    test('Jan 31 monthly rule uses Feb 29 in a leap year', () {
      final rule = makeRecurring(
        DateTime(2024, 1, 31, 9), RecurrenceFrequency.monthly,
      );
      expect(rule.computeNextDate(rule.startDate), DateTime(2024, 2, 29, 9));
    });

    test('Leap-day yearly rule does not overflow into March', () {
      final rule = makeRecurring(
        DateTime(2024, 2, 29, 9), RecurrenceFrequency.yearly,
      );
      expect(rule.computeNextDate(rule.startDate), DateTime(2025, 2, 28, 9));
    });

    test('Daily and weekly schedules keep their frequency', () {
      final day = makeRecurring(
        DateTime(2026, 11, 9, 9), RecurrenceFrequency.daily,
      );
      final week = makeRecurring(
        DateTime(2026, 11, 9, 9), RecurrenceFrequency.weekly,
      );
      expect(day.computeNextDate(day.startDate), DateTime(2026, 11, 10, 9));
      expect(week.computeNextDate(week.startDate), DateTime(2026, 11, 16, 9));
    });
  });

  group('Credit card statement status', () {
    test('marking paid and unpaid never changes the statement amount', () {
      final statement = CreditCardStatement(
        id: 'statement-1',
        cardName: 'Test card',
        scope: TransactionScope.family,
        currency: 'SGD',
        statementAmount: 250,
        minimumPayment: 50,
        dueDate: DateTime(2026, 11, 30),
      );
      final paid = statement.copyWith(
        paid: true,
        paidAt: DateTime(2026, 11, 9),
      );
      expect(paid.isPaid, isTrue);
      expect(paid.statementAmount, 250);
      expect(paid.scope, TransactionScope.family);
      final unpaid = paid.copyWith(paid: false);
      expect(unpaid.isPaid, isFalse);
      expect(unpaid.statementAmount, 250);
    });
  });

}
