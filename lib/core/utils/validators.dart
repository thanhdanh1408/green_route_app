class Validators {
  Validators._();

  static String? validateNotEmpty(
    String? value, {
    String fieldName = 'Trường này',
  }) {
    if (value == null || value.trim().isEmpty) return '$fieldName không được để trống';
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Vui lòng nhập số điện thoại';
    final normalized = value.replaceAll(RegExp(r"[^0-9+]"), '');
    final pattern = RegExp(r'^((\+84)|0)(3|5|7|8|9)([0-9]{8})$');
    if (!pattern.hasMatch(normalized)) return 'Số điện thoại không hợp lệ';
    return null;
  }

static String? validateEmail(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Vui lòng nhập email';
  }

  final pattern = RegExp(
    r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$',
  );
  if (!pattern.hasMatch(value.trim())) {
    return 'Email không hợp lệ';
  }
  return null;
}

  static String? validatePassword(String? value, {int minLen = 8}) {
    if (value == null || value.isEmpty) return 'Vui lòng nhập mật khẩu';
    if (value.length < minLen) return 'Mật khẩu phải có ít nhất $minLen ký tự';
    return null;
  }

  static String? validateAccountNumber(String? value) {
    if (value == null || value.trim().isEmpty) return 'Vui lòng nhập số tài khoản';
    final normalized = value.replaceAll(RegExp(r'\s+'), '');
    if (!RegExp(r'^[0-9]{6,20}$').hasMatch(normalized)) return 'Số tài khoản không hợp lệ';
    return null;
  }
}
