/// The traditional calendars this package implements and their exact
/// epoch constants, taken from caltib's `engines/specs.py`.
///
/// Every constant is stored as an integer in a fixed scale so that all later
/// arithmetic is exact:
///
/// * mean-date quantities (`m0`, `m1`, `m2`) in [meanScale] units of a day;
/// * solar phases (`s0`, `s1`, `s2`, `r0`) in [sunTurn] units of a turn;
/// * lunar anomaly phases (`a0`, `a1`, `a2`) in [moonTurn] units of a turn.
library;

import 'int_math.dart';

/// Units per day for mean-date constants (1/11312 day).
const int meanScale = 11312;

/// Units per turn for solar phases (1/4824 turn).
const int sunTurn = 4824;

/// Units per turn for lunar anomaly phases (1/3528 turn).
const int moonTurn = 3528;

/// Which of two months carrying the same number is called the leap month.
enum LeapLabeling {
  /// The first of the pair is the leap month (Phugpa, Mongol).
  firstIsLeap,

  /// The second of the pair is the leap month (Bhutan).
  secondIsLeap,
}

/// A traditional calendar.
enum Tradition {
  /// The Phugpa (Phukluk) system used in Tibet; caltib engine `phugpa`.
  phugpa,

  /// The Bhutanese system; caltib engine `bhutan`.
  bhutan,

  /// The Mongolian (New Genden) system; caltib engine `mongol`.
  mongol;

  /// Whether the leap month of a doubled pair comes first.
  ///
  /// True for Phugpa and Mongol, where a leap month precedes the regular
  /// month of the same number; false for Bhutan, where it follows it.
  bool get leapMonthComesFirst => spec.leapLabeling == LeapLabeling.firstIsLeap;
}

/// Internal access to the constants of a [Tradition]; not exported by the
/// public library.
extension TraditionSpecOf on Tradition {
  /// The exact constants of this tradition.
  TraditionSpec get spec => switch (this) {
    Tradition.phugpa => phugpaSpec,
    Tradition.bhutan => bhutanSpec,
    Tradition.mongol => mongolSpec,
  };
}

/// Exact parameters of one traditional calendar (caltib `CalendarSpec`).
final class TraditionSpec {
  /// Creates a spec; see the named constants for the published values.
  const TraditionSpec({
    required this.tradition,
    required this.y0,
    required this.betaStar,
    required this.tau,
    required this.m0Scaled,
    required this.s0Scaled,
    required this.a0Scaled,
    required this.leapLabeling,
  });

  /// The tradition these constants describe.
  final Tradition tradition;

  /// Solar months per intercalation cycle (65 solar months = 67 lunations).
  static const int p = 65;

  /// Lunations per intercalation cycle.
  static const int q = 67;

  /// Month label carried by the epoch (caltib `M0`).
  static const int epochMonth = 3;

  /// Mean synodic month `m1 = 167025/5656` days, in [meanScale] units.
  static const int m1Scaled = 334050;

  /// Mean lunar day `m2 = m1/30 = 11135/11312` days, in [meanScale] units.
  static const int m2Scaled = 11135;

  /// Mean solar motion per lunation `s1 = 65/804` turn, in [sunTurn] units.
  static const int s1Scaled = 390;

  /// Mean solar motion per lunar day `s2 = 13/4824` turn, in [sunTurn] units.
  static const int s2Scaled = 13;

  /// Lunar anomaly per lunation `a1 = 253/3528` turn, in [moonTurn] units.
  static const int a1Scaled = 253;

  /// Lunar anomaly per lunar day `a2 = 1/28` turn, in [moonTurn] units.
  static const int a2Scaled = 126;

  /// Epoch year (caltib `Y0`).
  final int y0;

  /// Published intercalation constant (caltib `beta_star`).
  final int betaStar;

  /// Published leap-month placement marker (caltib `tau`).
  final int tau;

  /// Mean new moon at the epoch, in [meanScale] units of a Julian Day.
  final int m0Scaled;

  /// Mean solar longitude at the epoch, in [sunTurn] units.
  final int s0Scaled;

  /// Lunar anomaly at the epoch, in [moonTurn] units.
  final int a0Scaled;

  /// Which month of a doubled pair is the leap month.
  final LeapLabeling leapLabeling;

  /// Leap months per cycle, `q - p`.
  int get ell => q - p;

  /// Shift sending the trigger set to `{0, .., ell-1}` (caltib `gamma_shift`).
  int get gammaShift => floorMod(p - tau, p);

  /// Combined intercalation constant `betaStar + gammaShift`, deliberately
  /// not reduced modulo [p] (caltib `beta_int`).
  int get betaInt => betaStar + gammaShift;

  /// Solar anomaly at the epoch, `s0 - 1/4` turn, in [sunTurn] units.
  int get r0Scaled => s0Scaled - sunTurn ~/ 4;
}

/// Phugpa, epoch 1927 (caltib `PHUGPA_SPEC`).
const TraditionSpec phugpaSpec = TraditionSpec(
  tradition: Tradition.phugpa,
  y0: 1927,
  betaStar: 55,
  tau: 48,
  m0Scaled: 27431294178, // 13715647089/5656
  s0Scaled: 4494, // 749/804
  a0Scaled: 1741, // 1741/3528
  leapLabeling: LeapLabeling.firstIsLeap,
);

/// Bhutan, epoch 1754 (caltib `BHUTAN_SPEC`).
const TraditionSpec bhutanSpec = TraditionSpec(
  tradition: Tradition.bhutan,
  y0: 1754,
  betaStar: 2,
  tau: 57,
  m0Scaled: 26716761616, // 1669797601/707
  s0Scaled: 72, // 1/67
  a0Scaled: 408, // 17/147
  leapLabeling: LeapLabeling.secondIsLeap,
);

/// Mongol (New Genden), epoch 1747 (caltib `MONGOL_SPEC`).
const TraditionSpec mongolSpec = TraditionSpec(
  tradition: Tradition.mongol,
  y0: 1747,
  betaStar: 10,
  tau: 46,
  m0Scaled: 26687699356, // 6671924839/2828
  s0Scaled: 4764, // 397/402
  a0Scaled: 3046, // 1523/1764
  leapLabeling: LeapLabeling.firstIsLeap,
);
