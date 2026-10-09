import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'model.dart' show feetToMeters, metersToFeet;

class CloudWorkspacePage extends StatefulWidget {
  const CloudWorkspacePage({
    super.key,
    required this.organization,
    required this.onBack,
    required this.onSignOut,
  });
  final Map<String, dynamic> organization;
  final VoidCallback onBack;
  final Future<void> Function() onSignOut;

  @override
  State<CloudWorkspacePage> createState() => _CloudWorkspacePageState();
}

class _CloudWorkspacePageState extends State<CloudWorkspacePage> {
  late Future<_CloudSnapshot> _snapshot;
  String? _error;
  SupabaseClient get _client => Supabase.instance.client;
  String get _organizationId => widget.organization['id'] as String;

  @override
  void initState() {
    super.initState();
    _snapshot = _load();
  }

  Future<_CloudSnapshot> _load() async {
    final results = await Future.wait([
      _client
          .from('venues')
          .select('id,name')
          .eq('organization_id', _organizationId)
          .order('created_at'),
      _client
          .from('spaces')
          .select('id,venue_id,name,width_m,depth_m,measurements_verified')
          .eq('organization_id', _organizationId)
          .order('created_at'),
      _client
          .from('events')
          .select(
            'id,space_id,name,guest_count,source_text,requirements_confirmed',
          )
          .eq('organization_id', _organizationId)
          .order('created_at', ascending: false),
    ]);
    return _CloudSnapshot(
      venues: List<Map<String, dynamic>>.from(results[0]),
      spaces: List<Map<String, dynamic>>.from(results[1]),
      events: List<Map<String, dynamic>>.from(results[2]),
    );
  }

  void _refresh() {
    setState(() {
      _snapshot = _load();
      _error = null;
    });
  }

  Future<void> _createVenue() async {
    final name = await _textDialog('New venue', 'Venue name');
    if (name == null) return;
    await _write(() async {
      await _client.from('venues').insert({
        'organization_id': _organizationId,
        'name': name,
      });
    });
  }

  Future<void> _createSpace(List<Map<String, dynamic>> venues) async {
    if (venues.isEmpty) {
      setState(() => _error = 'Create a venue before adding a room.');
      return;
    }
    final result = await showDialog<_SpaceInput>(
      context: context,
      builder: (context) => _SpaceDialog(venues: venues),
    );
    if (result == null) return;
    await _write(() async {
      await _client.from('spaces').insert({
        'organization_id': _organizationId,
        'venue_id': result.venueId,
        'name': result.name,
        'width_m': feetToMeters(result.widthFeet),
        'depth_m': feetToMeters(result.depthFeet),
        'measurements_verified': result.verified,
      });
    });
  }

  Future<void> _createEvent(List<Map<String, dynamic>> spaces) async {
    if (spaces.isEmpty) {
      setState(() => _error = 'Create a room before adding an event.');
      return;
    }
    final result = await showDialog<_EventInput>(
      context: context,
      builder: (context) => _EventDialog(spaces: spaces),
    );
    if (result == null) return;
    await _write(() async {
      await _client.from('events').insert({
        'organization_id': _organizationId,
        'space_id': result.spaceId,
        'name': result.name,
        'guest_count': result.guestCount,
        'source_text': result.sourceText,
      });
    });
  }

  Future<void> _confirmEvent(String id) async {
    await _write(() async {
      await _client
          .from('events')
          .update({'requirements_confirmed': true})
          .eq('id', id)
          .eq('organization_id', _organizationId);
    });
  }

  Future<void> _write(Future<void> Function() action) async {
    try {
      await action();
      if (mounted) _refresh();
    } on PostgrestException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Could not save this change. Check your connection and permissions.',
        );
      }
    }
  }

  Future<String?> _textDialog(String title, String label) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    final value = controller.text.trim();
    controller.dispose();
    return confirmed == true && value.isNotEmpty ? value : null;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.organization['name'] as String),
      actions: [
        IconButton(
          tooltip: 'Change organization',
          onPressed: widget.onBack,
          icon: const Icon(Icons.apartment),
        ),
        IconButton(
          tooltip: 'Sign out',
          onPressed: widget.onSignOut,
          icon: const Icon(Icons.logout),
        ),
      ],
    ),
    body: FutureBuilder<_CloudSnapshot>(
      future: _snapshot,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Could not load this organization. Check that the migration has been applied and that your role allows access.\n\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Cloud workspace',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const Text(
              'Venue, room, and event records are stored in Supabase and filtered by database row-level security.',
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: _createVenue,
                  icon: const Icon(Icons.add),
                  label: const Text('New venue'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _createSpace(data.venues),
                  icon: const Icon(Icons.add),
                  label: const Text('Add room'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _createEvent(data.spaces),
                  icon: const Icon(Icons.add),
                  label: const Text('New event'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Venues & rooms',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            for (final venue in data.venues)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        venue['name'] as String,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      for (final space in data.spaces.where(
                        (s) => s['venue_id'] == venue['id'],
                      ))
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(space['name'] as String),
                          subtitle: Text(
                            '${metersToFeet((space['width_m'] as num).toDouble()).toStringAsFixed(1)} × ${metersToFeet((space['depth_m'] as num).toDouble()).toStringAsFixed(1)} ft · ${space['measurements_verified'] == true ? 'verified measurements' : 'unverified measurements'}',
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            if (data.venues.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('No venues yet.'),
              ),
            const SizedBox(height: 18),
            Text('Events', style: Theme.of(context).textTheme.titleLarge),
            for (final event in data.events)
              Card(
                child: ListTile(
                  title: Text(event['name'] as String),
                  subtitle: Text(
                    '${event['guest_count']} guests · ${event['requirements_confirmed'] == true ? 'confirmed' : 'draft'}',
                  ),
                  trailing: event['requirements_confirmed'] == true
                      ? const Icon(Icons.check_circle_outline)
                      : TextButton(
                          onPressed: () => _confirmEvent(event['id'] as String),
                          child: const Text('Confirm'),
                        ),
                ),
              ),
            if (data.events.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('No events yet.'),
              ),
          ],
        );
      },
    ),
  );
}

