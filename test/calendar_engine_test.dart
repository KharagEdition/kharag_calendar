import 'package:kharag_calendar/src/calendar_engine.dart';
import 'package:kharag_calendar/src/julian_day.dart';
import 'package:kharag_calendar/src/tibetan_date.dart';
import 'package:kharag_calendar/src/tradition.dart';
import 'package:test/test.dart';

import 'support/golden.dart';

int jdnOfIso(String iso) => gregorianToJdn(
  int.parse(iso.substring(0, 4)),
  int.parse(iso.substring(5, 7)),
  int.parse(iso.substring(8, 10)),
);

/// caltib's leap flag for a lunation's leap_state under a leap labeling.
bool isLeapFor(LeapLabeling labeling, int leapState) => switch (leapState) {
  1 => labeling == LeapLabeling.firstIsLeap,
  2 => labeling == LeapLabeling.secondIsLeap,
  _ => false,
};

void main() {
  for (final t in Tradition.values) {
    final engine = CalendarEngine(t);
    final days = readGoldenCsv('days_${t.name}_1800_2200.csv.gz');
    final months = readGoldenCsv('months_${t.name}_1800_2200.csv.gz');
    final firstJdn = jdnOfIso(days.first[0]);
    final lastJdn = jdnOfIso(days.last[0]);

    test(
      '${t.name}: fromJdn equals caltib day_info on every day 1800-2200',
      () {
        var mismatches = 0;
        var checked = 0;
        TibetanDate? firstMismatch;
        for (final r in days) {
          final expected = TibetanDate(
            tradition: t,
            year: int.parse(r[1]),
            month: int.parse(r[2]),
            isLeapMonth: r[3] == '1',
            tithi: int.parse(r[4]),
            occ: int.parse(r[5]),
            previousTithiSkipped: r[6] == '1',
            linearDay: int.parse(r[7]),
          );
          final actual = engine.fromJdn(jdnOfIso(r[0]));
          if (actual != expected) {
            mismatches++;
            firstMismatch ??= actual;
          }
          checked++;
        }
        expect(mismatches, 0, reason: 'first mismatch: $firstMismatch');
        expect(checked, 146462);
      },
    );

    test('${t.name}: toJdn equals every caltib tithi end', () {
      var mismatches = 0;
      for (final r in months) {
        final year = int.parse(r[1]);
        final month = int.parse(r[2]);
        final leap = isLeapFor(t.spec.leapLabeling, int.parse(r[3]));
        final ends = r[6].split(' ').map(int.parse).toList();
        for (var d = 1; d <= 30; d++) {
          if (engine.toJdn(year, month, leap, d) != ends[d - 1]) mismatches++;
        }
      }
      expect(mismatches, 0);
    });

    test(
      '${t.name}: jdnsOf returns exactly the civil days carrying a label',
      () {
        var mismatches = 0;
        var skipped = 0;
        var duplicated = 0;
        for (final r in months) {
          final year = int.parse(r[1]);
          final month = int.parse(r[2]);
          final leap = isLeapFor(t.spec.leapLabeling, int.parse(r[3]));
          final ends = r[6].split(' ').map(int.parse).toList();
          var previousEnd = int.parse(r[4]) - 1; // first_jdn - 1 == J(30n)
          for (var d = 1; d <= 30; d++) {
            final expected = [
              for (var j = previousEnd + 1; j <= ends[d - 1]; j++) j,
            ];
            if (expected.isEmpty) skipped++;
            if (expected.length == 2) duplicated++;
            final actual = engine.jdnsOf(year, month, leap, d);
            if (actual.length != expected.length ||
                !actual.asMap().entries.every(
                  (e) => expected[e.key] == e.value,
                )) {
              mismatches++;
            }
            previousEnd = ends[d - 1];
          }
        }
        expect(mismatches, 0);
        expect(skipped, greaterThan(0));
        expect(duplicated, greaterThan(0));
      },
    );

    test('${t.name}: jdnOf picks the occurrence and clamps it', () {
      var mismatches = 0;
      for (final r in days) {
        final jdn = jdnOfIso(r[0]);
        final year = int.parse(r[1]);
        final month = int.parse(r[2]);
        final leap = r[3] == '1';
        final tithi = int.parse(r[4]);
        final occ = int.parse(r[5]);
        if (engine.jdnOf(year, month, leap, tithi, occ: occ) != jdn) {
          mismatches++;
        }
        // caltib clamps occ with min(occ - 1, len - 1).
        if (occ == 1 &&
            engine.jdnsOf(year, month, leap, tithi).length == 1 &&
            engine.jdnOf(year, month, leap, tithi, occ: 2) != jdn) {
          mismatches++;
        }
      }
      expect(mismatches, 0);
    });

    test('${t.name}: newYearJdn is the first day labeled with the year', () {
      final firstDayOfYear = <int, int>{};
      for (final r in days) {
        firstDayOfYear.putIfAbsent(int.parse(r[1]), () => jdnOfIso(r[0]));
      }
      var mismatches = 0;
      for (var y = 1801; y <= 2199; y++) {
        if (engine.newYearJdn(y) != firstDayOfYear[y]) mismatches++;
      }
      expect(mismatches, 0);
    });

    test('${t.name}: monthBounds equals caltib month_bounds', () {
      var mismatches = 0;
      for (final r in months) {
        final n = int.parse(r[0]);
        final year = int.parse(r[1]);
        final month = int.parse(r[2]);
        final leap = isLeapFor(t.spec.leapLabeling, int.parse(r[3]));
        final b = engine.monthBounds(year, month, isLeapMonth: leap);
        if (b.lunation != n ||
            b.firstJdn != int.parse(r[4]) ||
            b.lastJdn != int.parse(r[5]) ||
            b.year != year ||
            b.month != month ||
            b.isLeapMonth != leap) {
          mismatches++;
        }
      }
      expect(mismatches, 0);
    });

    test('${t.name}: every fixture day round-trips through jdnsOf', () {
      var mismatches = 0;
      for (final r in days) {
        final jdn = jdnOfIso(r[0]);
        if (jdn == firstJdn || jdn == lastJdn) continue;
        final d = engine.fromJdn(jdn);
        final back = engine.jdnsOf(d.year, d.month, d.isLeapMonth, d.tithi);
        if (back.length < d.occ || back[d.occ - 1] != jdn) mismatches++;
      }
      expect(mismatches, 0);
    });
  }

  group('published new year dates (external cross-checks)', () {
    void expectNewYear(Tradition t, int year, int m, int d) {
      expect(
        jdnToGregorian(CalendarEngine(t).newYearJdn(year)),
        (year: year, month: m, day: d),
        reason: '${t.name} $year',
      );
    }

    test('Phugpa Losar, Janson Table 9', () {
      const table = {
        2000: (2, 6),
        2001: (2, 24),
        2002: (2, 13),
        2003: (3, 3),
        2004: (2, 21),
        2005: (2, 9),
        2006: (2, 28),
        2007: (2, 18),
        2008: (2, 7),
        2009: (2, 25),
        2010: (2, 14),
        2011: (3, 5),
        2012: (2, 22),
        2013: (2, 11),
        2014: (3, 2),
        2015: (2, 19),
        2016: (2, 9),
        2017: (2, 27),
        2018: (2, 16),
        2019: (2, 5),
        2020: (2, 24),
        2021: (2, 12),
        2022: (3, 3),
        2023: (2, 21),
        2024: (2, 10),
        2025: (2, 28),
        2026: (2, 18),
        2027: (2, 7),
        2028: (2, 26),
        2029: (2, 14),
        2030: (3, 5),
      };
      table.forEach(
        (y, md) => expectNewYear(Tradition.phugpa, y, md.$1, md.$2),
      );
    });

    test('Bhutan Losar, Janson Table 9 and official holiday lists', () {
      const table = {
        2000: (2, 6),
        2001: (2, 24),
        2002: (2, 13),
        2003: (3, 4),
        2004: (2, 21),
        2005: (2, 9),
        2006: (2, 28),
        2007: (2, 18),
        2008: (2, 8),
        2009: (2, 25),
        2010: (2, 14),
        2011: (2, 3),
        2012: (2, 22),
        2013: (2, 11),
        2014: (3, 2),
        2015: (2, 19),
        2016: (2, 9),
        2017: (2, 27),
        2018: (2, 16),
        2019: (2, 5),
        2020: (2, 24),
        2021: (2, 12),
        2022: (3, 3),
        2023: (2, 21),
        2024: (2, 10),
        2025: (2, 28),
        2026: (2, 18),
        2027: (2, 7),
        2028: (2, 26),
        2029: (2, 14),
        2030: (2, 3),
      };
      table.forEach(
        (y, md) => expectNewYear(Tradition.bhutan, y, md.$1, md.$2),
      );
    });

    test('Mongol Tsagaan Sar, Janson Table 9 and Wikipedia 2019-2026', () {
      const table = {
        2000: (2, 6),
        2003: (2, 2),
        2006: (1, 30),
        2008: (2, 8),
        2011: (2, 3),
        2014: (1, 31),
        2019: (2, 5),
        2020: (2, 24),
        2021: (2, 12),
        2022: (2, 2),
        2023: (2, 21),
        2024: (2, 10),
        2025: (3, 1),
        2026: (2, 18),
        2030: (2, 3),
      };
      table.forEach(
        (y, md) => expectNewYear(Tradition.mongol, y, md.$1, md.$2),
      );
    });
  });

  test('a leap flag on a month that is not doubled is rejected', () {
    final engine = CalendarEngine(Tradition.phugpa);
    expect(() => engine.toJdn(2016, 5, true, 1), throwsArgumentError);
    expect(() => engine.jdnsOf(2016, 5, true, 1), throwsArgumentError);
    expect(
      engine.toJdn(2016, 4, true, 1),
      lessThan(engine.toJdn(2016, 4, false, 1)),
    );
  });

  test('TibetanDate equality covers every field', () {
    // The golden gate compares whole TibetanDate values, so == must compare
    // all eight fields; changing any one of them must break equality.
    const a = TibetanDate(
      tradition: Tradition.phugpa,
      year: 2026,
      month: 1,
      isLeapMonth: false,
      tithi: 1,
      occ: 1,
      previousTithiSkipped: false,
      linearDay: 1,
    );
    expect(a, a.copyWith());
    expect(a.hashCode, a.copyWith().hashCode);
    final variants = {
      'tradition': a.copyWith(tradition: Tradition.bhutan),
      'year': a.copyWith(year: 2027),
      'month': a.copyWith(month: 2),
      'isLeapMonth': a.copyWith(isLeapMonth: true),
      'tithi': a.copyWith(tithi: 2),
      'occ': a.copyWith(occ: 2),
      'previousTithiSkipped': a.copyWith(previousTithiSkipped: true),
      'linearDay': a.copyWith(linearDay: 2),
    };
    expect(variants.length, 8);
    variants.forEach((field, b) {
      expect(a == b, isFalse, reason: '== ignores $field');
    });
    expect(a.toString(), contains('phugpa'));
  });
}
