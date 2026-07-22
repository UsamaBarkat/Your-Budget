import 'package:flutter_test/flutter_test.dart';
import 'package:home_budget_app/core/report_utils.dart';
import 'package:home_budget_app/models/daily_expense.dart';
import 'package:home_budget_app/models/income_source.dart';


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

  group('sumIncomeForMonth', () {
    IncomeSource makeIncome(int amount, {int? month, int? year, bool nullDate = false}) =>
        IncomeSource(
          id: 'i_${year ?? 2025}_${month ?? 7}',
          type: 'salary',
          amount: amount,
          date: nullDate ? null : DateTime(year ?? 2025, month ?? 7, 1),
        );

    test('TS-R5: empty list returns zero', () {
      expect(sumIncomeForMonth([], now), 0);
    });

    test('TS-R6: entries from other months and years are excluded', () {
      final sources = [
        makeIncome(50000, month: 6),       // June 2025 — wrong month
        makeIncome(30000, year: 2024),     // July 2024 — wrong year
        makeIncome(45000),                  // July 2025 — matches
      ];
      expect(sumIncomeForMonth(sources, now), 45000);
    });

    test('TS-R7: null-date entries are excluded from the sum', () {
      final sources = [
        makeIncome(100000),                 // dated, matches
        makeIncome(50000, nullDate: true),  // null date — excluded
      ];
      expect(sumIncomeForMonth(sources, now), 100000);
    });

    test('TS-R8: multiple entries in the same month are summed', () {
      final sources = [
        makeIncome(100000),
        makeIncome(80000),
        makeIncome(20000),
      ];
      expect(sumIncomeForMonth(sources, now), 200000);
    });
  });

  group('sumBudgetPaisa', () {
    test('TS-R9: empty map returns zero', () {
      expect(sumBudgetPaisa({}), 0);
    });

    test('TS-R10: multiple categories are summed', () {
      expect(sumBudgetPaisa({'grocery': 500000, 'school': 300000}), 800000);
    });

    test('TS-R11: all-zero categories return zero', () {
      expect(sumBudgetPaisa({'grocery': 0, 'bills': 0}), 0);
    });
  });
}
