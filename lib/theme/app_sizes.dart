/// Size constraints from Lab 2 `DESIGN.md` §2, §10, §12 and the Lab 2
/// README accessibility table.
abstract final class AppSizes {
  /// Minimum touch target (48 × 48 dp).
  static const double minTouchTarget = 48;

  /// Minimum button height.
  static const double buttonHeight = 48;

  /// App bar height (Internship Detail spec: 56 dp).
  static const double appBarHeight = 56;

  /// Bottom navigation height (README: items 78 × 60 dp).
  static const double bottomNavHeight = 60;

  /// Standard icon sizes.
  static const double iconSmall = 20;
  static const double icon = 24;

  /// Company logo tile in the internship card (Home screenshot, verify in
  /// Figma: G-07).
  static const double companyLogo = 40;

  /// Home app-bar brand mark and the profile avatar (Home screenshot).
  static const double brandMark = 32;
  static const double profileAvatar = 32;

  /// Layout widths that every screen must be checked at.
  static const double baseWidth = 360;
  static const double responsiveCheckWidth = 412;
}
