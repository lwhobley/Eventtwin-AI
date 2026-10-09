import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'model.dart';

final initialDataProvider = Provider<ProjectData>((ref) => const ProjectData());
final preferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(),
);
final workspaceProvider = NotifierProvider<WorkspaceController, ProjectData>(
  WorkspaceController.new,
);

class WorkspaceController extends Notifier<ProjectData> {
  @override
  ProjectData build() => ref.read(initialDataProvider);

  void _save(ProjectData next) {
    state = next;
    ref
        .read(preferencesProvider)
        .setString('eventtwin_local_workspace_v1', next.encode());
  }

  void setOrganization(String name) =>
      _save(state.copyWith(organization: name));
  void addVenue(Venue venue) =>
      _save(state.copyWith(venues: [...state.venues, venue]));
  void addSpace(Space space) =>
      _save(state.copyWith(spaces: [...state.spaces, space]));
  void addEvent(EventRecord event) =>
      _save(state.copyWith(events: [...state.events, event]));
  void confirmEvent(String id) => _save(
    state.copyWith(
      events: [
        for (final event in state.events)
          event.id == id ? event.copyWith(confirmed: true) : event,
      ],
    ),
  );
  void saveLayouts(List<LayoutPlan> plans) {
    final ids = plans.map((p) => p.id).toSet();
    _save(
      state.copyWith(
        layouts: [...state.layouts.where((p) => !ids.contains(p.id)), ...plans],
      ),
    );
  }
}
