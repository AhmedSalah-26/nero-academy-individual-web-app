/// Form Validators
class Validators {
  Validators._();

  /// Email validation
  static String? email(String? value,
      {String? emptyMessage, String? invalidMessage}) {
    if (value == null || value.trim().isEmpty) {
      return emptyMessage ?? 'البريد الإلكتروني مطلوب';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return invalidMessage ?? 'البريد الإلكتروني غير صالح';
    }
    return null;
  }

  /// Password validation
  static String? password(
    String? value, {
    String? emptyMessage,
    String? shortMessage,
    int minLength = 8,
  }) {
    if (value == null || value.isEmpty) {
      return emptyMessage ?? 'كلمة المرور مطلوبة';
    }
    if (value.length < minLength) {
      return shortMessage ??
          'كلمة المرور يجب أن تكون $minLength أحرف على الأقل';
    }
    return null;
  }

  /// Confirm password validation
  static String? confirmPassword(
    String? value,
    String? password, {
    String? emptyMessage,
    String? mismatchMessage,
  }) {
    if (value == null || value.isEmpty) {
      return emptyMessage ?? 'تأكيد كلمة المرور مطلوب';
    }
    if (value != password) {
      return mismatchMessage ?? 'كلمة المرور غير متطابقة';
    }
    return null;
  }

  /// Required field validation
  static String? required(String? value, {String? message}) {
    if (value == null || value.trim().isEmpty) {
      return message ?? 'هذا الحقل مطلوب';
    }
    return null;
  }

  /// Phone validation
  static String? phone(String? value,
      {String? emptyMessage, String? invalidMessage}) {
    if (value == null || value.trim().isEmpty) {
      return emptyMessage ?? 'رقم الهاتف مطلوب';
    }
    final phoneRegex = RegExp(r'^[0-9]{10,15}$');
    if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'[\s\-\(\)]'), ''))) {
      return invalidMessage ?? 'رقم الهاتف غير صالح';
    }
    return null;
  }

  /// URL validation
  static String? url(String? value, {String? invalidMessage}) {
    if (value == null || value.trim().isEmpty) {
      return null; // URL is optional
    }
    final urlRegex = RegExp(
      r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
      caseSensitive: false,
    );
    if (!urlRegex.hasMatch(value.trim())) {
      return invalidMessage ?? 'الرابط غير صالح';
    }
    return null;
  }

  /// Min length validation
  static String? minLength(String? value, int min, {String? message}) {
    if (value == null || value.length < min) {
      return message ?? 'يجب أن يكون $min أحرف على الأقل';
    }
    return null;
  }

  /// Max length validation
  static String? maxLength(String? value, int max, {String? message}) {
    if (value != null && value.length > max) {
      return message ?? 'يجب ألا يتجاوز $max حرف';
    }
    return null;
  }

  /// Number validation
  static String? number(String? value, {String? message}) {
    if (value == null || value.isEmpty) return null;
    if (double.tryParse(value) == null) {
      return message ?? 'يجب إدخال رقم صالح';
    }
    return null;
  }

  /// Positive number validation
  static String? positiveNumber(String? value, {String? message}) {
    if (value == null || value.isEmpty) return null;
    final num = double.tryParse(value);
    if (num == null || num <= 0) {
      return message ?? 'يجب إدخال رقم موجب';
    }
    return null;
  }
}
