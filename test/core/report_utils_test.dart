import 'package:flutter_test/flutter_test.dart';
import 'package:home_budget_app/core/report_utils.dart';
import 'package:home_budget_app/models/daily_expense.dart';

void main() {
  final now = DateTime(2025, 7, 15);

  DailyExpense makeExpense(int day, int amount, {int? month, int? year, String? id}) =>
      DailyExpense(
        id: id ?? 'e_${year ?? 2025}_${month ?? 7}_$day',
        category: 'food',
        amount: amount,
        date: DateTime(year ?? 2025, month ?? 7, day),
      );

  group('bucketExpensesByDay', () {
    test('TS-R1: empty list returns empty map without crashing', () {
      expect(bucketExpensesByDay([], now), isEmpty);
    });

    test('TS-R2: entries from other months and years are excluded', () {
      final expenses = [
        makeExpense(1, 500, month: 6),          // June 2025 — wrong month
        makeExpense(1, 1000, year: 2024),        // July 2024 — wrong year
        makeExpense(15, 200),                    // July 2025 — matches
      ];
      final result = bucketExpensesByDay(expenses, now);
      expect(result.length, 1);
      expect(result[15], 200);
    });

    test('TS-R3: multiple entries on the same day are summed, not overwritten', () {
      final expenses = [
        makeExpense(5, 100, id: 'a'),
        makeExpense(5, 250, id: 'b'),
        makeExpense(5, 50, id: 'c'),
      ];
      final result = bucketExpensesByDay(expenses, now);
      expect(result[5], 400);
    });

    test('TS-R4: single entry produces a map with one key and correct value', () {
      final expenses = [makeExpense(10, 750)];
      final result = bucketExpensesByDay(expenses, now);
      expect(result.length, 1);
      expect(result[10], 750);
    });
  });
}
