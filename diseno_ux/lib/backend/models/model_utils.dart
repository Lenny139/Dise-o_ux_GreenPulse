DateTime? parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.parse(value.toString());
}

DateTime? parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) {
    return DateTime(value.year, value.month, value.day);
  }
  final parsed = DateTime.parse(value.toString());
  return DateTime(parsed.year, parsed.month, parsed.day);
}
