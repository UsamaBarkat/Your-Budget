import 'package:flutter_test/flutter_test.dart';
import 'package:home_budget_app/core/zakat.dart';

void main() {
  group('computeNisab', () {
    test('TS-Z1: (20000 × 612360 + 500) ~/ 1000 = 12247200', () {
      expect(computeNisab(20000), 12247200);
    });
    test('TS-Z2: zero silver price yields zero nisab', () {
      expect(computeNisab(0), 0);
    });
  });

  group('computeZakat', () {
    test('TS-Z3: zero assets, zero nisab — 2.5% of 0 = 0', () {
      expect(computeZakat(0, 0), 0);
    });
    test('TS-Z4: below nisab yields zero', () {
      expect(computeZakat(49999, 50000), 0);
    });
    test('TS-Z5: at nisab — zakat is due (result > 0)', () {
      expect(computeZakat(50000, 50000), greaterThan(0));
    });
    test('TS-Z6: 2.5% of 100000 paisa = 2500', () {
      expect(computeZakat(100000, 50000), 2500);
    });
    test('TS-Z7: round-half-up — 100020 × 0.025 = 2500.5 → 2501', () {
      expect(computeZakat(100020, 50000), 2501);
    });
  });

  group('computeTotalAssets', () {
    test('TS-Z8: sums all four asset categories', () {
      expect(computeTotalAssets(1000, 2000, 3000, 4000), 10000);
    });
  });

  group('computeMetalValue', () {
    test('TS-Z9: (50125 × 1500000 + 500) ~/ 1000 = 75187500', () {
      expect(computeMetalValue(50125, 1500000), 75187500);
    });
    test('TS-Z10: zero milligrams yields zero value', () {
      expect(computeMetalValue(0, 1500000), 0);
    });
  });

  group('gramsToMilligrams', () {
    test('TS-Z11: "50.125" → 50125 mg', () {
      expect(gramsToMilligrams('50.125'), 50125);
    });
    test('TS-Z12: "50" → 50000 mg', () {
      expect(gramsToMilligrams('50'), 50000);
    });
  });

  group('validateGramInput', () {
    test('TS-Z13: empty string is invalid', () {
      expect(validateGramInput(''), isNotNull);
    });
    test('TS-Z14: more than 3 decimal places is invalid', () {
      expect(validateGramInput('50.1234'), isNotNull);
    });
    test('TS-Z15: exactly 3 decimal places is valid', () {
      expect(validateGramInput('50.125'), isNull);
    });
  });
}
