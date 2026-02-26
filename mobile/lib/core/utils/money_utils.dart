import 'package:intl/intl.dart';

class MoneyUtils {
  MoneyUtils._();

  static String format(dynamic amount, {String currency = 'KZT'}) {
    final value = _toDouble(amount);
    final formatter = NumberFormat('#,##0', 'ru_RU');
    final formatted = formatter.format(value.truncate());
    final decimals = value - value.truncateToDouble();
    if (decimals > 0.001) {
      return '$formatted.${(decimals * 100).round().toString().padLeft(2, '0')} $currency';
    }
    return '$formatted $currency';
  }

  static String formatCompact(dynamic amount, {String currency = 'KZT'}) {
    final value = _toDouble(amount);
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M $currency';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K $currency';
    }
    return '${value.toStringAsFixed(0)} $currency';
  }

  static String formatShort(dynamic amount) {
    final value = _toDouble(amount);
    final formatter = NumberFormat('#,##0', 'ru_RU');
    return formatter.format(value.truncate());
  }

  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static double parseAmount(dynamic value) => _toDouble(value);
}
