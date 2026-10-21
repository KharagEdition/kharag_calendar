import 'package:kharag_calendar/src/quarter_wave_table.dart';
import 'package:test/test.dart';

import 'support/golden.dart';

const moon = QuarterWaveTable(
  quarter: [0, 5, 10, 15, 19, 22, 24, 25],
  step: 126,
);
const sun = QuarterWaveTable(quarter: [0, 6, 10, 11], step: 402);

void main() {
  test('derives period, turn and amplitude from the quarter table', () {
    expect(moon.period, 28);
    expect(moon.turn, 3528);
    expect(moon.amplitude, 25);
    expect(sun.period, 12);
    expect(sun.turn, 4824);
    expect(sun.amplitude, 11);
  });

  test('evaluates the quarter points with sine symmetry', () {
    expect(moon.evalScaled(0), 0);
    expect(moon.evalScaled(126), 5 * 126);
    expect(moon.evalScaled(882), 25 * 126); // peak at a quarter turn
    expect(moon.evalScaled(1764), 0); // half turn
    expect(moon.evalScaled(2646), -25 * 126); // three quarters
    expect(moon.evalScaled(3528), 0); // full turn wraps
    expect(moon.evalScaled(-882), -25 * 126); // negative phases wrap
    expect(sun.evalScaled(1206), 11 * 402);
    expect(sun.evalScaled(3618), -11 * 402);
  });

  test('interpolates linearly inside a step', () {
    expect(moon.evalScaled(63), 63 * 5); // half way from 0 to 5
    expect(moon.evalScaled(126 + 63), 5 * 126 + 63 * 5);
    expect(moon.evalScaled(1764 - 63), 63 * 5); // mirrored rising edge
    expect(moon.evalScaled(1764 + 63), -63 * 5);
    expect(sun.evalScaled(201), 201 * 6);
  });

  test('matches every caltib table value in tables.csv.gz', () {
    final rows = readGoldenCsv('tables.csv.gz');
    expect(rows.length, 3528 + 4824);
    var mismatches = 0;
    for (final r in rows) {
      final table = r[0] == 'moon' ? moon : sun;
      if (table.evalScaled(int.parse(r[1])) != int.parse(r[2])) mismatches++;
    }
    expect(mismatches, 0);
  });
}
