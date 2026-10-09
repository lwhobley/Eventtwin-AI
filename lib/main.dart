import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'beo_parser.dart';

import 'layout_engine.dart';
import 'model.dart';
import 'workspace.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString('eventtwin_local_workspace_v1');
  ProjectData initial;
  try {
    initial = saved == null ? const ProjectData() : ProjectData.decode(saved);
  } catch (_) {
    initial = const ProjectData();
  }
  runApp(
    ProviderScope(
      overrides: [
        preferencesProvider.overrideWithValue(prefs),
        initialDataProvider.overrideWithValue(initial),
      ],
      child: const EventTwinApp(),
    ),
  );
}

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (_, _) => const AppShell(index: 0, child: OverviewPage()),
    ),
    GoRoute(
      path: '/venues',
      builder: (_, _) => const AppShell(index: 1, child: VenuesPage()),
    ),
    GoRoute(
      path: '/events',
      builder: (_, _) => const AppShell(index: 2, child: EventsPage()),
    ),
    GoRoute(
      path: '/studio',
      builder: (_, _) => const AppShell(index: 3, child: StudioPage()),
    ),
  ],
);

class EventTwinApp extends StatelessWidget {
  const EventTwinApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'EventTwin AI',
    routerConfig: router,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xff176e72),
        surface: const Color(0xfff8f8f5),
      ),
      scaffoldBackgroundColor: const Color(0xfff8f8f5),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xff10283c),
        foregroundColor: Colors.white,
      ),
    ),
    debugShowCheckedModeBanner: false,
  );
}

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.index, required this.child});
  final int index;
  final Widget child;
  static const destinations = [
    (Icons.dashboard_outlined, 'Overview', '/'),
    (Icons.meeting_room_outlined, 'Venues', '/venues'),
    (Icons.event_note_outlined, 'Events', '/events'),
    (Icons.architecture_outlined, 'Studio', '/studio'),
  ];
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wide = MediaQuery.sizeOf(context).width >= 850;
    final data = ref.watch(workspaceProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('EventTwin AI'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: Center(child: Text(data.organization)),
          ),
        ],
      ),
      body: Row(
        children: [
          if (wide)
            NavigationRail(
              backgroundColor: const Color(0xff10283c),
              selectedIconTheme: const IconThemeData(color: Color(0xffd3ad72)),
              unselectedIconTheme: const IconThemeData(color: Colors.white70),
              selectedLabelTextStyle: const TextStyle(color: Colors.white),
              unselectedLabelTextStyle: const TextStyle(color: Colors.white70),
              extended: MediaQuery.sizeOf(context).width >= 1100,
              selectedIndex: index,
              onDestinationSelected: (i) => context.go(destinations[i].$3),
              destinations: [
                for (final d in destinations)
                  NavigationRailDestination(
                    icon: Icon(d.$1),
                    label: Text(d.$2),
                  ),
              ],
            ),
          Expanded(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  color: const Color(0xfffff3d8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 7,
                  ),
                  child: const Text(
                    'LOCAL DEMO · Data is stored on this device. No cloud account or tenant security is active.',
                  ),
                ),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: index,
              onDestinationSelected: (i) => context.go(destinations[i].$3),
              destinations: [
                for (final d in destinations)
                  NavigationDestination(icon: Icon(d.$1), label: d.$2),
              ],
            ),
    );
  }
}

Widget pageFrame(String title, String subtitle, List<Widget> children) =>
    ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: Color(0xff10283c),
          ),
        ),
        const SizedBox(height: 5),
        Text(subtitle),
        const SizedBox(height: 22),
        ...children,
      ],
    );

class OverviewPage extends ConsumerWidget {
  const OverviewPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(workspaceProvider);
    return pageFrame(
      'Plan events with measured spaces',
      'Create a venue and room, confirm event requirements, then compare validated table layouts.',
      [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _Stat('Venues', '${data.venues.length}', Icons.apartment),
            _Stat('Spaces', '${data.spaces.length}', Icons.crop_square),
            _Stat('Events', '${data.events.length}', Icons.event),
            _Stat('Saved layouts', '${data.layouts.length}', Icons.grid_on),
          ],
        ),
        const SizedBox(height: 25),
        FilledButton.icon(
          onPressed: () => context.go('/venues'),
          icon: const Icon(Icons.add),
          label: const Text('Start with a venue'),
        ),
        const SizedBox(height: 20),
        const Text(
          'Current scope: rectangular verified rooms, round banquet tables, explicit guest counts, local persistence, and dimensioned PDF export. Layouts are planning drafts; exits and fixed features are not yet modeled.',
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.icon);
  final String label, value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    width: 190,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: Colors.black12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xff176e72)),
        const SizedBox(height: 15),
        Text(
          value,
          style: const TextStyle(fontSize: 29, fontWeight: FontWeight.bold),
        ),
        Text(label),
      ],
    ),
  );
}

