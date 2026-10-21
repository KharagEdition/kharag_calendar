/// Continuous kinematics of the traditional calendars: when each lunar day
/// (tithi) ends, and which tithi is current at the dawn of a civil day.
///
/// Mirrors `TraditionalDayEngine` in caltib's `engines/trad_day.py` and the
/// search in `CalendarEngine.from_jdn` (`engines/calendar.py`), using exact
/// fixed-point integers instead of fractions.
///
/// The timeline is indexed by the absolute tithi `x = 30 n + d`, where `n` is
/// the lunation index of the tradition and `d` in `0..29` the tithi within it,
/// so `x = 30 n` is the end of the previous lunation's last tithi.
library;

import 'int_math.dart';
import 'quarter_wave_table.dart';
import 'tradition.dart';

/// Units per day of a true date: `lcm(11312, 60 * 126, 60 * 402)`.
///
/// The mean date is in 1/11312 day, the moon equation in table units x 126
/// (divided by 60 to give days) and the sun equation in table units x 402.
const int dayScale = 102317040;

const int _meanToDay = dayScale ~/ meanScale; // 9045
const int _moonToDay = dayScale ~/ (60 * 126); // 13534
const int _sunToDay = dayScale ~/ (60 * 402); // 4242

/// Maps absolute tithis to civil days for one tradition.
final class TraditionalDayEngine {
  /// Creates the day engine for [spec].
  const TraditionalDayEngine(this.spec);

  /// The tradition's constants.
  final TraditionSpec spec;

  /// The moon equation table (caltib `MOON_TAB_QUARTER`), 28 steps per turn.
  static const QuarterWaveTable moonTable = QuarterWaveTable(
    quarter: [0, 5, 10, 15, 19, 22, 24, 25],
    step: 126,
  );

  /// The sun equation table (caltib `SUN_TAB_QUARTER`), 12 steps per turn.
  static const QuarterWaveTable sunTable = QuarterWaveTable(
    quarter: [0, 6, 10, 11],
    step: 402,
  );

  /// Mean date of the end of tithi [x], in [meanScale] units of a Julian Day.
  int meanDateScaled(int x) {
    final n = floorDiv(x, 30);
    final d = floorMod(x, 30);
    return spec.m0Scaled +
        TraditionSpec.m1Scaled * n +
        TraditionSpec.m2Scaled * d;
  }

  /// True date of the end of tithi [x], in [dayScale] units of a Julian Day.
  int trueDateScaled(int x) {
    final n = floorDiv(x, 30);
    final d = floorMod(x, 30);
    final moonPhase =
        spec.a0Scaled + TraditionSpec.a1Scaled * n + TraditionSpec.a2Scaled * d;
    final sunPhase =
        spec.r0Scaled + TraditionSpec.s1Scaled * n + TraditionSpec.s2Scaled * d;
    return meanDateScaled(x) * _meanToDay +
        moonTable.evalScaled(moonPhase) * _moonToDay -
        sunTable.evalScaled(sunPhase) * _sunToDay;
  }

  /// The civil day (Julian Day Number) during which tithi [x] ends.
  int civilJdn(int x) => floorDiv(trueDateScaled(x), dayScale);

  /// The tithi current at the dawn of civil day [jdn]: the `x` with
  /// `civilJdn(x - 1) < jdn <= civilJdn(x)`.
  int xFromJdn(int jdn) {
    // Linear estimate, truncated toward zero as caltib's int() does.
    var x = (jdn * meanScale - spec.m0Scaled) ~/ TraditionSpec.m2Scaled;
    // caltib get_x_from_t2000: walk the true-date boundaries.
    final target = jdn * dayScale;
    while (trueDateScaled(x - 1) > target) {
      x--;
    }
    while (trueDateScaled(x) <= target) {
      x++;
    }
    // caltib from_jdn: settle on the exact discrete boundaries.
    while (true) {
      if (jdn <= civilJdn(x - 1)) {
        x--;
      } else if (jdn > civilJdn(x)) {
        x++;
      } else {
        return x;
      }
    }
  }
}
