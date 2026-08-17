import 'package:flutter_test/flutter_test.dart';
import 'package:rahhal_flutter/core/services/location_service.dart';

void main() {
  group('UserLocationResult.fullLocationDisplay', () {
    test('city and country in Arabic uses an Arabic comma', () {
      const result = UserLocationResult(
        latitude: 33.3,
        longitude: 44.4,
        cityName: 'بغداد',
        countryName: 'العراق',
      );
      expect(result.fullLocationDisplay('ar'), 'بغداد، العراق');
    });

    test('city and country in English uses a plain comma', () {
      const result = UserLocationResult(
        latitude: 33.3,
        longitude: 44.4,
        cityName: 'Baghdad',
        countryName: 'Iraq',
      );
      expect(result.fullLocationDisplay('en'), 'Baghdad, Iraq');
    });

    test('city only, no country', () {
      const result = UserLocationResult(
        latitude: 33.3,
        longitude: 44.4,
        cityName: 'Baghdad',
        countryName: '',
      );
      expect(result.fullLocationDisplay('en'), 'Baghdad');
    });

    test('country only, no city', () {
      const result = UserLocationResult(
        latitude: 33.3,
        longitude: 44.4,
        cityName: '',
        countryName: 'Iraq',
      );
      expect(result.fullLocationDisplay('en'), 'Iraq');
    });

    test('nothing resolved falls back to a localized "current location"', () {
      const result = UserLocationResult(
        latitude: 33.3,
        longitude: 44.4,
        cityName: '',
        countryName: '',
      );
      expect(result.fullLocationDisplay('ar'), 'الموقع الحالي');
      expect(result.fullLocationDisplay('en'), 'Current location');
    });
  });
}