class _CloudSnapshot {
  const _CloudSnapshot({
    required this.venues,
    required this.spaces,
    required this.events,
  });
  final List<Map<String, dynamic>> venues;
  final List<Map<String, dynamic>> spaces;
  final List<Map<String, dynamic>> events;
}

class _SpaceInput {
  const _SpaceInput({
    required this.venueId,
    required this.name,
    required this.widthFeet,
    required this.depthFeet,
    required this.verified,
  });
  final String venueId, name;
  final double widthFeet, depthFeet;
  final bool verified;
}

class _SpaceDialog extends StatefulWidget {
  const _SpaceDialog({required this.venues});
  final List<Map<String, dynamic>> venues;
  @override
  State<_SpaceDialog> createState() => _SpaceDialogState();
}

class _SpaceDialogState extends State<_SpaceDialog> {
  final _name = TextEditingController();
  final _width = TextEditingController();
  final _depth = TextEditingController();
  late String _venueId = widget.venues.first['id'] as String;
  bool _verified = false;

  @override
  void dispose() {
    _name.dispose();
    _width.dispose();
    _depth.dispose();
    super.dispose();
  }

  void _save() {
    final width = double.tryParse(_width.text);
    final depth = double.tryParse(_depth.text);
    if (_name.text.trim().isEmpty ||
        width == null ||
        depth == null ||
        width <= 0 ||
        depth <= 0) {
      return;
    }
    Navigator.pop(
      context,
      _SpaceInput(
        venueId: _venueId,
        name: _name.text.trim(),
        widthFeet: width,
        depthFeet: depth,
        verified: _verified,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Add measured room'),
    content: SizedBox(
      width: 400,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _venueId,
            items: [
              for (final venue in widget.venues)
                DropdownMenuItem(
                  value: venue['id'] as String,
                  child: Text(venue['name'] as String),
                ),
            ],
            onChanged: (id) => setState(() => _venueId = id ?? _venueId),
          ),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Room name'),
          ),
          TextField(
            controller: _width,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Width (feet)'),
          ),
          TextField(
            controller: _depth,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Depth (feet)'),
          ),
          CheckboxListTile(
            value: _verified,
            onChanged: (value) => setState(() => _verified = value ?? false),
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
      FilledButton(onPressed: _save, child: const Text('Save')),
    ],
  );
}

class _EventInput {
  const _EventInput({
    required this.spaceId,
    required this.name,
    required this.guestCount,
    required this.sourceText,
  });
  final String spaceId, name, sourceText;
  final int guestCount;
}

class _EventDialog extends StatefulWidget {
  const _EventDialog({required this.spaces});
  final List<Map<String, dynamic>> spaces;
  @override
  State<_EventDialog> createState() => _EventDialogState();
}

class _EventDialogState extends State<_EventDialog> {
  final _name = TextEditingController();
  final _guests = TextEditingController();
  final _source = TextEditingController();
  late String _spaceId = widget.spaces.first['id'] as String;

  @override
  void dispose() {
    _name.dispose();
    _guests.dispose();
    _source.dispose();
    super.dispose();
  }

  void _save() {
    final guests = int.tryParse(_guests.text);
    if (_name.text.trim().isEmpty || guests == null || guests <= 0) return;
    Navigator.pop(
      context,
      _EventInput(
        spaceId: _spaceId,
        name: _name.text.trim(),
        guestCount: guests,
        sourceText: _source.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Create event draft'),
    content: SizedBox(
      width: 420,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _spaceId,
              items: [
                for (final space in widget.spaces)
                  DropdownMenuItem(
                    value: space['id'] as String,
                    child: Text(
                      '${space['name']}${space['measurements_verified'] == true ? '' : ' · unverified room'}',
                    ),
                  ),
              ],
              onChanged: (id) => setState(() => _spaceId = id ?? _spaceId),
            ),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Event name'),
            ),
            TextField(
              controller: _guests,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Guest count'),
            ),
            TextField(
              controller: _source,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'BEO text (optional)',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'New events are saved unconfirmed. Review the source before confirming.',
              textAlign: TextAlign.left,
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
      FilledButton(onPressed: _save, child: const Text('Save draft')),
    ],
  );
}
