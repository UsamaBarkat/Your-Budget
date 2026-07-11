import 'package:flutter_test/flutter_test.dart';
import 'package:home_budget_app/core/money.dart';

void main() {
  group('rupeesToPaisa', () {
    test('whole rupees', () => expect(rupeesToPaisa('500'), 50000));
    test('one decimal place', () => expect(rupeesToPaisa('500.5'), 50050));
    test('two decimal places', () => expect(rupeesToPaisa('500.50'), 50050));
    test('99.99 converts exactly', () => expect(rupeesToPaisa('99.99'), 9999));
    test('zero', () => expect(rupeesToPaisa('0'), 0));
    test('large amount', () => expect(rupeesToPaisa('1000000'), 100000000));
    test('100 x 99.99 sums to exact 999900', () {
      final total = List.filled(100, rupeesToPaisa('99.99')).fold(0, (a, b) => a + b);
      expect(total, 999900);
    });
  });

  group('validateRupeeInput', () {
    test('valid whole number returns null', () => expect(validateRupeeInput('500'), isNull));
    test('valid one decimal returns null', () => expect(validateRupeeInput('99.9'), isNull));
    test('valid two decimals returns null', () => expect(validateRupeeInput('99.99'), isNull));
    test('empty string is invalid', () => expect(validateRupeeInput(''), isNotNull));
    test('non-numeric is invalid', () => expect(validateRupeeInput('abc'), isNotNull));
    test('three decimals returns too_many_decimals key',
        () => expect(validateRupeeInput('99.999'), 'error_too_many_decimals'));
    test('four decimals returns too_many_decimals key',
        () => expect(validateRupeeInput('99.9999'), 'error_too_many_decimals'));
  });

  group('paisaToDisplay', () {
    test('whole rupees — no decimal', () => expect(paisaToDisplay(50000), '500'));
    test('zero', () => expect(paisaToDisplay(0), '0'));
    test('large whole rupees', () => expect(paisaToDisplay(100000), '1000'));
    test('99.99', () => expect(paisaToDisplay(9999), '99.99'));
    test('500.50', () => expect(paisaToDisplay(50050), '500.50'));
    test('one paisa', () => expect(paisaToDisplay(1), '0.01'));
    test('ten paisa pads correctly', () => expect(paisaToDisplay(10), '0.10'));
    test('999900 paisa displays as 9999', () => expect(paisaToDisplay(999900), '9999'));
  });
}
