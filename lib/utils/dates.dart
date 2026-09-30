import 'package:intl/intl.dart';

import '../l10n/l10n.dart';

/// "Today", "Yesterday", a weekday within the week, else "12 Sep" (with the
/// year once it isn't this year). The date patterns come from the strings
/// file, so each language orders day and month its own way.
String friendlyDate(AppLocalizations l10n, DateTime date, {DateTime? now}) {
  final today = _dateOnly(now ?? DateTime.now());
  final day = _dateOnly(date);
  final diff = today.difference(day).inDays;
  final locale = l10n.localeName;

  if (diff <= 0) return l10n.dateToday;
  if (diff == 1) return l10n.dateYesterday;
  if (diff < 7) return DateFormat.E(locale).format(date);
  return DateFormat(
    date.year == today.year ? l10n.dateFormatShort : l10n.dateFormatLong,
    locale,
  ).format(date);
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
