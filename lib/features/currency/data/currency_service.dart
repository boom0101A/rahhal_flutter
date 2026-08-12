import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/dio_client.dart';

class CurrencyService {
  final Dio _dio;

  // DioClient.general, not a bare Dio() — /api/currency now requires a
  // Firebase ID token and only the shared client attaches one.
  CurrencyService({Dio? dio}) : _dio = dio ?? DioClient.general;

  static const _cachePrefix = 'currency_rate_';
  static const _cacheTimestampPrefix = 'currency_ts_';
  static const _cacheDurationHours = 6;

  /// Returns exchange rate: 1 USD = X [targetCurrency]
  Future<double?> getRate(String targetCurrency) async {
    if (targetCurrency == 'USD') return 1.0;

    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '$_cachePrefix$targetCurrency';
    final tsKey = '$_cacheTimestampPrefix$targetCurrency';

    // Check local cache first (offline support)
    final cachedRate = prefs.getDouble(cacheKey);
    final cachedTs = prefs.getInt(tsKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final cacheExpiry = _cacheDurationHours * 3600 * 1000;

    if (cachedRate != null && (now - cachedTs) < cacheExpiry) {
      return cachedRate;
    }

    // Fetch from server
    try {
      final res = await _dio.get(
        '${AppConfig.proxyBaseUrl}/api/currency',
        queryParameters: {'base': 'USD', 'target': targetCurrency},
        options: Options(receiveTimeout: const Duration(seconds: 6)),
      );
      final rate = (res.data['rate'] as num?)?.toDouble();
      if (rate != null) {
        await prefs.setDouble(cacheKey, rate);
        await prefs.setInt(tsKey, now);
        return rate;
      }
    } catch (_) {
      // Return cached value even if expired when offline
      if (cachedRate != null) return cachedRate;
    }
    return null;
  }

  static const Map<String, String> _symbols = {
    'IQD': 'د.ع', 'SAR': 'ر.س', 'AED': 'د.إ', 'EGP': 'ج.م', 'KWD': 'د.ك',
    'QAR': 'ر.ق', 'BHD': 'د.ب', 'OMR': 'ر.ع', 'JOD': 'د.أ', 'LBP': 'ل.ل',
    'SYP': 'ل.س', 'YER': 'ر.ي', 'MAD': 'د.م', 'TND': 'د.ت', 'DZD': 'د.ج',
    'LYD': 'د.ل', 'SDG': 'ج.س', 'ILS': '₪', 'IRR': '﷼',
    'GBP': '£', 'EUR': '€', 'TRY': '₺', 'JPY': '¥', 'CNY': '¥', 'INR': '₹',
    'USD': '\$', 'CAD': 'C\$', 'AUD': 'A\$', 'CHF': 'CHF', 'SEK': 'kr',
    'NOK': 'kr', 'DKK': 'kr', 'RUB': '₽', 'PKR': '₨', 'MYR': 'RM',
    'IDR': 'Rp', 'THB': '฿', 'KRW': '₩', 'SGD': 'S\$', 'AZN': '₼',
    'GEL': '₾', 'AMD': '֏', 'UAH': '₴', 'BRL': 'R\$', 'ZAR': 'R',
  };

  /// Currencies whose smallest practical unit is ~1 — showing decimals for
  /// them ("32,750.00 د.ع") is noise, so they're always rendered whole.
  static const Set<String> _wholeUnitCurrencies = {
    'IQD', 'LBP', 'SYP', 'YER', 'IRR', 'JPY', 'KRW', 'IDR', 'VND', 'UZS',
  };

  /// The bare symbol for a currency code, or the code itself when unknown.
  /// Unlike [format], this never runs a number through the formatter, so
  /// there's no stray "0" or decimal point to strip.
  static String symbolFor(String currencyCode) =>
      _symbols[currencyCode.toUpperCase()] ?? currencyCode.toUpperCase();

  /// Format an amount with its currency symbol. Large numbers get thousands
  /// separators — an Iraqi price like 1309992 is unreadable without them.
  static String format(double amount, String currencyCode) {
    final code = currencyCode.toUpperCase();
    final symbol = _symbols[code] ?? code;
    // Checked against the ROUNDED value — otherwise e.g. 999.7 read as
    // amount < 1000, took the 2-decimals-or-none branch below, and rounded
    // up to "1000" with no thousands separator.
    final whole =
        _wholeUnitCurrencies.contains(code) || amount.round() >= 1000;
    final text = whole
        ? _groupThousands(amount.round())
        : amount.toStringAsFixed(amount < 10 ? 2 : 0);
    // Arabic currency symbols read naturally after the number; Latin ones
    // before it.
    final isArabicSymbol = RegExp(r'[؀-ۿ]').hasMatch(symbol);
    return isArabicSymbol ? '$text $symbol' : '$symbol$text';
  }

  static String _groupThousands(int value) {
    final digits = value.abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
      buf.write(digits[i]);
    }
    return value < 0 ? '-$buf' : buf.toString();
  }

