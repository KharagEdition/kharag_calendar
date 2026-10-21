import 'package:kharag_calendar/src/month_engine.dart';
import 'package:kharag_calendar/src/tradition.dart';
import 'package:test/test.dart';

import 'support/golden.dart';

void main() {
  group('Janson Table 7 leap months', () {
    final phugpa = ArithmeticMonthEngine(Tradition.phugpa.spec);
    final bhutan = ArithmeticMonthEngine(Tradition.bhutan.spec);

    test('phugpa doubles month 4 of 2016 and month 1 of 2019', () {
      expect(phugpa.isTriggerLabel(2016, 4), isTrue);
      expect(phugpa.isTriggerLabel(2019, 1), isTrue);
      expect(phugpa.isTriggerLabel(2016, 5), isFalse);
      expect(phugpa.isTriggerLabel(2018, 1), isFalse);
      expect(phugpa.getLunations(2016, 4).length, 2);
      expect(phugpa.getLunations(2016, 5).length, 1);
    });

    test('bhutan doubles month 7 of 2016 and month 3 of 2019', () {
      expect(bhutan.isTriggerLabel(2016, 7), isTrue);
      expect(bhutan.isTriggerLabel(2019, 3), isTrue);
      expect(bhutan.isTriggerLabel(2016, 8), isFalse);
    });

    test(
      'a doubled month is two consecutive lunations with states 1 and 2',
      () {
        final pair = phugpa.getLunations(2016, 4);
        expect(pair[1], pair[0] + 1);
        expect(phugpa.labelFromLunation(pair[0]), (
          year: 2016,
          month: 4,
          leapState: 1,
        ));
        expect(phugpa.labelFromLunation(pair[1]), (
          year: 2016,
          month: 4,
          leapState: 2,
        ));
        expect(phugpa.labelFromLunation(pair[0] - 1), (
          year: 2016,
          month: 3,
          leapState: 0,
        ));
        expect(phugpa.labelFromLunation(pair[1] + 1), (
          year: 2016,
          month: 5,
          leapState: 0,
        ));
      },
    );
  });

  for (final t in Tradition.values) {
    final engine = ArithmeticMonthEngine(t.spec);
    final rows = readGoldenCsv('months_${t.name}_1800_2200.csv.gz');

    test('${t.name}: labelFromLunation matches every caltib lunation', () {
      var mismatches = 0;
      for (final r in rows) {
        final n = int.parse(r[0]);
        final expected = (
          year: int.parse(r[1]),
          month: int.parse(r[2]),
          leapState: int.parse(r[3]),
        );
        if (engine.labelFromLunation(n) != expected) mismatches++;
      }
      expect(mismatches, 0);
      expect(rows.length, 4986);
    });

    test('${t.name}: getLunations places every lunation by its leap state', () {
      var mismatches = 0;
      for (final r in rows) {
        final n = int.parse(r[0]);
        final year = int.parse(r[1]);
        final month = int.parse(r[2]);
        final leapState = int.parse(r[3]);
        final lunations = engine.getLunations(year, month);
        final ok = switch (leapState) {
          0 => lunations.length == 1 && lunations[0] == n,
          1 => lunations.length == 2 && lunations[0] == n,
          2 => lunations.length == 2 && lunations[1] == n,
          _ => false,
        };
        if (!ok) mismatches++;
      }
      expect(mismatches, 0);
    });

    test('${t.name}: firstLunation brackets the fixture', () {
      expect(engine.firstLunation(1799), int.parse(rows.first[0]));
      expect(engine.firstLunation(2202), int.parse(rows.last[0]));
      expect(engine.labelFromLunation(engine.firstLunation(2026)).month, 1);
    });
  }
}
