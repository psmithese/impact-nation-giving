import 'package:intl/intl.dart';

/// Standardized currency and number formatter for Impact Nation Giving.
/// Ensures consistent display across Mobile and Web.
class CurrencyFormatter {
  static final _fullCurrency = NumberFormat.currency(
    symbol: '₦',
    decimalDigits: 0,
  );

  /// Full formatted currency with commas, e.g. "₦2,500,000"
  static String formatFull(num amount) {
    return _fullCurrency.format(amount);
  }

  /// Compact representation of amount, e.g.:
  /// 2,500,000 -> "2.5M"
  /// 1,000,000 -> "1M"
  /// 100,000 -> "100K"
  /// 1,500 -> "1.5K"
  /// 500 -> "500"
  /// 0 -> "0"
  static String formatCompact(num value) {
    final v = value.toDouble();
    if (v >= 1000000000) {
      final b = v / 1000000000;
      final d = (b % 1 == 0) ? 0 : (b * 10 % 1 == 0 ? 1 : 2);
      return '${b.toStringAsFixed(d)}B';
    }
    if (v >= 1000000) {
      final m = v / 1000000;
      final d = (m % 1 == 0) ? 0 : (m * 10 % 1 == 0 ? 1 : 2);
      return '${m.toStringAsFixed(d)}M';
    }
    if (v >= 1000) {
      final k = v / 1000;
      final d = (k % 1 == 0) ? 0 : (k * 10 % 1 == 0 ? 1 : 2);
      return '${k.toStringAsFixed(d)}K';
    }
    return v.toStringAsFixed(0);
  }

  /// Compact representation with Naira symbol:
  /// 2,500,000 -> "₦2.5M"
  /// 100,000 -> "₦100K"
  /// 0 -> "₦0"
  static String formatCompactCurrency(num value) {
    return '₦${formatCompact(value)}';
  }
}
