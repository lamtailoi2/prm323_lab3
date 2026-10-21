import 'package:flutter/widgets.dart';

/// Elevation tokens from Lab 2 `DESIGN.md` §8.
///
/// Prefer borders or background contrast before shadows.
abstract final class AppElevation {
  /// `elevation/0` — default surfaces, forms, flat lists.
  static const List<BoxShadow> level0 = <BoxShadow>[];

  /// `elevation/1` — `0 1 3 rgba(15, 23, 42, 0.08)`: cards, search surface.
  static const List<BoxShadow> level1 = <BoxShadow>[
    BoxShadow(color: Color(0x140F172A), offset: Offset(0, 1), blurRadius: 3),
  ];

  /// `elevation/2` — `0 8 24 rgba(15, 23, 42, 0.12)`: dialogs, sheets.
  static const List<BoxShadow> level2 = <BoxShadow>[
    BoxShadow(color: Color(0x1F0F172A), offset: Offset(0, 8), blurRadius: 24),
  ];
}
