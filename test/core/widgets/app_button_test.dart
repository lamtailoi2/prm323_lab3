import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internly/core/widgets/app_button.dart';
import 'package:internly/theme/app_colors.dart';

import '../../helpers/pump.dart';

void main() {
  testWidgets('tapping calls onPressed once', (tester) async {
    var taps = 0;
    await pumpThemed(
      tester,
      AppButton(label: 'Apply now', onPressed: () => taps++),
    );
    await tester.tap(find.text('Apply now'));
    expect(taps, 1);
  });

  testWidgets('every variant keeps a 48 dp touch target', (tester) async {
    await pumpThemed(
      tester,
      Column(
        children: [
          for (final variant in AppButtonVariant.values)
            AppButton(label: variant.name, onPressed: () {}, variant: variant),
        ],
      ),
    );
    final buttons = find.byWidgetPredicate((w) => w is ButtonStyleButton);
    expect(buttons, findsNWidgets(AppButtonVariant.values.length));
    for (final element in buttons.evaluate()) {
      expect(element.size!.height, greaterThanOrEqualTo(48));
    }
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  });

  testWidgets(
    'loading blocks taps, shows a spinner and keeps the default look',
    (tester) async {
      var taps = 0;
      await pumpThemed(
        tester,
        AppButton(label: 'Apply now', onPressed: () => taps++, isLoading: true),
      );
      await tester.tap(find.text('Apply now'), warnIfMissed: false);
      expect(taps, 0);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      final material = tester.widget<Material>(
        find.descendant(
          of: find.byType(FilledButton),
          matching: find.byType(Material),
        ),
      );
      expect(material.color, AppColors.primary);
      expect(find.bySemanticsLabel('Apply now, loading'), findsOneWidget);
    },
  );

  testWidgets('null onPressed renders the disabled state', (tester) async {
    await pumpThemed(
      tester,
      const AppButton(label: 'Apply now', onPressed: null),
    );
    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(FilledButton),
        matching: find.byType(Material),
      ),
    );
    expect(material.color, AppColors.surfaceVariant);
  });

  testWidgets('expand makes the button full width', (tester) async {
    await pumpThemed(
      tester,
      AppButton(label: 'Search internships', onPressed: () {}, expand: true),
    );
    // 360 dp screen minus 2 × 16 dp padding.
    expect(tester.getSize(find.byType(FilledButton)).width, 328);
  });
}
