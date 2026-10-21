import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internly/theme/app_sizes.dart';
import 'package:internly/theme/app_theme.dart';

/// The two widths every screen and component must support (DESIGN.md §2).
const checkWidths = <double>[AppSizes.baseWidth, AppSizes.responsiveCheckWidth];

/// Sets the logical screen size for the current test and restores it after.
void setScreenSize(
  WidgetTester tester, {
  double width = 360,
  double height = 800,
}) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, height);
  addTearDown(tester.view.reset);
}

/// Pumps [child] inside a themed scaffold at the given width.
Future<void> pumpThemed(
  WidgetTester tester,
  Widget child, {
  double width = AppSizes.baseWidth,
}) async {
  setScreenSize(tester, width: width);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  );
}
