import 'package:eventtwin_ai/beo_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('extracts only explicit fields and keeps source lines', () {
    final result = extractExplicitBeoFields(
      'Event: Annual Dinner\nGuests: 120\nSetup: banquet',
    );
    expect(result.eventName, 'Annual Dinner');
    expect(result.guestCount, 120);
    expect(result.eventSource, 'Event: Annual Dinner');
    expect(result.guestSource, 'Guests: 120');
  });

  test('does not invent fields from vague text', () {
    final result = extractExplicitBeoFields(
      'Our annual dinner may host many people.',
    );
    expect(result.eventName, isNull);
    expect(result.guestCount, isNull);
  });
}
