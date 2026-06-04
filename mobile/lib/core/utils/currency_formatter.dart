import 'package:intl/intl.dart';

/// Currency formatting utilities for VND.
/// All amounts in the app are stored as integers (VND).
abstract class CurrencyFormatter {
  static final _vndFormatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '',
    decimalDigits: 0,
  );

  /// Format as full VND: 1,000,000 → "1.000.000 ₫"
  static String format(int amountVnd) {
    return '${_vndFormatter.format(amountVnd).trim()} ₫';
  }

  /// Format compact for display: 1,000,000 → "1 triệu", -1,000,000 -> "-1 triệu"
  static String compact(int amountVnd) {
    final bool isNegative = amountVnd < 0;
    final int absValue = amountVnd.abs();

    String result;
    if (absValue >= 1000000000) {
      final billions = absValue / 1000000000;
      result = '${_formatDecimal(billions)} tỷ';
    } else if (absValue >= 1000000) {
      final millions = absValue / 1000000;
      result = '${_formatDecimal(millions)} triệu';
    } else if (absValue >= 1000) {
      final thousands = absValue / 1000;
      result = '${_formatDecimal(thousands)} nghìn';
    } else {
      result = '$absValue ₫';
    }

    return isNegative ? '-$result' : result;
  }

  /// For input field display: 3000000 → "3.000.000"
  static String formatInput(int amountVnd) {
    return _vndFormatter.format(amountVnd).trim();
  }

  /// Parse user input string back to int: "3.000.000" → 3000000
  static int? parse(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^\d]'), '');
    return int.tryParse(cleaned);
  }

  static String _formatDecimal(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }
}

/// Month/time formatting utilities
abstract class DateHelper {
  /// Format months to human-readable: 26 → "26 tháng" / 13 → "1 năm 1 tháng"
  static String formatMonths(int months) {
    if (months <= 0) return 'Đã đủ tiền! 🎉';
    if (months < 12) return '$months tháng';

    final years = months ~/ 12;
    final remainingMonths = months % 12;

    if (remainingMonths == 0) return '$years năm';
    return '$years năm $remainingMonths tháng';
  }

  /// Format target month: 26 months from now → "Tháng 8/2028"
  static String targetMonthFromNow(int months) {
    final target = DateTime.now().add(Duration(days: months * 30));
    return 'Tháng ${target.month}/${target.year}';
  }
}