class VenuesPage extends ConsumerWidget {
  const VenuesPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(workspaceProvider);
    return pageFrame(
      'Venues & spaces',
      'Enter real measurements and explicitly verify them.',
      [
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: () => _createVenue(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('New venue'),
          ),
        ),
        const SizedBox(height: 16),
        for (final venue in data.venues)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    venue.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  for (final space in data.spaces.where(
                    (s) => s.venueId == venue.id,
                  ))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(space.name),
                      subtitle: Text(
                        '${metersToFeet(space.widthMeters).toStringAsFixed(1)} × ${metersToFeet(space.heightMeters).toStringAsFixed(1)} ft · ${space.verified ? 'Measurements verified' : 'Unverified'}',
                      ),
                    ),
                  TextButton.icon(
                    onPressed: () => _createSpace(context, ref, venue.id),
                    icon: const Icon(Icons.add),
                    label: const Text('Add measured space'),
                  ),
                ],
              ),
            ),
          ),
        if (data.venues.isEmpty)
          const Text('No venues yet. Create one to begin.'),
      ],
    );
  }
}

Future<void> _createVenue(BuildContext context, WidgetRef ref) async {
  final name = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('New venue'),
      content: TextField(
        controller: name,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Venue name'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, name.text.trim()),
          child: const Text('Create'),
        ),
      ],
    ),
  );
  name.dispose();
  if (result != null && result.isNotEmpty) {
    ref
        .read(workspaceProvider.notifier)
        .addVenue(
          Venue(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            name: result,
          ),
        );
  }
}

Future<void> _createSpace(
  BuildContext context,
  WidgetRef ref,
  String venueId,
) async {
  final name = TextEditingController();
  final width = TextEditingController();
  final height = TextEditingController();
  var verified = false;
  final result = await showDialog<Space>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Measured space'),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Room name'),
              ),
              TextField(
                controller: width,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Width (feet)'),
              ),
              TextField(
                controller: height,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Depth (feet)'),
              ),
              CheckboxListTile(
                value: verified,
                onChanged: (v) => setDialogState(() => verified = v ?? false),
                title: const Text('I verified these measurements'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final w = double.tryParse(width.text),
                  h = double.tryParse(height.text);
              if (name.text.trim().isEmpty ||
                  w == null ||
                  h == null ||
                  w <= 0 ||
                  h <= 0) {
                return;
              }
              Navigator.pop(
                context,
                Space(
                  id: DateTime.now().microsecondsSinceEpoch.toString(),
                  venueId: venueId,
                  name: name.text.trim(),
                  widthMeters: feetToMeters(w),
                  heightMeters: feetToMeters(h),
                  verified: verified,
                ),
              );
            },
            child: const Text('Save room'),
          ),
        ],
      ),
    ),
  );
  name.dispose();
  width.dispose();
  height.dispose();
  if (result != null) ref.read(workspaceProvider.notifier).addSpace(result);
}

const sampleBeo =
    'SAMPLE CORPORATE BANQUET BEO\nEvent: Annual Leadership Dinner\nGuests: 120\nSetup: Round banquet tables\nNote: Demonstration only. Confirm all requirements against the actual BEO.';

