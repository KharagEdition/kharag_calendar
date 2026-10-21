import 'package:kharag_calendar/src/day_engine.dart';
import 'package:kharag_calendar/src/julian_day.dart';
import 'package:kharag_calendar/src/month_engine.dart';
import 'package:kharag_calendar/src/tradition.dart';
import 'package:test/test.dart';

import 'support/golden.dart';

void main() {
  test('dayScale is the lcm of the three equation denominators', () {
    expect(dayScale, 102317040);
    expect(dayScale % meanScale, 0);
    expect(dayScale % (60 * 126), 0); // moon equation: table units x 126 / 60
    expect(dayScale % (60 * 402), 0); // sun equation: table units x 402 / 60
  });

  group('tie cases hardcoded from caltib', () {
    final phugpa = TraditionalDayEngine(Tradition.phugpa.spec);
    final bhutan = TraditionalDayEngine(Tradition.bhutan.spec);
    final phugpaMonths = ArithmeticMonthEngine(Tradition.phugpa.spec);
    final bhutanMonths = ArithmeticMonthEngine(Tradition.bhutan.spec);

    test('Phugpa 2077-07-20: tithi 1 of month 6 covers two dawns', () {
      expect(phugpaMonths.getLunations(2077, 6), [1859]);
      const x = 30 * 1859 + 1; // 55771
      expect(
        [for (var i = -2; i <= 1; i++) phugpa.civilJdn(x + i)],
        [2479868, 2479869, 2479871, 2479872],
      );
      expect(gregorianToJdn(2077, 7, 20), 2479870);
      expect(phugpa.xFromJdn(2479870), x);
      expect(phugpa.xFromJdn(2479871), x);
      expect(phugpa.xFromJdn(2479872), x + 1);
    });

    test('Phugpa 2099-10-14: tithi 30 of month 8 is skipped', () {
      expect(phugpaMonths.getLunations(2099, 9), [2134]);
      const x = 30 * 2134 + 1; // 64021
      expect(
        [for (var i = -2; i <= 1; i++) phugpa.civilJdn(x + i)],
        [2487990, 2487990, 2487991, 2487992],
      );
      expect(gregorianToJdn(2099, 10, 14), 2487991);
      expect(phugpa.xFromJdn(2487990), x - 2);
      expect(phugpa.xFromJdn(2487991), x);
    });

    test('Bhutan 2020-04-22: tithi 30 of month 2 covers two dawns', () {
      expect(bhutanMonths.getLunations(2020, 2), [3289]);
      const x = 30 * 3289 + 30; // 98700
      expect(
        [for (var i = -2; i <= 1; i++) bhutan.civilJdn(x + i)],
        [2458960, 2458961, 2458963, 2458964],
      );
      expect(gregorianToJdn(2020, 4, 22), 2458962);
      expect(bhutan.xFromJdn(2458962), x);
      expect(bhutan.xFromJdn(2458963), x);
      expect(bhutan.xFromJdn(2458964), x + 1);
    });
  });

  for (final t in Tradition.values) {
    final engine = TraditionalDayEngine(t.spec);
    final rows = readGoldenCsv('months_${t.name}_1800_2200.csv.gz');

    test('${t.name}: civilJdn matches every caltib tithi boundary', () {
      var mismatches = 0;
      var checked = 0;
      for (final r in rows) {
        final n = int.parse(r[0]);
        final firstJdn = int.parse(r[4]);
        final lastJdn = int.parse(r[5]);
        final ends = r[6].split(' ').map(int.parse).toList();
        if (engine.civilJdn(30 * n) + 1 != firstJdn) mismatches++;
        if (engine.civilJdn(30 * n + 30) != lastJdn) mismatches++;
        for (var d = 1; d <= 30; d++) {
          if (engine.civilJdn(30 * n + d) != ends[d - 1]) mismatches++;
          checked++;
        }
      }
      expect(mismatches, 0);
      expect(checked, 4986 * 30);
    });

    test('${t.name}: xFromJdn returns the tithi active at every dawn', () {
      var mismatches = 0;
      var checked = 0;
      var previousEnd = engine.civilJdn(30 * int.parse(rows.first[0]));
      for (final r in rows) {
        final n = int.parse(r[0]);
        final ends = r[6].split(' ').map(int.parse).toList();
        for (var d = 1; d <= 30; d++) {
          final x = 30 * n + d;
          for (var jdn = previousEnd + 1; jdn <= ends[d - 1]; jdn++) {
            if (engine.xFromJdn(jdn) != x) mismatches++;
            checked++;
          }
          previousEnd = ends[d - 1];
        }
      }
      expect(mismatches, 0);
      expect(checked, greaterThan(146462));
    });
  }

  test('scaled values stay below 2^53 from year 1000 to 3000', () {
    const limit = 9007199254740992; // 2^53
    for (final t in Tradition.values) {
      final engine = TraditionalDayEngine(t.spec);
      for (final jdn in [
        gregorianToJdn(1000, 1, 1),
        gregorianToJdn(3000, 12, 31),
      ]) {
        final x = engine.xFromJdn(jdn);
        expect(engine.trueDateScaled(x).abs(), lessThan(limit));
        expect(
          engine.meanDateScaled(x).abs() * (dayScale ~/ meanScale),
          lessThan(limit),
        );
        expect(engine.civilJdn(x), greaterThanOrEqualTo(jdn));
        expect(engine.civilJdn(x - 1), lessThan(jdn));
      }
    }
  });
}
