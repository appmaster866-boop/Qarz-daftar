import 'package:intl/intl.dart';

/// "1234567.5" -> "1 234 567.5" (minglarni bo'sh joy bilan ajratadi)
String groupDigits(String raw) {
  if (raw == 'Xato') return raw;
  final negative = raw.startsWith('-');
  final s = negative ? raw.substring(1) : raw;
  final parts = s.split('.');
  final intPart = parts[0];

  final buf = StringBuffer();
  for (var i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(' ');
    buf.write(intPart[i]);
  }
  var result = buf.toString();
  if (parts.length > 1) result += '.${parts[1]}';
  return negative ? '-$result' : result;
}

/// 150000 -> "150 000 so'm"
String formatMoney(double v) {
  final isWhole = v == v.truncateToDouble();
  return "${groupDigits(v.toStringAsFixed(isWhole ? 0 : 2))} so'm";
}

String formatDate(DateTime d) => DateFormat('dd.MM.yyyy').format(d);
String formatTime(DateTime d) => DateFormat('HH:mm').format(d);

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
