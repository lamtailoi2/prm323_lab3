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

  /// Company logo in the Internship Detail header (Figma 202:243, 48 × 48).
  static const double companyLogoLarge = 48;

  /// Logo that overlaps the cover of the Job Hero Card (Figma "Job Hero
  /// Card", DC-31).
  static const double companyLogoHero = 64;

  /// Cover band at the top of the Job Hero Card (Figma "Job Hero Card").
  static const double jobCoverHeight = 112;

  /// Home app-bar brand mark and the profile avatar (Home screenshot).
  static const double brandMark = 32;
  static const double profileAvatar = 32;

  /// Avatar in the Profile header card (Profile screenshot, verify in
  /// Figma: G-07).
  static const double profileHeaderAvatar = 56;

  /// Photo at the top of Edit profile (Edit Profile frame, verify in
  /// Figma: G-07).
  static const double editProfileAvatar = 80;

  /// Height of the large skill / preference tag on Profile (design owner,
  /// 2026-10-28).
  static const double tagLarge = 44;

  /// Icon tile of the CV file card and the sheet headers (Profile
  /// screenshots; same size as the company logo, verify in Figma: G-07).
  static const double fileTile = 40;

  /// Layout widths that every screen must be checked at.
  static const double baseWidth = 360;
  static const double responsiveCheckWidth = 412;
}
