import 'package:eventtwin_ai/cloud_layout_codec.dart';
import 'package:eventtwin_ai/model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cloud floor-plan coordinates remain in meters', () {
    final objects = cloudTableObjects(const [TablePosition(3.5, 7.25)]);
    expect(objects.single, {'type': 'round_table', 'x_m': 3.5, 'y_m': 7.25});

    final plan = cloudLayoutFromRow({
      'id': 'plan',
      'event_id': 'event',
      'name': 'Capacity grid',
      'version': 2,
      'objects': objects,
    });
    expect(plan.version, 2);
    expect(plan.tables.single.x, 3.5);
    expect(plan.tables.single.y, 7.25);
  });
}
