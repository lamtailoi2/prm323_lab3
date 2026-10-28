/// Field validators for ViewModels. Each returns `null` when the value is
/// valid, otherwise the plain-language message to show under the field.
///
/// Messages are passed in by the caller so they stay specific to the field,
/// e.g. "Enter your full name to continue." (Figma Text Field error).
abstract final class Validators {
  static final RegExp _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final RegExp _phone = RegExp(r'^\+?[0-9][0-9 .-]*$');

  static String? required(String? value, {required String message}) {
    return value == null || value.trim().isEmpty ? message : null;
  }

  static String? email(String? value, {required String message}) {
    final trimmed = value?.trim() ?? '';
    return _email.hasMatch(trimmed) ? null : message;
  }

  static String? maxLength(String? value, int max, {required String message}) {
    return (value?.length ?? 0) > max ? message : null;
  }

  /// Digits with optional spaces, dots or dashes and a leading `+`; 9 to 15
  /// digits in total (Vietnamese mobile numbers have 10).
  static String? phone(String? value, {required String message}) {
    final trimmed = value?.trim() ?? '';
    if (!_phone.hasMatch(trimmed)) return message;
    final digits = trimmed.replaceAll(RegExp('[^0-9]'), '').length;
    return digits >= 9 && digits <= 15 ? null : message;
  }
}
