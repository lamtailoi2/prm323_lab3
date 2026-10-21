import 'package:flutter/widgets.dart';

/// Corner radius tokens from Lab 2 `DESIGN.md` §7.
abstract final class AppRadii {
  /// `radius/8` — small chips, badges, compact tags.
  static const double small = 8;

  /// `radius/12` — buttons, text fields, filter chips.
  static const double medium = 12;

  /// `radius/16` — internship cards, dialogs, bottom sheets, profile sections.
  static const double large = 16;

  /// `radius/full` — pills, circular icon buttons, avatars.
  static const double full = 999;

  static const BorderRadius smallAll = BorderRadius.all(Radius.circular(small));
  static const BorderRadius mediumAll = BorderRadius.all(
    Radius.circular(medium),
  );
  static const BorderRadius largeAll = BorderRadius.all(Radius.circular(large));
  static const BorderRadius fullAll = BorderRadius.all(Radius.circular(full));
}
