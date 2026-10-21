/// Integer division and modulo with Python semantics.
///
/// Dart's `~/` and `%` truncate toward zero (and `%` is Euclidean); the
/// reference implementation (caltib, Python) relies on `//` and `%`, which
/// round toward negative infinity. Every division in this package goes
/// through these two helpers so that negative lunation indices and negative
/// phase offsets behave exactly as in the reference.
library;

/// Floor division: the largest integer not greater than `a / b`.
///
/// Mirrors Python's `a // b`. [b] must be non-zero.
int floorDiv(int a, int b) {
  final q = a ~/ b;
  if (a % b != 0 && ((a < 0) != (b < 0))) return q - 1;
  return q;
}

/// Floor modulo: `a - b * floorDiv(a, b)`, which has the sign of [b].
///
/// Mirrors Python's `a % b`. [b] must be non-zero.
int floorMod(int a, int b) => a - b * floorDiv(a, b);
