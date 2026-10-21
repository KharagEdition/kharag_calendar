import 'package:kharag_calendar/src/julian_day.dart';
import 'package:test/test.dart';

void main() {
  test('gregorianToJdn matches known anchors (JDN of the civil day)', () {
    expect(gregorianToJdn(2000, 1, 1), 2451545);
    expect(gregorianToJdn(1858, 11, 17), 2400001);
    expect(gregorianToJdn(1582, 10, 15), 2299161);
    expect(gregorianToJdn(2026, 10, 21), 2461335);
  });

  test('jdnToGregorian inverts the anchors', () {
    expect(jdnToGregorian(2451545), (year: 2000, month: 1, day: 1));
    expect(jdnToGregorian(2400001), (year: 1858, month: 11, day: 17));
    expect(jdnToGregorian(2299161), (year: 1582, month: 10, day: 15));
    expect(jdnToGregorian(2461335), (year: 2026, month: 10, day: 21));
  });

  test('round-trips every day 1600-2400 and agrees with DateTime', () {
    var jdn = gregorianToJdn(1600, 1, 1);
    final last = gregorianToJdn(2400, 12, 31);
    var dt = DateTime.utc(1600, 1, 1);
    var mismatches = 0;
    for (; jdn <= last; jdn++) {
      final g = jdnToGregorian(jdn);
      if (g != (year: dt.year, month: dt.month, day: dt.day) ||
          gregorianToJdn(g.year, g.month, g.day) != jdn) {
        mismatches++;
      }
      dt = dt.add(const Duration(days: 1));
    }
    expect(mismatches, 0);
    expect(jdn - gregorianToJdn(1600, 1, 1), 292560); // days in 1600..2400
  });
}
