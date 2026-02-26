import 'package:intl/intl.dart';

class DateUtils2 {
  DateUtils2._();

  static String formatDate(DateTime date) {
    return DateFormat('dd.MM.yyyy').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('dd.MM.yyyy HH:mm').format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Только что';
    if (diff.inMinutes < 60) return '${diff.inMinutes} мин назад';
    if (diff.inHours < 24) return '${diff.inHours} ч назад';
    if (diff.inDays < 7) return '${diff.inDays} дн назад';
    return formatDate(date);
  }

  static String formatPeriod(DateTime start, DateTime end) {
    return '${DateFormat('dd MMM').format(start)} — ${DateFormat('dd MMM').format(end)}';
  }

  static String daysUntil(DateTime target) {
    final days = target.difference(DateTime.now()).inDays;
    if (days < 0) return 'Просрочено';
    if (days == 0) return 'Сегодня';
    if (days == 1) return 'Завтра';
    return '$days дн';
  }
}