class EventsPage extends ConsumerWidget {
  const EventsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(workspaceProvider);
    return pageFrame(
      'Events & BEOs',
      'Paste BEO text or enter event details. Review the extracted guest count before layout generation.',
      [
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: data.spaces.isEmpty
                ? null
                : () => _createEvent(context, ref, data.spaces),
            icon: const Icon(Icons.add),
            label: const Text('New event'),
          ),
        ),
        const SizedBox(height: 16),
        for (final event in data.events)
          Card(
            child: ListTile(
              title: Text(event.name),
              subtitle: Text(
                '${event.guests} guests · ${event.confirmed ? 'Confirmed' : 'Requires confirmation'} · ${data.spaces.where((s) => s.id == event.spaceId).firstOrNull?.name ?? 'Missing room'}',
              ),
              trailing: event.confirmed
                  ? const Icon(Icons.check_circle, color: Color(0xff176e72))
                  : TextButton(
                      onPressed: () => _reviewEvent(context, ref, event),
                      child: const Text('Review & confirm'),
                    ),
            ),
          ),
        if (data.spaces.isEmpty) const Text('Create a measured room first.'),
      ],
    );
  }
}

Future<void> _createEvent(
  BuildContext context,
  WidgetRef ref,
  List<Space> spaces,
) async {
  final name = TextEditingController();
  final guests = TextEditingController();
  final beo = TextEditingController();
  var spaceId = spaces.first.id;
  final result = await showDialog<EventRecord>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('New event'),
        content: SizedBox(
          width: 450,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: spaceId,
                  decoration: const InputDecoration(labelText: 'Room'),
                  items: [
                    for (final s in spaces)
                      DropdownMenuItem(value: s.id, child: Text(s.name)),
                  ],
                  onChanged: (v) =>
                      setDialogState(() => spaceId = v ?? spaceId),
                ),
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Event name'),
                ),
                TextField(
                  controller: guests,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Guest count (confirm manually)',
                  ),
                ),
                TextField(
                  controller: beo,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Original BEO text',
                  ),
                ),
                TextButton(
                  onPressed: () => beo.text = sampleBeo,
                  child: const Text('Use labeled sample BEO'),
                ),
                TextButton.icon(
                  onPressed: () {
                    final extracted = extractExplicitBeoFields(beo.text);
                    if (extracted.eventName != null) {
                      name.text = extracted.eventName!;
                    }
                    if (extracted.guestCount != null) {
                      guests.text = '${extracted.guestCount}';
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          extracted.eventName == null &&
                                  extracted.guestCount == null
                              ? 'No explicit Event: or Guests: lines found. Enter details manually.'
                              : 'Copied explicit fields from BEO text. Review before confirming.',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.text_snippet_outlined),
                  label: const Text('Extract explicit fields'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final count = int.tryParse(guests.text);
              if (name.text.trim().isEmpty || count == null || count <= 0) {
                return;
              }
              Navigator.pop(
                context,
                EventRecord(
                  id: DateTime.now().microsecondsSinceEpoch.toString(),
                  name: name.text.trim(),
                  spaceId: spaceId,
                  beoText: beo.text.trim(),
                  guests: count,
                  confirmed: false,
                ),
              );
            },
            child: const Text('Save draft'),
          ),
        ],
      ),
    ),
  );
  name.dispose();
  guests.dispose();
  beo.dispose();
  if (result != null) ref.read(workspaceProvider.notifier).addEvent(result);
}

Future<void> _reviewEvent(
  BuildContext context,
  WidgetRef ref,
  EventRecord event,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Confirm event requirements'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Event: ${event.name}\nGuests: ${event.guests}\nSeating: round banquet tables, 10 seats each',
              ),
              const SizedBox(height: 12),
              const Text(
                'Original BEO / entry:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                event.beoText.isEmpty
                    ? 'No BEO text supplied. This is manual entry.'
                    : event.beoText,
              ),
              const SizedBox(height: 12),
              const Text(
                'Confirm the guest count and seating assumption against the source. Other BEO details are not extracted yet.',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Confirm'),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    ref.read(workspaceProvider.notifier).confirmEvent(event.id);
  }
}

class StudioPage extends ConsumerStatefulWidget {
  const StudioPage({super.key});
  @override
  ConsumerState<StudioPage> createState() => _StudioPageState();
}

