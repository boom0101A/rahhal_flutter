import 'package:flutter_test/flutter_test.dart';
import 'package:rahhal_flutter/features/currency/data/currency_service.dart';

void main() {
  test('Iraqi dinar: whole numbers, grouped, symbol after', () {
    // 1 USD ≈ 1310 IQD — an Iraqi price is a big number and must stay readable.
    expect(CurrencyService.format(32750, 'IQD'), '32,750 د.ع');
    expect(CurrencyService.format(1309992, 'IQD'), '1,309,992 د.ع');
    // Never shows fractional dinars.
    expect(CurrencyService.format(1310.4, 'IQD'), '1,310 د.ع');
  });

  test('Latin symbols stay before the number', () {
    expect(CurrencyService.format(25, 'USD'), '\$25');
    expect(CurrencyService.format(1500, 'USD'), '\$1,500');
  });

  test('small amounts in decimal currencies keep cents', () {
    expect(CurrencyService.format(9.5, 'USD'), '\$9.50');
  });

  test('an amount that rounds up to 1000 still gets a thousands separator', () {
    // `whole` used to be decided on the un-rounded amount, so 999.7 (< 1000)
    // took the decimal branch, which itself rounds to "1000" via
    // toStringAsFixed(0) — producing "$1000" instead of "$1,000".
    expect(CurrencyService.format(999.7, 'USD'), '\$1,000');
    expect(CurrencyService.format(999.5, 'EUR'), '€1,000');
    // Just under the boundary still rounds to a plain (non-grouped) integer.
    expect(CurrencyService.format(999.4, 'USD'), '\$999');
  });

  test('unknown currency falls back to its code, not a crash', () {
    expect(CurrencyService.format(100, 'XYZ'), 'XYZ100');
  });

  test('country to currency mapping covers Iraq and the region', () {
    expect(CurrencyService.currencyForCountry('IQ'), 'IQD');
    expect(CurrencyService.currencyForCountry('iq'), 'IQD'); // case-insensitive
    expect(CurrencyService.currencyForCountry('TR'), 'TRY');
    expect(CurrencyService.currencyForCountry('DE'), 'EUR');
    expect(CurrencyService.currencyForCountry(null), isNull);
    expect(CurrencyService.currencyForCountry(''), isNull);
  });

  test('symbolFor returns a bare symbol, never digits or stray punctuation', () {
    // The picker subtitle uses this directly — it must not carry leftovers
    // from formatting a zero amount (e.g. "$." or ". ر.س").
    expect(CurrencyService.symbolFor('IQD'), 'د.ع');
    expect(CurrencyService.symbolFor('USD'), '\$');
    expect(CurrencyService.symbolFor('sar'), 'ر.س'); // case-insensitive
    expect(CurrencyService.symbolFor('XYZ'), 'XYZ'); // unknown falls back to code
  });
}
