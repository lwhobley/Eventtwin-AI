class ExtractedBeo {
  const ExtractedBeo({
    this.eventName,
    this.guestCount,
    this.eventSource,
    this.guestSource,
  });
  final String? eventName;
  final int? guestCount;
  final String? eventSource;
  final String? guestSource;
}

ExtractedBeo extractExplicitBeoFields(String text) {
  String? eventName;
  int? guestCount;
  String? eventSource;
  String? guestSource;
  for (final line in text.split(RegExp(r'\r?\n'))) {
    final event = RegExp(
      r'^\s*event\s*:\s*(.+?)\s*$',
      caseSensitive: false,
    ).firstMatch(line);
    if (event != null && eventName == null) {
      eventName = event.group(1);
      eventSource = line.trim();
    }
    final guests = RegExp(
      r'^\s*(?:guests|expected guests)\s*:\s*(\d+)\s*$',
      caseSensitive: false,
    ).firstMatch(line);
    if (guests != null && guestCount == null) {
      guestCount = int.tryParse(guests.group(1)!);
      guestSource = line.trim();
    }
  }
  return ExtractedBeo(
    eventName: eventName,
    guestCount: guestCount,
    eventSource: eventSource,
    guestSource: guestSource,
  );
}
