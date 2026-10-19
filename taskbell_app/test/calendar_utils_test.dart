import 'package:flutter_test/flutter_test.dart';
import 'package:taskbell_app/core/utils/calendar_utils.dart';

void main() {
  group('Calendar utils', () {
    test('daysInMonth handles regular and leap years', () {
      expect(daysInMonth(2026, 2), 28);
      expect(daysInMonth(2028, 2), 29);
      expect(daysInMonth(2026, 4), 30);
      expect(daysInMonth(2026, 12), 31);
    });

    test('month and weekday names are Indonesian', () {
      expect(monthName(1), 'Januari');
      expect(monthName(10), 'Oktober');
      expect(weekdayLabel(DateTime.monday), 'Sen');
      expect(weekdayLabel(DateTime.sunday), 'Min');
    });

    test('grid starts on Monday and aligns the first day', () {
      // 1 Oktober 2026 adalah hari Kamis.
      final grid = buildMonthGrid(2026, 10);

      expect(grid.first.length, 7);
      expect(grid.first[DateTime.thursday - 1], DateTime(2026, 10, 1));
      expect(grid.first.take(3).every((day) => day == null), isTrue);
      expect(grid.last.length, 7);
    });

    test('grid contains every day exactly once', () {
      final grid = buildMonthGrid(2026, 2);
      final days = grid.expand((week) => week).whereType<DateTime>().toList();

      expect(days.length, 28);
      expect(days.first, DateTime(2026, 2, 1));
      expect(days.last, DateTime(2026, 2, 28));
      expect(days.map((day) => day.day).toSet().length, 28);
    });

    test('dayKey removes the time component', () {
      final key = dayKey(DateTime(2026, 10, 20, 23, 59, 59));

      expect(key, DateTime(2026, 10, 20));
      expect(key.hour, 0);
    });

    test('formatTime pads single digit values', () {
      expect(formatTime(DateTime(2026, 10, 20, 9, 5)), '09:05');
      expect(formatTime(DateTime(2026, 10, 20, 23, 59)), '23:59');
    });
  });
}
