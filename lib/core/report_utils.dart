import '../models/daily_expense.dart';
import '../models/income_source.dart';

// Returns a map of day-of-month → total paisa for the same year+month as [now].
// Days with no expenses are absent from the map (not present as zero).
Map<int, int> bucketExpensesByDay(List<DailyExpense> expenses, DateTime now) {
  final result = <int, int>{};
  for (final e in expenses) {
    if (e.date.year == now.year && e.date.month == now.month) {
      result[e.date.day] = (result[e.date.day] ?? 0) + e.amount;
    }
  }
  return result;
}

// Returns total paisa for all income entries in the same year+month as [now].
// Entries with a null date are excluded from the sum.
int sumIncomeForMonth(List<IncomeSource> sources, DateTime now) {
  int total = 0;
  for (final s in sources) {
    if (s.date != null && s.date!.year == now.year && s.date!.month == now.month) {
      total += s.amount;
    }
  }
  return total;
}
