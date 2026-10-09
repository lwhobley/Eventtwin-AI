import 'package:eventtwin_ai/layout_engine.dart';
import 'package:eventtwin_ai/model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const room = Space(
    id: 'room',
    venueId: 'venue',
    name: 'Ballroom',
    widthMeters: 24.384,
    heightMeters: 18.288,
    verified: true,
  );
  const event = EventRecord(
    id: 'event',
    name: 'Dinner',
    spaceId: 'room',
    beoText: '',
    guests: 120,
    confirmed: true,
  );

  test('converts feet to meters and back', () {
    expect(metersToFeet(feetToMeters(80)), closeTo(80, 0.00001));
  });

  test('generates three distinct feasible table arrangements', () {
    final layouts = generateLayouts(room, event);
    expect(layouts, hasLength(3));
    expect(layouts.map((e) => e.tables.first.x).toSet().length, greaterThan(1));
    for (final layout in layouts) {
      expect(layout.tables, hasLength(12));
      expect(validateLayout(room, layout.tables), isEmpty);
      expect(
        layout.tables.length * seatsPerTable,
        greaterThanOrEqualTo(event.guests),
      );
    }
  });

  test('rejects impossible seating rather than inventing a layout', () {
    expect(
      () => generateLayouts(room, event.copyWith(guests: 2000)),
      throwsStateError,
    );
  });

  test('rejects unverified room and unconfirmed requirements', () {
    const unverified = Space(
      id: 'room',
      venueId: 'venue',
      name: 'Ballroom',
      widthMeters: 24.384,
      heightMeters: 18.288,
      verified: false,
    );
    expect(() => generateLayouts(unverified, event), throwsStateError);
    expect(
      () => generateLayouts(room, event.copyWith(confirmed: false)),
      throwsStateError,
    );
  });

  test('detects boundaries and clearance collisions after edits', () {
    final issues = validateLayout(room, const [
      TablePosition(0.1, 1),
      TablePosition(0.2, 1),
    ]);
    expect(issues.any((issue) => issue.contains('beyond')), isTrue);
    expect(issues.any((issue) => issue.contains('overlap')), isTrue);
  });
}