class _StudioPageState extends ConsumerState<StudioPage> {
  String? eventId;
  String? layoutId;
  List<TablePosition>? draft;
  String? error;

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(workspaceProvider);
    final events = data.events.where((e) => e.confirmed).toList();
    final selectedEventId = events.any((e) => e.id == eventId)
        ? eventId
        : events.firstOrNull?.id;
    final event = events.where((e) => e.id == selectedEventId).firstOrNull;
    final space = data.spaces.where((s) => s.id == event?.spaceId).firstOrNull;
    final layouts = data.layouts
        .where((p) => p.eventId == selectedEventId)
        .toList();
    final selectedLayoutId = layouts.any((p) => p.id == layoutId)
        ? layoutId
        : layouts.firstOrNull?.id;
    final layout = layouts.where((p) => p.id == selectedLayoutId).firstOrNull;
    final tables = draft ?? layout?.tables;
    final issues = space == null || tables == null
        ? <String>[]
        : validateLayout(space, tables);
    return pageFrame(
      'Floor Plan Studio',
      'Generate and edit measured table plans. Planning draft only until exits and fixed room features are modeled.',
      [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 240,
              child: DropdownButtonFormField<String>(
                initialValue: selectedEventId,
                decoration: const InputDecoration(labelText: 'Confirmed event'),
                items: [
                  for (final e in events)
                    DropdownMenuItem(value: e.id, child: Text(e.name)),
                ],
                onChanged: (v) => setState(() {
                  eventId = v;
                  layoutId = null;
                  draft = null;
                  error = null;
                }),
              ),
            ),
            FilledButton.icon(
              onPressed: event == null || space == null
                  ? null
                  : () {
                      try {
                        final generated = generateLayouts(space, event);
                        ref
                            .read(workspaceProvider.notifier)
                            .saveLayouts(generated);
                        setState(() {
                          layoutId = generated.first.id;
                          draft = null;
                          error = null;
                        });
                      } catch (e) {
                        setState(
                          () => error = e.toString().replaceFirst(
                            'Bad state: ',
                            '',
                          ),
                        );
                      }
                    },
              icon: const Icon(Icons.auto_fix_high),
              label: const Text('Generate 3 layouts'),
            ),
            if (layouts.isNotEmpty)
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String>(
                  key: ValueKey(selectedLayoutId),
                  initialValue: selectedLayoutId,
                  decoration: const InputDecoration(labelText: 'Layout option'),
                  items: [
                    for (final p in layouts)
                      DropdownMenuItem(value: p.id, child: Text(p.name)),
                  ],
                  onChanged: (v) => setState(() {
                    layoutId = v;
                    draft = null;
                    error = null;
                  }),
                ),
              ),
            OutlinedButton.icon(
              onPressed: draft == null || layout == null || issues.isNotEmpty
                  ? null
                  : () {
                      ref.read(workspaceProvider.notifier).saveLayouts([
                        layout.copyWith(
                          tables: draft,
                          version: layout.version + 1,
                        ),
                      ]);
                      setState(() {
                        draft = null;
                        error = null;
                      });
                    },
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save edit'),
            ),
            OutlinedButton.icon(
              onPressed:
                  layout == null ||
                      space == null ||
                      tables == null ||
                      issues.isNotEmpty
                  ? null
                  : () => _exportPdf(space, event!, layout, tables),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Export PDF'),
            ),
          ],
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text(error!, style: const TextStyle(color: Colors.red)),
          ),
        const SizedBox(height: 20),
        if (space != null && tables != null) ...[
          Text(
            '${space.name} · ${metersToFeet(space.widthMeters).toStringAsFixed(1)} × ${metersToFeet(space.heightMeters).toStringAsFixed(1)} ft · ${tables.length} tables · ${tables.length * seatsPerTable} seats · version ${layout?.version ?? 1}',
          ),
          const SizedBox(height: 10),
          LayoutCanvas(
            space: space,
            tables: tables,
            onMoved: (index, position) {
              setState(() {
                final next = [...tables];
                next[index] = position;
                draft = next;
              });
            },
          ),
          const SizedBox(height: 10),
          Text(
            issues.isEmpty
                ? 'No table boundary or clearance conflicts detected.'
                : issues.join('\n'),
            style: TextStyle(
              color: issues.isEmpty ? const Color(0xff176e72) : Colors.red,
            ),
          ),
        ] else
          const Text('Confirm an event, then generate its layouts.'),
      ],
    );
  }
}

class LayoutCanvas extends StatefulWidget {
  const LayoutCanvas({
    super.key,
    required this.space,
    required this.tables,
    required this.onMoved,
  });
  final Space space;
  final List<TablePosition> tables;
  final void Function(int, TablePosition) onMoved;
  @override
  State<LayoutCanvas> createState() => _LayoutCanvasState();
}

