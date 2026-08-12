import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rahhal_flutter/core/network/dio_client.dart';

/// Regression test for DioClient's retry interceptor blindly retrying
/// non-idempotent requests on timeout. /api/generate-trip and /api/chat are
/// expensive AI calls that may still be genuinely processing when
/// receiveTimeout fires — retrying used to fire a SECOND full generation/
/// chat call, doubling provider cost and risking a rate-limit collision.
///
/// The interceptor classes are private to dio_client.dart, so this drives
/// the fix through the real public DioClient.anthropic Dio instance with a
/// fake HttpClientAdapter that always times out, counting how many times
/// the adapter is actually invoked for a given request.
///
/// The companion fix — guarding the 401/403 auto-refresh-and-retry branch
/// against unbounded recursion via an `authRetried` flag — is NOT covered
/// here: that branch only activates when `FirebaseAuth.instance.currentUser`
/// is non-null, which needs Firebase test scaffolding this project doesn't
/// have. Verified instead by reading dio_client.dart directly: the branch
/// now checks `err.requestOptions.extra['authRetried'] != true` before
/// attempting a refresh, and sets it to `true` before the one retry it's
/// allowed, so a second 401/403 on the retried request falls straight
/// through instead of recursing into the same branch again.
class _AlwaysTimesOutAdapter implements HttpClientAdapter {
  int callCount = 0;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<List<int>>? requestStream, Future<void>? cancelFuture) async {
    callCount++;
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.receiveTimeout,
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('a POST that times out is NOT retried (non-idempotent)', () async {
    final adapter = _AlwaysTimesOutAdapter();
    DioClient.anthropic.httpClientAdapter = adapter;

    await expectLater(
      DioClient.anthropic.post('/api/generate-trip', data: {'x': 1}),
      throwsA(isA<DioException>()),
    );

    expect(adapter.callCount, 1,
        reason: 'a POST must fail on the first timeout, not be retried — '
            'retrying re-fires an expensive AI call that may still be '
            'genuinely processing server-side');
  });

  test('a GET that times out IS retried up to maxRetries', () async {
    final adapter = _AlwaysTimesOutAdapter();
    DioClient.anthropic.httpClientAdapter = adapter;

    await expectLater(
      DioClient.anthropic.get('/health'),
      throwsA(isA<DioException>()),
    );

    // _RetryInterceptor is constructed with maxRetries: 3 in dio_client.dart
    // — the original attempt plus 3 retries is 4 total adapter calls.
    expect(adapter.callCount, 4,
        reason: 'GET is idempotent — a warmup/health-check timeout should '
            'still retry the way it always did');
  });
}
