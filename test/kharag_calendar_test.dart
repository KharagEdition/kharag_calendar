import 'package:kharag_calendar/kharag_calendar.dart';
import 'package:test/test.dart';

void main() {
  final phugpa = KharagCalendar.phugpa();
  final bhutan = KharagCalendar.bhutan();
  final mongol = KharagCalendar.mongol();

  group('fromDate', () {
    test('returns Losar 2026 for 18 February 2026 (Phugpa and Bhutan)', () {
      for (final cal in [phugpa, bhutan]) {
        final d = cal.fromDate(DateTime(2026, 2, 18));
        expect((d.year, d.month, d.isLeapMonth, d.tithi), (2026, 1, false, 1));
        expect(d.tradition, cal.tradition);
      }
    });

    test('returns Tsagaan Sar 2025 for 1 March 2025 (Mongol)', () {
      // In 2025 the first lunar day of the Mongolian year is skipped, so
      // New Year's Day is labeled day 2 (as in caltib).
      final d = mongol.fromYmd(2025, 3, 1);
      expect((d.year, d.month, d.tithi, d.linearDay), (2025, 1, 2, 1));
      expect(d.previousTithiSkipped, isTrue);
      expect(mongol.toDates(year: 2025, month: 1, tithi: 1), isEmpty);
    });

    test('uses the civil date only, ignoring time of day and zone', () {
      final expected = phugpa.fromYmd(2026, 2, 18);
      expect(phugpa.fromDate(DateTime(2026, 2, 18)), expected);
      expect(phugpa.fromDate(DateTime.utc(2026, 2, 18)), expected);
      expect(phugpa.fromDate(DateTime(2026, 2, 18, 23, 59, 59)), expected);
      expect(phugpa.fromDate(DateTime.utc(2026, 2, 18, 0, 0, 1)), expected);
    });

    test('fromJdn agrees with fromYmd', () {
      expect(
        phugpa.fromJdn(gregorianToJdn(2026, 2, 18)),
        phugpa.fromYmd(2026, 2, 18),
      );
    });

    test('rejects civil days outside the supported range', () {
      // 1000-01-01 still belongs to calendar year 999 (Losar 1000 is later).
      expect(() => phugpa.fromYmd(1000, 1, 1), throwsArgumentError);
      expect(() => phugpa.fromYmd(999, 12, 31), throwsArgumentError);
      expect(
        () => phugpa.fromJdn(gregorianToJdn(999, 12, 31)),
        throwsArgumentError,
      );
      // 3001-01-01 is still calendar year 3000 (Losar 3001 is later).
      expect(phugpa.fromYmd(3001, 1, 1).year, 3000);
      expect(phugpa.fromYmd(3000, 12, 31).year, 3000);
      expect(() => phugpa.fromYmd(3002, 1, 1), throwsArgumentError);
    });

    test('the jdn range error names the jdn and the allowed range', () {
      final first = dateTimeToJdn(phugpa.firstSupportedDate);
      final last = dateTimeToJdn(phugpa.lastSupportedDate);
      expect(
        () => phugpa.fromJdn(0),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.toString(),
            'message',
            allOf(
              contains('jdn'),
              contains(': 0'),
              contains('$first'),
              contains('$last'),
            ),
          ),
        ),
      );
    });

    test('rejects invalid civil dates', () {
      expect(() => phugpa.fromYmd(2026, 13, 1), throwsArgumentError);
      expect(() => phugpa.fromYmd(2026, 2, 30), throwsArgumentError);
      expect(() => phugpa.fromYmd(2026, 0, 1), throwsArgumentError);
    });
  });

  group('toDates and toDate', () {
    test('a normal lunar day maps to one civil day (UTC midnight)', () {
      expect(phugpa.toDates(year: 2026, month: 1, tithi: 1), [
        DateTime.utc(2026, 2, 18),
      ]);
      expect(
        phugpa.toDate(year: 2026, month: 1, tithi: 1),
        DateTime.utc(2026, 2, 18),
      );
    });

    test('a duplicated lunar day maps to two civil days', () {
      // Bhutan 2020, month 2, day 30 covers 22 and 23 April 2020.
      expect(bhutan.toDates(year: 2020, month: 2, tithi: 30), [
        DateTime.utc(2020, 4, 22),
        DateTime.utc(2020, 4, 23),
      ]);
      expect(
        bhutan.toDate(year: 2020, month: 2, tithi: 30),
        DateTime.utc(2020, 4, 22),
      );
      expect(
        bhutan.toDate(year: 2020, month: 2, tithi: 30, occ: 2),
        DateTime.utc(2020, 4, 23),
      );
      expect(bhutan.fromYmd(2020, 4, 23).occ, 2);
    });

    test('a skipped lunar day maps to no civil day', () {
      // Janson Table 8: Phugpa 2012 month 1 skips day 19.
      expect(phugpa.toDates(year: 2012, month: 1, tithi: 19), isEmpty);
      expect(phugpa.toDate(year: 2012, month: 1, tithi: 19), isNull);
      expect(phugpa.fromYmd(2012, 3, 11).tithi, 18);
      final after = phugpa.fromYmd(2012, 3, 12);
      expect(after.tithi, 20);
      expect(after.previousTithiSkipped, isTrue);
    });

    test('occ beyond the last occurrence clamps to the last one', () {
      expect(
        phugpa.toDate(year: 2026, month: 1, tithi: 1, occ: 2),
        DateTime.utc(2026, 2, 18),
      );
    });

    test('leap months are addressed with isLeapMonth', () {
      // Janson Table 7: Phugpa doubles month 4 of 2016, leap month first.
      expect(
        phugpa.toDate(year: 2016, month: 4, isLeapMonth: true, tithi: 1),
        DateTime.utc(2016, 5, 7),
      );
      expect(
        phugpa.toDate(year: 2016, month: 4, tithi: 1),
        DateTime.utc(2016, 6, 6),
      );
      // Bhutan doubles month 7 of 2016, leap month second.
      expect(
        bhutan.toDate(year: 2016, month: 7, isLeapMonth: true, tithi: 1),
        DateTime.utc(2016, 9, 2),
      );
      // Day 1 of the following month 8 is duplicated (1 and 2 October).
      expect(bhutan.toDates(year: 2016, month: 8, tithi: 1), [
        DateTime.utc(2016, 10, 1),
        DateTime.utc(2016, 10, 2),
      ]);
    });

    test('toDateOf inverts fromDate, keeping the occurrence', () {
      for (final cal in [phugpa, bhutan, mongol]) {
        for (final day in [
          DateTime.utc(2020, 4, 22),
          DateTime.utc(2020, 4, 23),
          DateTime.utc(2026, 2, 18),
          DateTime.utc(1850, 7, 4),
          DateTime.utc(2150, 11, 30),
        ]) {
          expect(
            cal.toDateOf(cal.fromDate(day)),
            day,
            reason: '${cal.tradition} $day',
          );
        }
      }
    });

    test('rejects out-of-range components', () {
      expect(
        () => phugpa.toDates(year: 2026, month: 0, tithi: 1),
        throwsArgumentError,
      );
      expect(
        () => phugpa.toDates(year: 2026, month: 13, tithi: 1),
        throwsArgumentError,
      );
      expect(
        () => phugpa.toDates(year: 2026, month: 1, tithi: 0),
        throwsArgumentError,
      );
      expect(
        () => phugpa.toDates(year: 2026, month: 1, tithi: 31),
        throwsArgumentError,
      );
      expect(
        () => phugpa.toDate(year: 2026, month: 1, tithi: 1, occ: 0),
        throwsArgumentError,
      );
      expect(
        () => phugpa.toDate(year: 2026, month: 1, tithi: 1, occ: 3),
        throwsArgumentError,
      );
      expect(
        () => phugpa.toDates(year: 999, month: 1, tithi: 1),
        throwsArgumentError,
      );
      expect(
        () => phugpa.toDates(year: 3001, month: 1, tithi: 1),
        throwsArgumentError,
      );
      expect(
        () => phugpa.toDates(year: 2016, month: 5, isLeapMonth: true, tithi: 1),
        throwsArgumentError,
      );
    });
  });

  group('years and months', () {
    test('newYearDay', () {
      expect(phugpa.newYearDay(2026), DateTime.utc(2026, 2, 18));
      expect(bhutan.newYearDay(2011), DateTime.utc(2011, 2, 3));
      expect(mongol.newYearDay(2025), DateTime.utc(2025, 3, 1));
      expect(() => phugpa.newYearDay(999), throwsArgumentError);
    });

    test('monthBounds exposes civil dates', () {
      final b = phugpa.monthBounds(2026, 1);
      expect(b.firstDate, DateTime.utc(2026, 2, 18));
      expect(b.lastDate, phugpa.toDates(year: 2026, month: 1, tithi: 30).last);
      expect(b.lastDate.isBefore(phugpa.newYearDay(2027)), isTrue);
      expect(() => phugpa.monthBounds(2026, 13), throwsArgumentError);
      expect(
        () => phugpa.monthBounds(2026, 1, isLeapMonth: true),
        throwsArgumentError,
      );
    });
  });

  group('TibetanDate rabjung', () {
    TibetanDate at(int year) => TibetanDate(
      tradition: Tradition.phugpa,
      year: year,
      month: 1,
      isLeapMonth: false,
      tithi: 1,
    );

    test('2026 is year 40 of the 17th rabjung', () {
      expect((at(2026).rabjungCycle, at(2026).rabjungYear), (17, 40));
    });

    test('cycle boundaries use floor semantics like caltib', () {
      expect((at(1027).rabjungCycle, at(1027).rabjungYear), (1, 1));
      expect((at(1086).rabjungCycle, at(1086).rabjungYear), (1, 60));
      expect((at(1087).rabjungCycle, at(1087).rabjungYear), (2, 1));
      expect((at(1026).rabjungCycle, at(1026).rabjungYear), (0, 60));
    });
  });

  test('public exports', () {
    expect(Tradition.values.length, 3);
    expect(KharagCalendar(Tradition.mongol).tradition, Tradition.mongol);
    expect(jdnToGregorian(gregorianToJdn(2026, 10, 21)), (
      year: 2026,
      month: 10,
      day: 21,
    ));
    expect(dateTimeToJdn(DateTime(2026, 10, 21, 23, 30)), 2461335);
    expect(jdnToDateTime(2461335), DateTime.utc(2026, 10, 21));
  });

  test(
    'leapMonthComesFirst tells which month of a doubled pair is the leap one',
    () {
      expect(Tradition.phugpa.leapMonthComesFirst, isTrue);
      expect(Tradition.mongol.leapMonthComesFirst, isTrue);
      expect(Tradition.bhutan.leapMonthComesFirst, isFalse);
    },
  );

  group('supported range is closed under both directions', () {
    for (final cal in [phugpa, bhutan, mongol]) {
      final name = cal.tradition.name;
      final first = cal.firstSupportedDate;
      final last = cal.lastSupportedDate;

      test(
        '$name: the range is Losar 1000 up to the day before Losar 3001',
        () {
          expect(first, cal.newYearDay(KharagCalendar.minYear));
          final firstDate = cal.fromDate(first);
          expect((firstDate.year, firstDate.linearDay), (1000, 1));
          expect(cal.fromDate(last).year, 3000);
          expect(
            () => cal.fromDate(first.subtract(const Duration(days: 1))),
            throwsArgumentError,
          );
          expect(
            () => cal.fromDate(last.add(const Duration(days: 1))),
            throwsArgumentError,
          );
          expect(
            () => cal.newYearDay(KharagCalendar.maxYear + 1),
            throwsArgumentError,
          );
        },
      );

      test('$name: every day in the first and last 90 days round-trips', () {
        for (var i = 0; i < 90; i++) {
          for (final day in [
            first.add(Duration(days: i)),
            last.subtract(Duration(days: i)),
          ]) {
            final date = cal.fromDate(day);
            expect(cal.toDateOf(date), day, reason: '$name $day');
            expect(
              cal.toDates(
                year: date.year,
                month: date.month,
                isLeapMonth: date.isLeapMonth,
                tithi: date.tithi,
              ),
              contains(day),
              reason: '$name $day',
            );
            final bounds = cal.monthBounds(
              date.year,
              date.month,
              isLeapMonth: date.isLeapMonth,
            );
            expect(bounds.firstDate.isAfter(day), isFalse);
            expect(bounds.lastDate.isBefore(day), isFalse);
          }
        }
      });

      test('$name: the last lunar days of year 3000 convert back', () {
        final lastDate = cal.fromDate(last);
        final tail = cal.toDates(
          year: lastDate.year,
          month: lastDate.month,
          isLeapMonth: lastDate.isLeapMonth,
          tithi: 30,
        );
        expect(tail, isNotEmpty);
        expect(tail.last, last);
        for (final day in tail) {
          expect(cal.fromDate(day).year, 3000);
        }
      });
    }

    test('phugpa: month 12 day 30 of year 3000 is the last supported day', () {
      final tail = phugpa.toDates(year: 3000, month: 12, tithi: 30);
      expect(tail, [phugpa.lastSupportedDate]);
      expect(phugpa.fromDate(tail.last).tithi, 30);
    });
  });

  group('toDateOf errors', () {
    test('rejects a date of another tradition', () {
      final date = bhutan.fromYmd(2026, 2, 18);
      expect(
        () => phugpa.toDateOf(date),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.toString(),
            'message',
            contains('bhutan'),
          ),
        ),
      );
    });

    test('rejects a skipped lunar day', () {
      const skipped = TibetanDate(
        tradition: Tradition.phugpa,
        year: 2012,
        month: 1,
        isLeapMonth: false,
        tithi: 19,
      );
      expect(
        () => phugpa.toDateOf(skipped),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.toString(),
            'message',
            contains('skipped'),
          ),
        ),
      );
    });
  });
}
