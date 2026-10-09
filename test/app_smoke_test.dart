import 'package:eventtwin_ai/main.dart';
import 'package:eventtwin_ai/model.dart';
import 'package:eventtwin_ai/workspace.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('local app opens its overview with demo notice', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesProvider.overrideWithValue(preferences),
          initialDataProvider.overrideWithValue(const ProjectData()),
        ],
        child: const EventTwinApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('EventTwin AI'), findsOneWidget);
    expect(find.textContaining('LOCAL DEMO'), findsOneWidget);
    expect(find.text('Plan events with measured spaces'), findsOneWidget);
  });
}
