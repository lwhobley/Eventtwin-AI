import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'cloud_layout_codec.dart';
import 'floorplan_view.dart';
import 'layout_engine.dart';
import 'model.dart';

class CloudFloorplansPage extends StatefulWidget {
  const CloudFloorplansPage({
    super.key,
    required this.organizationId,
    required this.canEdit,
    required this.event,
    required this.space,
  });

  final String organizationId;
  final bool canEdit;
  final Map<String, dynamic> event;
  final Map<String, dynamic> space;

  @override
  State<CloudFloorplansPage> createState() => _CloudFloorplansPageState();
}

class _CloudFloorplansPageState extends State<CloudFloorplansPage> {
  late Future<List<LayoutPlan>> _plans;
  String? _selectedId;
  List<TablePosition>? _draft;
  String? _error;
  bool _saving = false;

  SupabaseClient get _client => Supabase.instance.client;

  Space get _room => Space(
    id: widget.space['id'] as String,
    venueId: widget.space['venue_id'] as String,
    name: widget.space['name'] as String,
    widthMeters: (widget.space['width_m'] as num).toDouble(),
    heightMeters: (widget.space['depth_m'] as num).toDouble(),
    verified: widget.space['measurements_verified'] as bool,
  );

  EventRecord get _event => EventRecord(
    id: widget.event['id'] as String,
    name: widget.event['name'] as String,
    spaceId: widget.event['space_id'] as String,
    beoText: widget.event['source_text'] as String,
    guests: widget.event['guest_count'] as int,
    confirmed: widget.event['requirements_confirmed'] as bool,
  );

  @override
  void initState() {
    super.initState();
    _plans = _load();
  }

  Future<List<LayoutPlan>> _load() async {
    final rows = await _client
        .from('floorplans')
        .select('id,event_id,name,version,objects')
        .eq('organization_id', widget.organizationId)
        .eq('event_id', _event.id)
        .order('created_at', ascending: false);
    return [for (final row in rows) cloudLayoutFromRow(row)];
  }

  Future<void> _save(Future<void> Function() action) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await action();
      if (mounted) {
        setState(() {
          _plans = _load();
          _selectedId = null;
          _draft = null;
        });
      }
    } on PostgrestException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on StateError catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Could not save this draft. Check your connection and permissions.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _generate(List<LayoutPlan> existing) => _save(() async {
    final options = generateLayouts(_room, _event);
    await _client.from('floorplans').insert([
      for (final option in options)
        {
          'organization_id': widget.organizationId,
          'event_id': _event.id,
          'name': option.name,
          'version': _nextVersion(existing, option.name),
          'objects': cloudTableObjects(option.tables),
        },
    ]);
  });

  Future<void> _saveEdit(LayoutPlan plan, List<LayoutPlan> existing) =>
      _save(() async {
        await _client.from('floorplans').insert({
          'organization_id': widget.organizationId,
          'event_id': _event.id,
          'name': plan.name,
          'version': _nextVersion(existing, plan.name),
          'objects': cloudTableObjects(_draft!),
        });
      });

  int _nextVersion(List<LayoutPlan> plans, String name) {
    var latest = 0;
    for (final plan in plans) {
      if (plan.name == name && plan.version > latest) latest = plan.version;
    }
    return latest + 1;
  }

  List<String> _issues(List<TablePosition> tables) => [
    if (!_room.verified) 'Room measurements are not verified.',
    if (!_event.confirmed) 'Event requirements are not confirmed.',
    if (tables.length != (_event.guests / seatsPerTable).ceil())
      'Table count no longer matches the confirmed guest count.',
    ...validateLayout(_room, tables),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('${_event.name} · Floor plans')),
    body: FutureBuilder<List<LayoutPlan>>(
      future: _plans,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Could not load floor plans: ${snapshot.error}'),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final plans = snapshot.data!;
        final selectedId = plans.any((p) => p.id == _selectedId)
            ? _selectedId
            : plans.firstOrNull?.id;
        final selected = plans.where((p) => p.id == selectedId).firstOrNull;
        final tables = _draft ?? selected?.tables;
        final issues = tables == null ? <String>[] : _issues(tables);
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Measured floor-plan drafts',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 6),
            const Text(
              'Round tables only. Exits, fixed features, circulation, and accessibility rules are not yet modeled. These plans cannot be approved.',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed:
                      _saving ||
                          !widget.canEdit ||
                          !_room.verified ||
                          !_event.confirmed
                      ? null
                      : () => _generate(plans),
                  icon: const Icon(Icons.auto_fix_high),
                  label: const Text('Generate 3 drafts'),
                ),
                if (plans.isNotEmpty)
                  SizedBox(
                    width: 270,
                    child: DropdownButtonFormField<String>(
                      key: ValueKey(selectedId),
                      initialValue: selectedId,
                      decoration: const InputDecoration(
                        labelText: 'Saved version',
                      ),
                      items: [
                        for (final plan in plans)
                          DropdownMenuItem(
                            value: plan.id,
                            child: Text('${plan.name} · v${plan.version}'),
                          ),
                      ],
                      onChanged: (id) => setState(() {
                        _selectedId = id;
                        _draft = null;
                        _error = null;
                      }),
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed:
                      _saving ||
                          !widget.canEdit ||
                          selected == null ||
                          _draft == null ||
                          issues.isNotEmpty
                      ? null
                      : () => _saveEdit(selected, plans),
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save new version'),
                ),
                OutlinedButton.icon(
                  onPressed:
                      selected == null || _draft != null || issues.isNotEmpty
                      ? null
                      : () =>
                            exportPdf(_room, _event, selected, selected.tables),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Export planning PDF'),
                ),
              ],
            ),
            if (!_room.verified)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'Verify room measurements before generating drafts.',
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (_saving) const LinearProgressIndicator(),
            const SizedBox(height: 18),
            if (selected != null && tables != null) ...[
              Text(
                '${_room.name} · ${metersToFeet(_room.widthMeters).toStringAsFixed(1)} × ${metersToFeet(_room.heightMeters).toStringAsFixed(1)} ft · ${tables.length} tables · ${tables.length * seatsPerTable} seats',
              ),
              const SizedBox(height: 10),
              LayoutCanvas(
                space: _room,
                tables: tables,
                onMoved: widget.canEdit
                    ? (index, position) => setState(() {
                        final next = [...tables];
                        next[index] = position;
                        _draft = next;
                      })
                    : null,
              ),
              const SizedBox(height: 10),
              Text(
                issues.isEmpty
                    ? 'No table boundary or clearance conflicts detected. Server checks again when saving.'
                    : issues.join('\n'),
                style: TextStyle(
                  color: issues.isEmpty ? const Color(0xff176e72) : Colors.red,
                ),
              ),
            ] else
              const Text(
                'No saved drafts yet. Generate three options to compare.',
              ),
          ],
        );
      },
    ),
  );
}
