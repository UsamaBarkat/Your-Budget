import 'package:flutter_test/flutter_test.dart';
import 'package:home_budget_app/core/date_utils.dart';

void main() {
  // Reference week: Mon 2024-01-08 … Sun 2024-01-14
  const monday = '2024-01-08';
  const tuesday = '2024-01-09';
  const sunday = '2024-01-14';
  const prevSunday = '2024-01-07';
  const nextMonday = '2024-01-15';

  group('weekStart — FR-B1', () {
    test('Monday returns itself as week start', () {
      expect(weekStart(DateTime.parse(monday)), DateTime.parse(monday));
    });

    test('Sunday returns the Monday of the same week', () {
      expect(weekStart(DateTime.parse(sunday)), DateTime.parse(monday));
    });

    test('mid-week day returns the same Monday', () {
      expect(weekStart(DateTime.parse(tuesday)), DateTime.parse(monday));
    });

    test('previous Sunday returns its own Monday (different week)', () {
      expect(weekStart(DateTime.parse(prevSunday)), DateTime.parse('2024-01-01'));
    });

    test('next Monday is the start of the following week', () {
      expect(weekStart(DateTime.parse(nextMonday)), DateTime.parse(nextMonday));
    });

    test('result is always midnight (00:00:00)', () {
      final result = weekStart(DateTime.parse('2024-01-10T14:30:00'));
      expect(result.hour, 0);
      expect(result.minute, 0);
      expect(result.second, 0);
    });
  });

  group('isSameWeek — FR-B2 (Monday boundary)', () {
    final ref = DateTime.parse(tuesday); // reference day mid-week

    test('Monday of the same week is included', () {
      expect(isSameWeek(DateTime.parse(monday), ref), isTrue);
    });

    test('Sunday of the same week is included', () {
      expect(isSameWeek(DateTime.parse(sunday), ref), isTrue);
    });

    test('the previous Sunday is excluded (it is in the prior week)', () {
      expect(isSameWeek(DateTime.parse(prevSunday), ref), isFalse);
    });

    test('the next Monday is excluded (it starts the following week)', () {
      expect(isSameWeek(DateTime.parse(nextMonday), ref), isFalse);
    });

    test('Monday at 23:59:59 is still included (time stripped)', () {
      final mondayLate = DateTime.parse('${monday}T23:59:59');
      expect(isSameWeek(mondayLate, ref), isTrue);
    });

    test('previous Sunday at 23:59:59 is still excluded (time stripped)', () {
      final prevSundayLate = DateTime.parse('${prevSunday}T23:59:59');
      expect(isSameWeek(prevSundayLate, ref), isFalse);
    });

    test('ref day itself is included', () {
      expect(isSameWeek(ref, ref), isTrue);
    });
  });
}
