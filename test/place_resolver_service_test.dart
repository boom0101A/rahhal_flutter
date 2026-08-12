import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rahhal_flutter/core/services/place_resolver_service.dart';

/// Regression test for PlaceResolverService permanently caching a failed
/// resolution. The static `_cache` map has no expiry, and used to store
/// `null` on any error — so one transient network blip poisoned that
/// name+coordinate key for the rest of the app session, permanently falling
/// back to a coordinate pin instead of the exact Google Places card, even
/// long after connectivity recovered.
class _FailThenSucceedAdapter implements HttpClientAdapter {
  int callCount = 0;
  final String placeId;

  _FailThenSucceedAdapter(this.placeId);

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<List<int>>? requestStream, Future<void>? cancelFuture) async {
    callCount++;
    if (callCount == 1) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    final body = jsonEncode({'place_id': placeId});
    return ResponseBody.fromBytes(
      Uint8List.fromList(utf8.encode(body)),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('a failed resolution is retried on the next call, not permanently cached',
      () async {
    final adapter = _FailThenSucceedAdapter('ChIJ_test_place_id');
    final dio = Dio()..httpClientAdapter = adapter;
    final service = PlaceResolverService(dio: dio);

    final first = await service.resolvePlaceId(
      name: 'Unique Cafe For This Test',
      lat: 33.123456,
      lng: 44.123456,
    );
    expect(first, isNull, reason: 'first call fails (simulated network error)');
    expect(adapter.callCount, 1);

    final second = await service.resolvePlaceId(
      name: 'Unique Cafe For This Test',
      lat: 33.123456,
      lng: 44.123456,
    );
    expect(second, 'ChIJ_test_place_id',
        reason: 'the failure must not have been cached — this call should '
            'hit the network again and succeed');
    expect(adapter.callCount, 2,
        reason: 'a cached null would have short-circuited this into a '
            'second network call never happening');
  });

  test('a successful resolution IS cached — a third call does not hit the network',
      () async {
    final adapter = _FailThenSucceedAdapter('ChIJ_second_test_id');
    final dio = Dio()..httpClientAdapter = adapter;
    final service = PlaceResolverService(dio: dio);

    // Prime past the simulated first failure.
    await service.resolvePlaceId(
      name: 'Another Unique Cafe',
      lat: 34.111111,
      lng: 45.111111,
    );
    final resolved = await service.resolvePlaceId(
      name: 'Another Unique Cafe',
      lat: 34.111111,
      lng: 45.111111,
    );
    expect(resolved, 'ChIJ_second_test_id');

    final cachedAgain = await service.resolvePlaceId(
      name: 'Another Unique Cafe',
      lat: 34.111111,
      lng: 45.111111,
    );
    expect(cachedAgain, 'ChIJ_second_test_id');
    expect(adapter.callCount, 2,
        reason: 'a real success should stay cached indefinitely — place ids '
            "don't change — so this third call must not hit the network");
  });
}
