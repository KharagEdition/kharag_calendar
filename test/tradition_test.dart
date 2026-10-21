import 'package:kharag_calendar/src/tradition.dart';
import 'package:test/test.dart';

/// Checks that a scaled integer constant equals the exact fraction num/den
/// from caltib's specs.py: scaled / scale == num / den.
void expectFraction(int scaled, int scale, int num, int den, String what) {
  expect(scaled * den, num * scale, reason: '$what should be $num/$den');
}

void main() {
  test('every tradition has a spec', () {
    for (final t in Tradition.values) {
      expect(t.spec.tradition, t);
    }
  });

  test('shared constants reconstruct caltib fractions', () {
    expect(TraditionSpec.p, 65);
    expect(TraditionSpec.q, 67);
    expect(TraditionSpec.epochMonth, 3);
    expectFraction(TraditionSpec.m1Scaled, meanScale, 167025, 5656, 'm1');
    expectFraction(TraditionSpec.m2Scaled, meanScale, 11135, 11312, 'm2');
    expectFraction(TraditionSpec.s1Scaled, sunTurn, 65, 804, 's1');
    expectFraction(TraditionSpec.s2Scaled, sunTurn, 13, 4824, 's2');
    expectFraction(TraditionSpec.a1Scaled, moonTurn, 253, 3528, 'a1');
    expectFraction(TraditionSpec.a2Scaled, moonTurn, 1, 28, 'a2');
    expect(meanScale, 11312);
    expect(sunTurn, 4824);
    expect(moonTurn, 3528);
  });

  test('phugpa constants (E1927)', () {
    final s = Tradition.phugpa.spec;
    expect(s.y0, 1927);
    expect(s.betaStar, 55);
    expect(s.tau, 48);
    expect(s.betaInt, 72); // unreduced: beta_star + (P - tau) % P
    expectFraction(s.m0Scaled, meanScale, 13715647089, 5656, 'm0');
    expectFraction(s.s0Scaled, sunTurn, 749, 804, 's0');
    expectFraction(s.a0Scaled, moonTurn, 1741, 3528, 'a0');
    expectFraction(s.r0Scaled, sunTurn, 137, 201, 'r0 = s0 - 1/4');
    expect(s.leapLabeling, LeapLabeling.firstIsLeap);
  });

  test('bhutan constants (E1754)', () {
    final s = Tradition.bhutan.spec;
    expect(s.y0, 1754);
    expect(s.betaStar, 2);
    expect(s.tau, 57);
    expect(s.betaInt, 10);
    expectFraction(s.m0Scaled, meanScale, 1669797601, 707, 'm0');
    expectFraction(s.s0Scaled, sunTurn, 1, 67, 's0');
    expectFraction(s.a0Scaled, moonTurn, 17, 147, 'a0');
    expectFraction(s.r0Scaled, sunTurn, -63, 268, 'r0 = s0 - 1/4');
    expect(s.leapLabeling, LeapLabeling.secondIsLeap);
  });

  test('mongol constants (E1747)', () {
    final s = Tradition.mongol.spec;
    expect(s.y0, 1747);
    expect(s.betaStar, 10);
    expect(s.tau, 46);
    expect(s.betaInt, 29);
    expectFraction(s.m0Scaled, meanScale, 6671924839, 2828, 'm0');
    expectFraction(s.s0Scaled, sunTurn, 397, 402, 's0');
    expectFraction(s.a0Scaled, moonTurn, 1523, 1764, 'a0');
    expectFraction(s.r0Scaled, sunTurn, 593, 804, 'r0 = s0 - 1/4');
    expect(s.leapLabeling, LeapLabeling.firstIsLeap);
  });
}
