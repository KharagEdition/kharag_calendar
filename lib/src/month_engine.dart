/// Discrete arithmetic mapping (year, month) labels to lunation indices and
/// back, with leap-month detection.
///
/// Mirrors `ArithmeticMonthEngine` in caltib's `engines/arithmetic_month.py`.
/// Lunation index `n = 0` is the epoch new moon of the tradition.
library;

import 'int_math.dart';
import 'tradition.dart';

/// A year, month and leap state (0 regular, 1 first of a doubled pair,
/// 2 second of a doubled pair) as caltib's `label_from_lunation` returns.
typedef MonthLabel = ({int year, int month, int leapState});

/// Converts between calendar month labels and lunation indices.
final class ArithmeticMonthEngine {
  /// Creates the month engine for [spec].
  const ArithmeticMonthEngine(this.spec);

  /// The tradition's constants.
  final TraditionSpec spec;

  /// Months elapsed from the epoch label to ([year], [month]) (caltib `mstar`).
  int mstar(int year, int month) =>
      12 * (year - spec.y0) + (month - TraditionSpec.epochMonth);

  /// Whether the label ([year], [month]) is carried by two lunations.
  bool isTriggerLabel(int year, int month) =>
      floorMod(spec.ell * mstar(year, month) + spec.betaInt, TraditionSpec.p) <
      spec.ell;

  /// The right-end lunation attached to ([year], [month]) (caltib `n_plus`).
  int nPlus(int year, int month) => floorDiv(
    TraditionSpec.q * mstar(year, month) + spec.betaInt,
    TraditionSpec.p,
  );

  /// The lunations carrying the label ([year], [month]): one, or two in
  /// chronological order for a doubled month.
  List<int> getLunations(int year, int month) {
    final n = nPlus(year, month);
    return isTriggerLabel(year, month) ? [n - 1, n] : [n];
  }

  /// The first lunation of [year].
  int firstLunation(int year) => getLunations(year, 1).first;

  /// Inverse of [nPlus] (caltib `mstar_from_lunation`).
  int mstarFromLunation(int n) =>
      floorDiv(TraditionSpec.p * n - spec.betaInt - 1, TraditionSpec.q) + 1;

  int _cumulMonth(int n) => mstarFromLunation(n) + TraditionSpec.epochMonth;

  /// The label of lunation [n] (caltib `label_from_lunation`).
  MonthLabel labelFromLunation(int n) {
    final cumul = _cumulMonth(n);
    final month = floorMod(cumul - 1, 12) + 1;
    final year = spec.y0 + floorDiv(cumul - month, 12);
    final leapState = cumul == _cumulMonth(n + 1)
        ? 1
        : cumul == _cumulMonth(n - 1)
        ? 2
        : 0;
    return (year: year, month: month, leapState: leapState);
  }
}
