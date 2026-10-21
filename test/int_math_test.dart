import 'package:kharag_calendar/src/int_math.dart';
import 'package:test/test.dart';

void main() {
  group('floorDiv', () {
    test('rounds toward negative infinity like Python //', () {
      expect(floorDiv(7, 2), 3);
      expect(floorDiv(-7, 2), -4);
      expect(floorDiv(7, -2), -4);
      expect(floorDiv(-7, -2), 3);
    });

    test('is exact on multiples and zero', () {
      expect(floorDiv(-6, 2), -3);
      expect(floorDiv(6, -3), -2);
      expect(floorDiv(0, 5), 0);
      expect(floorDiv(0, -5), 0);
    });
  });

  group('floorMod', () {
    test('takes the sign of the divisor like Python %', () {
      expect(floorMod(7, 2), 1);
      expect(floorMod(-7, 2), 1);
      expect(floorMod(7, -2), -1);
      expect(floorMod(-7, -2), -1);
    });

    test('wraps phases into [0, turn)', () {
      expect(floorMod(-1, 3528), 3527);
      expect(floorMod(3528, 3528), 0);
      expect(floorMod(-3529, 3528), 3527);
      expect(floorMod(7056, 3528), 0);
    });

    test('satisfies a == b * floorDiv(a, b) + floorMod(a, b)', () {
      for (var a = -100; a <= 100; a++) {
        for (final b in [-7, -3, -1, 1, 2, 5, 30]) {
          expect(b * floorDiv(a, b) + floorMod(a, b), a, reason: 'a=$a b=$b');
          final r = floorMod(a, b);
          expect(
            b > 0 ? r >= 0 && r < b : r <= 0 && r > b,
            isTrue,
            reason: 'a=$a b=$b r=$r',
          );
        }
      }
    });
  });
}
