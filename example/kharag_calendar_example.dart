import 'package:kharag_calendar/kharag_calendar.dart';

void main() {
  final today = DateTime.now();
  for (final calendar in [
    KharagCalendar.phugpa(),
    KharagCalendar.bhutan(),
    KharagCalendar.mongol(),
  ]) {
    final date = calendar.fromDate(today);
    print(
      '${calendar.tradition.name}: year ${date.year} '
      '(rabjung ${date.rabjungCycle}, year ${date.rabjungYear}), '
      'month ${date.month}${date.isLeapMonth ? ' (leap)' : ''}, '
      'day ${date.tithi}${date.occ == 2 ? ' (second occurrence)' : ''}',
    );
  }

  // New Year's Day of each tradition.
  print('Losar 2026 (Phugpa): ${KharagCalendar.phugpa().newYearDay(2026)}');
  print('Losar 2026 (Bhutan): ${KharagCalendar.bhutan().newYearDay(2026)}');
  print('Tsagaan Sar 2026:    ${KharagCalendar.mongol().newYearDay(2026)}');

  // Lunar days can be duplicated (two civil days) or skipped (none).
  final bhutan = KharagCalendar.bhutan();
  print(
    'Bhutan 2020 month 2 day 30: '
    '${bhutan.toDates(year: 2020, month: 2, tithi: 30)}',
  );
  final phugpa = KharagCalendar.phugpa();
  print(
    'Phugpa 2012 month 1 day 19: '
    '${phugpa.toDates(year: 2012, month: 1, tithi: 19)}',
  );
}
