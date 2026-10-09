import 'dart:math' as math;

import 'model.dart';

const tableDiameterMeters = 1.8;
const clearanceMeters = 0.9;
const seatsPerTable = 10;

List<String> validateLayout(Space space, List<TablePosition> tables) {
  final issues = <String>[];
  final radius = tableDiameterMeters / 2 + clearanceMeters;
  for (var i = 0; i < tables.length; i++) {
    final table = tables[i];
    if (table.x - radius < 0 ||
        table.y - radius < 0 ||
        table.x + radius > space.widthMeters ||
        table.y + radius > space.heightMeters) {
      issues.add(
        'Table ${i + 1} extends beyond the room or required clearance.',
      );
    }
    for (var j = 0; j < i; j++) {
      if (math.sqrt(
            math.pow(table.x - tables[j].x, 2) +
                math.pow(table.y - tables[j].y, 2),
          ) <
          radius * 2) {
        issues.add(
          'Tables ${j + 1} and ${i + 1} overlap their clearance zones.',
        );
      }
    }
  }
  return issues;
}

List<LayoutPlan> generateLayouts(Space space, EventRecord event) {
  if (!space.verified) throw StateError('Verify room measurements first.');
  if (!event.confirmed || event.guests <= 0) {
    throw StateError('Confirm a positive guest count first.');
  }
  final needed = (event.guests / seatsPerTable).ceil();
  final radius = tableDiameterMeters / 2 + clearanceMeters;
  final spacing = radius * 2 + 0.2;
  final columns = ((space.widthMeters - radius * 2) / spacing).floor() + 1;
  final rows = ((space.heightMeters - radius * 2) / spacing).floor() + 1;
  if (columns <= 0 || rows <= 0) {
    throw StateError('The room is too small for a table with clearance.');
  }

  List<TablePosition>? option(int strategy) {
    final cells = <TablePosition>[];
    for (var row = 0; row < rows; row++) {
      for (var column = 0; column < columns; column++) {
        final x = radius + column * spacing;
        final y = radius + row * spacing;
        if (x + radius <= space.widthMeters &&
            y + radius <= space.heightMeters) {
          cells.add(TablePosition(x, y));
        }
      }
    }
    if (strategy == 1) {
      cells.sort((a, b) {
        final aScore =
            (a.x - space.widthMeters / 2).abs() +
            (a.y - space.heightMeters / 2).abs();
        final bScore =
            (b.x - space.widthMeters / 2).abs() +
            (b.y - space.heightMeters / 2).abs();
        return aScore.compareTo(bScore);
      });
    } else if (strategy == 2) {
      cells.sort((a, b) {
        final aScore = (a.x - space.widthMeters / 2).abs();
        final bScore = (b.x - space.widthMeters / 2).abs();
        return bScore.compareTo(aScore);
      });
    }
    if (cells.length < needed) return null;
    final selected = cells.take(needed).toList();
    return validateLayout(space, selected).isEmpty ? selected : null;
  }

  final candidates = <LayoutPlan>[];
  for (var strategy = 0; strategy < 3; strategy++) {
    final tables = option(strategy);
    if (tables != null) {
      candidates.add(
        LayoutPlan(
          id: '${event.id}-$strategy',
          eventId: event.id,
          name: ['Capacity grid', 'Central cluster', 'Open center'][strategy],
          tables: tables,
          version: 1,
        ),
      );
    }
  }
  if (candidates.length < 3 ||
      candidates
              .map((c) => c.tables.map((t) => '${t.x},${t.y}').join(';'))
              .toSet()
              .length <
          3) {
    throw StateError(
      'Cannot produce three distinct layouts for this room and guest count. Reduce the guest count or use a larger room.',
    );
  }
  return candidates;
}
