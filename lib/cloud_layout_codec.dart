import 'model.dart';

List<Map<String, dynamic>> cloudTableObjects(List<TablePosition> tables) => [
  for (final table in tables)
    {'type': 'round_table', 'x_m': table.x, 'y_m': table.y},
];

LayoutPlan cloudLayoutFromRow(Map<String, dynamic> row) => LayoutPlan(
  id: row['id'] as String,
  eventId: row['event_id'] as String,
  name: row['name'] as String,
  version: row['version'] as int,
  tables: [
    for (final object in row['objects'] as List)
      TablePosition(
        (object['x_m'] as num).toDouble(),
        (object['y_m'] as num).toDouble(),
      ),
  ],
);
