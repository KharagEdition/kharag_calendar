/// Exact fixed-point evaluation of the traditional sine-like lookup tables.
///
/// Mirrors `QuarterWaveTable.eval_u` in caltib's `engines/astro/tables.py`.
/// A table lists one quarter wave (0 up to the peak); the other three
/// quarters follow by mirroring and sign flip, like a sine. Values between
/// grid points are linearly interpolated.
library;

import 'int_math.dart';

/// A quarter-wave periodic table evaluated with exact integer arithmetic.
///
/// The full period has [period] `= 4 * (quarter.length - 1)` grid steps.
/// A phase is given as an integer number of `1 / turn` of a full period,
/// where [turn] `= period * step`, so one grid step spans [step] phase units
/// and interpolation inside a step is exact when the result is scaled by
/// [step].
final class QuarterWaveTable {
  /// Creates a table from its rising quarter wave, `quarter[0]` being the
  /// value at phase 0 and `quarter.last` the peak at a quarter turn.
  const QuarterWaveTable({required this.quarter, required this.step});

  /// Table values from phase 0 to the peak, one per grid step.
  final List<int> quarter;

  /// Phase units per grid step.
  final int step;

  /// Grid steps in a full period (caltib's `N`).
  int get period => 4 * (quarter.length - 1);

  /// Phase units in a full period.
  int get turn => period * step;

  /// The peak value, reached at a quarter turn.
  int get amplitude => quarter.last;

  /// Evaluates the table at [phase] (in `1 / turn` units, any integer) and
  /// returns the interpolated value multiplied by [step].
  int evalScaled(int phase) {
    var p = floorMod(phase, turn);
    var sign = 1;
    final half = turn ~/ 2;
    if (p > half) {
      sign = -1;
      p = turn - p;
    }
    final quarterTurn = turn ~/ 4;
    if (p > quarterTurn) {
      p = half - p;
    }
    final i = p ~/ step; // p >= 0 here, so truncation is floor
    if (i >= period ~/ 4) {
      return sign * amplitude * step;
    }
    final t = p - i * step;
    final v0 = quarter[i];
    final v1 = quarter[i + 1];
    return sign * (v0 * step + t * (v1 - v0));
  }
}
