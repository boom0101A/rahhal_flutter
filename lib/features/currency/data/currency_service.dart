import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/app_config.dart';

class CurrencyService {
  final Dio _dio;

  CurrencyService({Dio? dio}) : _dio = dio ?? Dio();

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

  /// Format an amount with currency symbol
  static String format(double amount, String currencyCode) {
    final symbols = {
      'SAR': 'ر.س', 'AED': 'د.إ', 'EGP': 'ج.م', 'KWD': 'د.ك',
      'QAR': 'ر.ق', 'BHD': 'د.ب', 'OMR': 'ر.ع', 'JOD': 'د.أ',
      'MAD': 'د.م', 'TND': 'د.ت', 'GBP': '£', 'EUR': '€',
      'TRY': '₺', 'JPY': '¥', 'CNY': '¥', 'INR': '₹', 'USD': '\$',
    };
    final symbol = symbols[currencyCode] ?? currencyCode;
    return '$symbol${amount.toStringAsFixed(amount < 10 ? 2 : 0)}';
  }

  /// Map country code to its local currency code
  static String? currencyForCountry(String? countryCode) {
    if (countryCode == null) return null;
    const map = {
      'SA': 'SAR', 'AE': 'AED', 'EG': 'EGP', 'KW': 'KWD',
      'QA': 'QAR', 'BH': 'BHD', 'OM': 'OMR', 'JO': 'JOD',
      'MA': 'MAD', 'TN': 'TND', 'TR': 'TRY', 'GB': 'GBP',
      'FR': 'EUR', 'DE': 'EUR', 'IT': 'EUR', 'ES': 'EUR',
      'JP': 'JPY', 'CN': 'CNY', 'IN': 'INR', 'US': 'USD',
    };
    return map[countryCode.toUpperCase()];
  }
}
