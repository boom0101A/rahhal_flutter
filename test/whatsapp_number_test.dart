import 'package:flutter_test/flutter_test.dart';
import 'package:rahhal_flutter/shared/widgets/booking_contact_section.dart';

void main() {
  test('Iraqi national format gets the 964 country code', () {
    expect(whatsAppNumber('0770 123 4567', countryCode: 'IQ'), '9647701234567');
    expect(whatsAppNumber('07701234567', countryCode: 'IQ'), '9647701234567');
  });

  test('already-international numbers are kept, plus stripped', () {
    expect(whatsAppNumber('+964 770 123 4567', countryCode: 'IQ'), '9647701234567');
    // Works even when the trip country is unknown.
    expect(whatsAppNumber('+90 532 123 4567'), '905321234567');
  });

  test('other countries resolve their own dialing code', () {
    expect(whatsAppNumber('0532 123 4567', countryCode: 'TR'), '905321234567');
    expect(whatsAppNumber('050 123 4567', countryCode: 'AE'), '971501234567');
  });

  test('national number with unknown country is rejected, not guessed', () {
    // Prefixing a wrong country code would open a stranger's chat.
    expect(whatsAppNumber('0770 123 4567', countryCode: null), isNull);
    expect(whatsAppNumber('0770 123 4567', countryCode: 'ZZ'), isNull);
  });

  test('junk and empty input are rejected', () {
    expect(whatsAppNumber(null), isNull);
    expect(whatsAppNumber(''), isNull);
    expect(whatsAppNumber('   '), isNull);
    expect(whatsAppNumber('غير متوفر'), isNull);
    expect(whatsAppNumber('0', countryCode: 'IQ'), isNull);
  });

  test('formatting characters are stripped', () {
    expect(whatsAppNumber('(0770) 123-4567', countryCode: 'IQ'), '9647701234567');
  });
}
