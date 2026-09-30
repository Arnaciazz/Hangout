import 'package:flutter_test/flutter_test.dart';
import 'package:hangout/utils/money.dart';

void main() {
  group('formatRupees', () {
    test('uses Indian digit grouping', () {
      expect(formatRupees(0), '₹0');
      expect(formatRupees(85000), '₹850');
      expect(formatRupees(123400), '₹1,234');
      expect(formatRupees(10000000), '₹1,00,000');
      expect(formatRupees(1234567800), '₹1,23,45,678');
    });

    test('shows paise only when there are any', () {
      expect(formatRupees(123450), '₹1,234.50');
      expect(formatRupees(5), '₹0.05');
      expect(formatRupees(-2550), '-₹25.50');
    });
  });

  group('parseRupees', () {
    test('accepts what people type', () {
      expect(parseRupees('850'), 85000);
      expect(parseRupees('1,234'), 123400);
      expect(parseRupees('₹ 1,234.5'), 123450);
      expect(parseRupees('0.05'), 5);
      expect(parseRupees(' 99.99 '), 9999);
    });

    test('rejects anything else', () {
      expect(parseRupees(''), isNull);
      expect(parseRupees('0'), isNull);
      expect(parseRupees('abc'), isNull);
      expect(parseRupees('12.345'), isNull);
      expect(parseRupees('-50'), isNull);
      expect(parseRupees('1.2.3'), isNull);
      expect(parseRupees('1234567890'), isNull);
    });
  });

  group('splitEvenly', () {
    test('always adds back up to the total', () {
      for (final total in [1, 99, 100000, 100001, 123457]) {
        for (var n = 1; n <= 10; n++) {
          final parts = splitEvenly(total, n);
          expect(parts, hasLength(n));
          expect(parts.reduce((a, b) => a + b), total);
          expect(parts.first - parts.last, lessThanOrEqualTo(1));
        }
      }
    });

    test('matches the database: leftover paise go to the first people', () {
      expect(splitEvenly(100000, 3), [33334, 33333, 33333]);
      expect(splitEvenly(10, 4), [3, 3, 2, 2]);
      expect(splitEvenly(500, 0), isEmpty);
    });
  });

  group('isValidUpiId', () {
    test('accepts real-looking IDs', () {
      expect(isValidUpiId('asha@okicici'), isTrue);
      expect(isValidUpiId('9876543210@ybl'), isTrue);
      expect(isValidUpiId('first.last-1@paytm'), isTrue);
      expect(isValidUpiId('  rohan@upi  '), isTrue);
    });

    test('rejects the rest', () {
      expect(isValidUpiId(''), isFalse);
      expect(isValidUpiId('asha'), isFalse);
      expect(isValidUpiId('a@okicici'), isFalse);
      expect(isValidUpiId('asha@'), isFalse);
      expect(isValidUpiId('asha@1bank'), isFalse);
      expect(isValidUpiId('asha@ok icici'), isFalse);
      expect(isValidUpiId('as ha@okicici'), isFalse);
    });
  });

  test('upiPaymentUri builds a prefilled UPI link', () {
    final uri = upiPaymentUri(
      payeeUpi: 'asha@okicici',
      payeeName: 'Asha Rao',
      amountPaise: 33334,
      note: 'Hangout: Toit & friends',
    );
    expect(uri.scheme, 'upi');
    expect(uri.host, 'pay');
    expect(uri.toString(), startsWith('upi://pay?pa=asha@okicici&'));
    expect(uri.queryParameters['pa'], 'asha@okicici');
    expect(uri.queryParameters['pn'], 'Asha Rao');
    expect(uri.queryParameters['am'], '333.34');
    expect(uri.queryParameters['cu'], 'INR');
    expect(uri.queryParameters['tn'], 'Hangout: Toit & friends');

    final small = upiPaymentUri(
      payeeUpi: 'a1@ybl',
      payeeName: 'A',
      amountPaise: 5,
      note: 'x',
    );
    expect(small.queryParameters['am'], '0.05');
  });
}
