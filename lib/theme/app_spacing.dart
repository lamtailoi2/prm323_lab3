/// Spacing scale from Lab 2 `DESIGN.md` §6 (Figma `spacing/4` … `spacing/32`).
abstract final class AppSpacing {
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s24 = 24;
  static const double s32 = 32;

  /// Standard horizontal screen padding.
  static const double screenHorizontal = s16;

  /// Gap between major sections.
  static const double section = s24;

  /// Gap between internship cards.
  static const double betweenCards = s16;

  /// Gap between closely related text elements.
  static const double related = s8;
}
