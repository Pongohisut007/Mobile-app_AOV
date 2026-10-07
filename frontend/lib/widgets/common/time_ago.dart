import 'package:flutter_application_1/l10n/l10n.dart';

/// แปลงเวลาเป็น "x นาทีที่แล้ว / x ชั่วโมงที่แล้ว / x วันที่แล้ว ..."
String timeAgo(AppLocalizations l10n, DateTime time, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(time);
  if (diff.inSeconds < 60) return l10n.timeJustNow;
  if (diff.inMinutes < 60) return l10n.timeMinutesAgo(diff.inMinutes);
  if (diff.inHours < 24) return l10n.timeHoursAgo(diff.inHours);
  if (diff.inDays < 30) return l10n.timeDaysAgo(diff.inDays);
  if (diff.inDays < 365) return l10n.timeMonthsAgo((diff.inDays / 30).floor());
  return l10n.timeYearsAgo((diff.inDays / 365).floor());
}