class _LayoutCanvasState extends State<LayoutCanvas> {
  int? selected;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = math.min(constraints.maxWidth, 900.0);
      final height =
          width * widget.space.heightMeters / widget.space.widthMeters;
      return SizedBox(
        width: width,
        height: height,
        child: GestureDetector(
          onPanStart: (details) {
            final point = details.localPosition;
            final x = point.dx / width * widget.space.widthMeters;
            final y = point.dy / height * widget.space.heightMeters;
            var distance = double.infinity;
            int? nearest;
            for (var i = 0; i < widget.tables.length; i++) {
              final d = math.sqrt(
                math.pow(widget.tables[i].x - x, 2) +
                    math.pow(widget.tables[i].y - y, 2),
              );
              if (d < tableDiameterMeters && d < distance) {
                distance = d;
                nearest = i;
              }
            }
            selected = nearest;
          },
          onPanUpdate: (details) {
            if (selected == null) return;
            widget.onMoved(
              selected!,
              TablePosition(
                details.localPosition.dx / width * widget.space.widthMeters,
                details.localPosition.dy / height * widget.space.heightMeters,
              ),
            );
          },
          onPanEnd: (_) => selected = null,
          child: CustomPaint(
            painter: _RoomPainter(widget.space, widget.tables),
            size: Size(width, height),
          ),
        ),
      );
    },
  );
}

class _RoomPainter extends CustomPainter {
  _RoomPainter(this.space, this.tables);
  final Space space;
  final List<TablePosition> tables;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..color = const Color(0xff10283c)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    final scale = size.width / space.widthMeters;
    for (var i = 0; i < tables.length; i++) {
      final center = Offset(tables[i].x * scale, tables[i].y * scale);
      canvas.drawCircle(
        center,
        tableDiameterMeters / 2 * scale,
        Paint()..color = const Color(0xffb78c58),
      );
      canvas.drawCircle(
        center,
        tableDiameterMeters / 2 * scale,
        Paint()
          ..color = const Color(0xff10283c)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      final text = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: const TextStyle(color: Colors.white, fontSize: 11),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, center - Offset(text.width / 2, text.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _RoomPainter oldDelegate) =>
      oldDelegate.tables != tables || oldDelegate.space != space;
}

Future<void> _exportPdf(
  Space space,
  EventRecord event,
  LayoutPlan layout,
  List<TablePosition> tables,
) async {
  final doc = pw.Document();
  const planWidth = 480.0;
  final planHeight = planWidth * space.heightMeters / space.widthMeters;
  final scale = planWidth / space.widthMeters;
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'EventTwin AI | Planning draft',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text('${event.name} · ${layout.name} · Version ${layout.version}'),
          pw.Text(
            '${space.name}: ${metersToFeet(space.widthMeters).toStringAsFixed(1)} × ${metersToFeet(space.heightMeters).toStringAsFixed(1)} ft',
          ),
          pw.Text(
            '${tables.length} round tables · ${tables.length * seatsPerTable} seats',
          ),
          pw.SizedBox(height: 16),
          pw.Container(
            width: planWidth,
            height: planHeight,
            decoration: pw.BoxDecoration(border: pw.Border.all()),
            child: pw.Stack(
              children: [
                for (var i = 0; i < tables.length; i++)
                  pw.Positioned(
                    left: tables[i].x * scale - tableDiameterMeters / 2 * scale,
                    top: tables[i].y * scale - tableDiameterMeters / 2 * scale,
                    child: pw.Container(
                      width: tableDiameterMeters * scale,
                      height: tableDiameterMeters * scale,
                      decoration: pw.BoxDecoration(
                        shape: pw.BoxShape.circle,
                        color: PdfColors.brown300,
                      ),
                      alignment: pw.Alignment.center,
                      child: pw.Text('${i + 1}'),
                    ),
                  ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Measurements are based on user-verified room dimensions. Exits and fixed features are not modeled; this is not a final safety or code-compliance approval.',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    ),
  );
  await Printing.layoutPdf(
    onLayout: (_) => doc.save(),
    name: 'eventtwin-${event.id}-${layout.version}.pdf',
  );
}
