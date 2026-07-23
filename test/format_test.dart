import 'package:flutter_test/flutter_test.dart';
import 'package:fittimer/utils/format.dart';

void main() {
  group('formatSeconds', () {
    test('under a minute shows seconds', () {
      expect(formatSeconds(45), '45s');
    });
    test('minutes and hours', () {
      expect(formatSeconds(90), '1:30');
      expect(formatSeconds(3665), '1:01:05');
    });
  });

  group('relativeDate', () {
    final now = DateTime(2026, 7, 23, 12, 0);

    test('same day is Today', () {
      expect(relativeDate(DateTime(2026, 7, 23, 6), now), 'Today');
    });
    test('previous day is Yesterday', () {
      expect(relativeDate(DateTime(2026, 7, 22, 23), now), 'Yesterday');
    });
    test('within a week is Nd ago', () {
      expect(relativeDate(DateTime(2026, 7, 20), now), '3d ago');
    });
    test('older same year is d.M.', () {
      expect(relativeDate(DateTime(2026, 5, 1), now), '1.5.');
    });
    test('previous year includes 2-digit year', () {
      expect(relativeDate(DateTime(2025, 12, 31), now), '31.12.25');
    });
  });
}
