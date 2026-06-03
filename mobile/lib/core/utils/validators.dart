/// Form validators — returns null if valid, error string if invalid.
/// All messages in Vietnamese.
abstract class Validators {
  /// Monthly income: 500K–1B VND
  static String? income(String? value) {
    if (value == null || value.trim().isEmpty) return 'Vui lòng nhập thu nhập';
    final amount = _parseVnd(value);
    if (amount == null) return 'Số tiền không hợp lệ';
    if (amount < 500000) return 'Thu nhập tối thiểu 500.000 ₫';
    if (amount > 1000000000) return 'Số tiền quá lớn';
    return null;
  }

  /// Fixed monthly expenses
  static String? expenses(String? value, {required int income}) {
    if (value == null || value.trim().isEmpty) return 'Vui lòng nhập chi phí cố định';
    final amount = _parseVnd(value);
    if (amount == null) return 'Số tiền không hợp lệ';
    if (amount < 0) return 'Chi phí không thể âm';
    if (amount >= income) {
      return 'Chi phí cố định đang vượt thu nhập — hãy kiểm tra lại';
    }
    return null;
  }

  /// Current savings amount
  static String? savings(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional, default 0
    final amount = _parseVnd(value);
    if (amount == null) return 'Số tiền không hợp lệ';
    if (amount < 0) return 'Tiết kiệm không thể âm';
    return null;
  }

  /// Goal target amount
  static String? goalAmount(String? value) {
    if (value == null || value.trim().isEmpty) return 'Vui lòng nhập số tiền mục tiêu';
    final amount = _parseVnd(value);
    if (amount == null) return 'Số tiền không hợp lệ';
    if (amount < 100000) return 'Mục tiêu tối thiểu 100.000 ₫';
    return null;
  }

  /// Goal name for custom goals
  static String? goalName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Vui lòng đặt tên mục tiêu';
    if (value.trim().length < 2) return 'Tên quá ngắn';
    if (value.trim().length > 100) return 'Tên tối đa 100 ký tự';
    return null;
  }

  /// Age: 16–100
  static String? age(String? value) {
    if (value == null || value.trim().isEmpty) return 'Vui lòng nhập tuổi';
    final age = int.tryParse(value.trim());
    if (age == null) return 'Tuổi không hợp lệ';
    if (age < 16) return 'Tuổi tối thiểu là 16';
    if (age > 100) return 'Tuổi không hợp lệ';
    return null;
  }

  /// Salary date: 1–31
  static String? salaryDate(String? value) {
    if (value == null || value.trim().isEmpty) return 'Vui lòng chọn ngày nhận lương';
    final day = int.tryParse(value.trim());
    if (day == null || day < 1 || day > 31) return 'Ngày không hợp lệ (1-31)';
    return null;
  }

  static int? _parseVnd(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^\d]'), '');
    return int.tryParse(cleaned);
  }
}
