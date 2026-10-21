import 'package:test/test.dart';

import 'support/golden.dart';

/// Phase 0: the golden fixtures generated from caltib exist, decompress and
/// have the shape the later phases rely on.
void main() {
  const traditions = ['phugpa', 'bhutan', 'mongol'];
  const fromYear = 1800;
  const toYear = 2200;
  const expectedDays = 146462; // every day of 1800-01-01 .. 2200-12-31

  test('meta.json records the caltib commit and the range', () {
    final meta = readGoldenMeta();
    expect(meta['caltib_commit'], startsWith('bd15aa9'));
    expect(meta['range'], {'from': fromYear, 'to': toYear});
  });

  for (final t in traditions) {
    final days = 'days_${t}_${fromYear}_$toYear.csv.gz';
    final months = 'months_${t}_${fromYear}_$toYear.csv.gz';

    test('$days has every civil day of the range', () {
      expect(
        goldenHeader(days),
        'date,year,month,is_leap_month,tithi,occ,previous_tithi_skipped,linear_day',
      );
      final rows = readGoldenCsv(days);
      expect(rows.length, expectedDays);
      expect(rows.first.first, '$fromYear-01-01');
      expect(rows.last.first, '$toYear-12-31');
      expect(rows.every((r) => r.length == 8), isTrue);
    });

    test('$months covers every lunation touching the range', () {
      expect(
        goldenHeader(months),
        'n,year,month,leap_state,first_jdn,last_jdn,tithi_end_jdns',
      );
      final rows = readGoldenCsv(months);
      expect(int.parse(rows.first[1]), fromYear - 1);
      expect(int.parse(rows.last[1]), toYear + 2);
      for (var i = 1; i < rows.length; i++) {
        expect(
          int.parse(rows[i][0]),
          int.parse(rows[i - 1][0]) + 1,
          reason: 'lunation indices must be consecutive',
        );
      }
      for (final r in rows) {
        expect(
          r[6].split(' ').length,
          30,
          reason: 'tithi_end_jdns must hold 30 values',
        );
      }
    });
  }

  test('tables.csv.gz has every moon and sun phase', () {
    expect(goldenHeader('tables.csv.gz'), 'table,phase,value_scaled');
    final rows = readGoldenCsv('tables.csv.gz');
    final moon = rows.where((r) => r[0] == 'moon').toList();
    final sun = rows.where((r) => r[0] == 'sun').toList();
    expect(moon.length, 3528);
    expect(sun.length, 4824);
    expect(moon.first[1], '0');
    expect(moon.last[1], '3527');
    expect(sun.last[1], '4823');
  });
}
