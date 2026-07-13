import 'package:flutter_test/flutter_test.dart';
import 'package:home_budget_app/models/daily_expense.dart';
import 'package:home_budget_app/models/bill_reminder.dart';
import 'package:home_budget_app/models/income_source.dart';

void main() {
  group('DailyExpense', () {
    test('round-trip preserves all fields', () {
      final original = DailyExpense(
        id: '123',
        category: 'food',
        amount: 9999,
        date: DateTime(2024, 1, 15, 10, 30),
      );
      final rt = DailyExpense.fromJson(original.toJson());
      expect(rt.id, original.id);
      expect(rt.category, original.category);
      expect(rt.amount, original.amount);
      expect(rt.date, original.date);
    });

    test('amount is stored and read as integer paisa', () {
      final expense = DailyExpense(
        id: '1', category: 'food', amount: 50050, date: DateTime(2024, 1, 1),
      );
      final json = expense.toJson();
      expect(json['amount'], isA<int>());
      expect(json['amount'], 50050);
      expect(DailyExpense.fromJson(json).amount, 50050);
    });

    test('date round-trips via ISO 8601', () {
      final date = DateTime(2024, 6, 15, 14, 30, 0);
      final expense = DailyExpense(id: '1', category: 'food', amount: 100, date: date);
      expect(DailyExpense.fromJson(expense.toJson()).date, date);
    });

    test('zero amount round-trips', () {
      final expense = DailyExpense(id: '1', category: 'other', amount: 0, date: DateTime(2024, 1, 1));
      expect(DailyExpense.fromJson(expense.toJson()).amount, 0);
    });

    test('large amount round-trips without overflow', () {
      final expense = DailyExpense(
        id: '1', category: 'other', amount: 100000000, date: DateTime(2024, 1, 1),
      );
      expect(DailyExpense.fromJson(expense.toJson()).amount, 100000000);
    });
  });

  group('BillReminder', () {
    test('round-trip with amount preserves all fields', () {
      final original = BillReminder(
        id: '456',
        billType: 'electricity',
        dueDate: DateTime(2024, 2, 28),
        amount: 150075,
        isPaid: false,
      );
      final rt = BillReminder.fromJson(original.toJson());
      expect(rt.id, original.id);
      expect(rt.billType, original.billType);
      expect(rt.dueDate, original.dueDate);
      expect(rt.amount, original.amount);
      expect(rt.isPaid, original.isPaid);
    });

    test('null amount round-trips as null', () {
      final original = BillReminder(
        id: '789', billType: 'rent', dueDate: DateTime(2024, 3, 1),
      );
      expect(BillReminder.fromJson(original.toJson()).amount, isNull);
    });

    test('amount is stored and read as integer paisa', () {
      final reminder = BillReminder(
        id: '1', billType: 'gas', dueDate: DateTime(2024, 1, 1), amount: 99999,
      );
      final json = reminder.toJson();
      expect(json['amount'], isA<int>());
      expect(json['amount'], 99999);
    });

    test('isPaid defaults to false', () {
      final reminder = BillReminder(
        id: '1', billType: 'water', dueDate: DateTime(2024, 1, 1),
      );
      expect(reminder.isPaid, isFalse);
    });

    test('isPaid true round-trips correctly', () {
      final original = BillReminder(
        id: '1', billType: 'water', dueDate: DateTime(2024, 1, 1), isPaid: true,
      );
      expect(BillReminder.fromJson(original.toJson()).isPaid, isTrue);
    });

    test('missing isPaid in JSON defaults to false', () {
      final json = {
        'id': '1',
        'billType': 'water',
        'dueDate': '2024-01-01T00:00:00.000',
        'amount': null,
      };
      expect(BillReminder.fromJson(json).isPaid, isFalse);
    });
  });

  group('IncomeSource', () {
    test('round-trip preserves all fields', () {
      final original = IncomeSource(id: '111', type: 'salary', amount: 10000000);
      final rt = IncomeSource.fromJson(original.toJson());
      expect(rt.id, original.id);
      expect(rt.type, original.type);
      expect(rt.amount, original.amount);
    });

    test('amount is stored and read as integer paisa', () {
      final source = IncomeSource(id: '1', type: 'business', amount: 50050);
      final json = source.toJson();
      expect(json['amount'], isA<int>());
      expect(json['amount'], 50050);
    });

    test('zero amount round-trips', () {
      final source = IncomeSource(id: '1', type: 'other', amount: 0);
      expect(IncomeSource.fromJson(source.toJson()).amount, 0);
    });

    test('round-trip with date preserves date', () {
      final date = DateTime(2025, 7, 13, 9, 30);
      final original = IncomeSource(id: '2', type: 'salary', amount: 5000000, date: date);
      final rt = IncomeSource.fromJson(original.toJson());
      expect(rt.date, date);
    });

    test('missing date key in JSON gives null date', () {
      final json = {'id': '3', 'type': 'other', 'amount': 100};
      final source = IncomeSource.fromJson(json);
      expect(source.date, isNull);
    });

    test('list with mixed dated and null-date records loads without error', () {
      final dated = IncomeSource(id: '4', type: 'salary', amount: 1000, date: DateTime(2025, 7, 1));
      final undated = IncomeSource(id: '5', type: 'other', amount: 500);
      final list = [dated.toJson(), undated.toJson()]
          .map(IncomeSource.fromJson)
          .toList();
      expect(list.length, 2);
      expect(list[0].date, isNotNull);
      expect(list[1].date, isNull);
    });
  });
}
