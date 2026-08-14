import 'package:flutter/foundation.dart';
import 'dio_client.dart';
import '../config/app_config.dart';
import '../services/crash_reporter.dart';

/// Submits "this AI result is wrong" reports to the backend.
class IssueReportService {
  final _dio = DioClient.general;

  /// Small, fast Firestore write — not a slow AI call, so `.general`'s short
  /// 15s/30s timeouts (vs `.anthropic`'s 90s/120s) fail fast instead of
  /// leaving a "submitting…" dialog hanging.
  Future<bool> submitReport({
    required String sourceType,
    required String tripId,
    required String itemId,
    String? itemName,
    String? placeId,
    required String reason,
    String? extraContext,
  }) async {
    try {
      await _dio.post(
        '${AppConfig.proxyBaseUrl}/api/report-issue',
        data: {
          'sourceType': sourceType,
          'tripId': tripId,
          'itemId': itemId,
          'itemName': itemName,
          'placeId': placeId,
          'reason': reason,
          'context': extraContext,
        },
      );
      return true;
    } catch (e, st) {
      debugPrint('[IssueReportService] submitReport failed: $e');
      reportNonFatal(e, st, reason: 'IssueReportService.submitReport failed');
      return false;
    }
  }
}