  /// Map country code to its local currency code.
  static String? currencyForCountry(String? countryCode) {
    if (countryCode == null || countryCode.trim().isEmpty) return null;
    const map = {
      'IQ': 'IQD', 'SA': 'SAR', 'AE': 'AED', 'EG': 'EGP', 'KW': 'KWD',
      'QA': 'QAR', 'BH': 'BHD', 'OM': 'OMR', 'JO': 'JOD', 'LB': 'LBP',
      'SY': 'SYP', 'YE': 'YER', 'PS': 'ILS', 'IR': 'IRR',
      'MA': 'MAD', 'TN': 'TND', 'DZ': 'DZD', 'LY': 'LYD', 'SD': 'SDG',
      'TR': 'TRY', 'GB': 'GBP', 'US': 'USD', 'CA': 'CAD', 'AU': 'AUD',
      'CH': 'CHF', 'SE': 'SEK', 'NO': 'NOK', 'DK': 'DKK', 'RU': 'RUB',
      'JP': 'JPY', 'CN': 'CNY', 'IN': 'INR', 'PK': 'PKR', 'MY': 'MYR',
      'ID': 'IDR', 'TH': 'THB', 'KR': 'KRW', 'SG': 'SGD',
      'AZ': 'AZN', 'GE': 'GEL', 'AM': 'AMD', 'UA': 'UAH',
      'BR': 'BRL', 'ZA': 'ZAR',
      // Eurozone
      'FR': 'EUR', 'DE': 'EUR', 'IT': 'EUR', 'ES': 'EUR', 'NL': 'EUR',
      'BE': 'EUR', 'AT': 'EUR', 'PT': 'EUR', 'GR': 'EUR', 'IE': 'EUR',
      'FI': 'EUR', 'CY': 'EUR', 'MT': 'EUR', 'SK': 'EUR', 'SI': 'EUR',
      'EE': 'EUR', 'LV': 'EUR', 'LT': 'EUR', 'LU': 'EUR', 'HR': 'EUR',
    };
    return map[countryCode.trim().toUpperCase()];
  }

  // ─── Home currency (the user's own money) ─────────────────────────────────

  static const _homeCurrencyKey = 'home_currency_code';

  /// The currency the user thinks in. Resolution order:
  ///   1. an explicit choice they saved,
  ///   2. the device's region (e.g. an Iraqi phone → IQD),
  ///   3. null, so callers just show USD.
  static Future<String?> homeCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_homeCurrencyKey);
    if (saved != null && saved.isNotEmpty) return saved;
    return currencyForCountry(deviceCountryCode());
  }

  /// Lets the user override the auto-detected currency.
  static Future<void> setHomeCurrency(String? code) async {
    final prefs = await SharedPreferences.getInstance();
    if (code == null || code.isEmpty) {
      await prefs.remove(_homeCurrencyKey);
    } else {
      await prefs.setString(_homeCurrencyKey, code.toUpperCase());
    }
  }

  /// ISO-2 region from the device locale ("ar_IQ" → "IQ").
  static String? deviceCountryCode() {
    final locale = ui.PlatformDispatcher.instance.locale;
    final region = locale.countryCode;
    return (region == null || region.isEmpty) ? null : region.toUpperCase();
  }
}
