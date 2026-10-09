import 'dart:convert';

const feetPerMeter = 3.280839895;

double feetToMeters(double feet) => feet / feetPerMeter;
double metersToFeet(double meters) => meters * feetPerMeter;

class Venue {
  const Venue({required this.id, required this.name});
  final String id;
  final String name;

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
  factory Venue.fromJson(Map<String, dynamic> data) =>
      Venue(id: data['id'] as String, name: data['name'] as String);
}

class Space {
  const Space({
    required this.id,
    required this.venueId,
    required this.name,
    required this.widthMeters,
    required this.heightMeters,
    required this.verified,
  });
  final String id;
  final String venueId;
  final String name;
  final double widthMeters;
  final double heightMeters;
  final bool verified;

  Map<String, dynamic> toJson() => {
    'id': id,
    'venueId': venueId,
    'name': name,
    'widthMeters': widthMeters,
    'heightMeters': heightMeters,
    'verified': verified,
  };
  factory Space.fromJson(Map<String, dynamic> data) => Space(
    id: data['id'] as String,
    venueId: data['venueId'] as String,
    name: data['name'] as String,
    widthMeters: (data['widthMeters'] as num).toDouble(),
    heightMeters: (data['heightMeters'] as num).toDouble(),
    verified: data['verified'] as bool,
  );
}

class EventRecord {
  const EventRecord({
    required this.id,
    required this.name,
    required this.spaceId,
    required this.beoText,
    required this.guests,
    required this.confirmed,
  });
  final String id;
  final String name;
  final String spaceId;
  final String beoText;
  final int guests;
  final bool confirmed;

  EventRecord copyWith({
    String? name,
    String? beoText,
    int? guests,
    bool? confirmed,
  }) => EventRecord(
    id: id,
    name: name ?? this.name,
    spaceId: spaceId,
    beoText: beoText ?? this.beoText,
    guests: guests ?? this.guests,
    confirmed: confirmed ?? this.confirmed,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'spaceId': spaceId,
    'beoText': beoText,
    'guests': guests,
    'confirmed': confirmed,
  };
  factory EventRecord.fromJson(Map<String, dynamic> data) => EventRecord(
    id: data['id'] as String,
    name: data['name'] as String,
    spaceId: data['spaceId'] as String,
    beoText: data['beoText'] as String,
    guests: data['guests'] as int,
    confirmed: data['confirmed'] as bool,
  );
}

class TablePosition {
  const TablePosition(this.x, this.y);
  final double x;
  final double y;
  Map<String, dynamic> toJson() => {'x': x, 'y': y};
  factory TablePosition.fromJson(Map<String, dynamic> data) => TablePosition(
    (data['x'] as num).toDouble(),
    (data['y'] as num).toDouble(),
  );
}

class LayoutPlan {
  const LayoutPlan({
    required this.id,
    required this.eventId,
    required this.name,
    required this.tables,
    required this.version,
  });
  final String id;
  final String eventId;
  final String name;
  final List<TablePosition> tables;
  final int version;

  LayoutPlan copyWith({List<TablePosition>? tables, int? version}) =>
      LayoutPlan(
        id: id,
        eventId: eventId,
        name: name,
        tables: tables ?? this.tables,
        version: version ?? this.version,
      );
  Map<String, dynamic> toJson() => {
    'id': id,
    'eventId': eventId,
    'name': name,
    'tables': tables.map((t) => t.toJson()).toList(),
    'version': version,
  };
  factory LayoutPlan.fromJson(Map<String, dynamic> data) => LayoutPlan(
    id: data['id'] as String,
    eventId: data['eventId'] as String,
    name: data['name'] as String,
    tables: (data['tables'] as List)
        .map((e) => TablePosition.fromJson(e as Map<String, dynamic>))
        .toList(),
    version: data['version'] as int,
  );
}

class ProjectData {
  const ProjectData({
    this.organization = 'Sample organization',
    this.venues = const [],
    this.spaces = const [],
    this.events = const [],
    this.layouts = const [],
  });
  final String organization;
  final List<Venue> venues;
  final List<Space> spaces;
  final List<EventRecord> events;
  final List<LayoutPlan> layouts;

  ProjectData copyWith({
    String? organization,
    List<Venue>? venues,
    List<Space>? spaces,
    List<EventRecord>? events,
    List<LayoutPlan>? layouts,
  }) => ProjectData(
    organization: organization ?? this.organization,
    venues: venues ?? this.venues,
    spaces: spaces ?? this.spaces,
    events: events ?? this.events,
    layouts: layouts ?? this.layouts,
  );
  String encode() => jsonEncode({
    'organization': organization,
    'venues': venues.map((v) => v.toJson()).toList(),
    'spaces': spaces.map((s) => s.toJson()).toList(),
    'events': events.map((e) => e.toJson()).toList(),
    'layouts': layouts.map((l) => l.toJson()).toList(),
  });
  factory ProjectData.decode(String value) {
    final data = jsonDecode(value) as Map<String, dynamic>;
    return ProjectData(
      organization: data['organization'] as String,
      venues: (data['venues'] as List)
          .map((e) => Venue.fromJson(e as Map<String, dynamic>))
          .toList(),
      spaces: (data['spaces'] as List)
          .map((e) => Space.fromJson(e as Map<String, dynamic>))
          .toList(),
      events: (data['events'] as List)
          .map((e) => EventRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
      layouts: (data['layouts'] as List)
          .map((e) => LayoutPlan.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
