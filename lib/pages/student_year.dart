int? studentYearNumber(Object? value) {
  final normalized = value?.toString().trim().toLowerCase() ?? '';

  const wordYears = {'first': 1, 'second': 2, 'third': 3, 'fourth': 4};
  for (final entry in wordYears.entries) {
    if (normalized == entry.key || normalized == '${entry.key} year') {
      return entry.value;
    }
  }

  final match = RegExp(r'^(?:year\s*)?([1-4])(?:st|nd|rd|th)?(?:\s*year)?$')
      .firstMatch(normalized);
  return match == null ? null : int.parse(match.group(1)!);
}
