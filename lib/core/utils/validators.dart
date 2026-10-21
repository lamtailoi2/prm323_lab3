/// Field validators for ViewModels. Each returns `null` when the value is
/// valid, otherwise the plain-language message to show under the field.
///
/// Messages are passed in by the caller so they stay specific to the field,
/// e.g. "Enter your full name to continue." (Figma Text Field error).
abstract final class Validators {
  static final RegExp _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

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
}
