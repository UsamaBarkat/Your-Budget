/// Returns the Monday 00:00:00 of the week that contains [date].
/// Monday is treated as the first day of the week (Dart weekday: 1=Mon, 7=Sun).
DateTime weekStart(DateTime date) {
  final daysFromMonday = date.weekday - DateTime.monday;
  final monday = date.subtract(Duration(days: daysFromMonday));
  return DateTime(monday.year, monday.month, monday.day);
}

/// Returns true if [date] falls within the same Monday-to-Sunday week as [ref].
bool isSameWeek(DateTime date, DateTime ref) {
  final start = weekStart(ref);
  final end = start.add(const Duration(days: 7));
  final d = DateTime(date.year, date.month, date.day);
  return !d.isBefore(start) && d.isBefore(end);
}
