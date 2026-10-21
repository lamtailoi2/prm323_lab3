import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internly/core/widgets/app_button.dart';
import 'package:internly/core/widgets/state_view.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../helpers/pump.dart';

void main() {
  testWidgets('loading shows a labeled spinner', (tester) async {
    await pumpThemed(
      tester,
      const StateView.loading(message: 'Loading internships'),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Loading internships'), findsOneWidget);
  });

  for (final width in checkWidths) {
    testWidgets('empty state (Figma "Saved") at $width dp', (tester) async {
      var actions = 0;
      await pumpThemed(
        tester,
        StateView.empty(
          icon: Symbols.bookmark_rounded,
          title: 'No saved internships yet',
          message: 'Save opportunities to compare them and apply when you are ready.',
          actionLabel: 'Search internships',
          onAction: () => actions++,
        ),
        width: width,
      );
      expect(find.text('No saved internships yet'), findsOneWidget);
      final icon = tester.widget<Icon>(find.byIcon(Symbols.bookmark_rounded));
      expect(icon.size, 24);

      // One useful action, primary and full width.
      final button = tester.widget<AppButton>(find.byType(AppButton));
      expect(button.variant, AppButtonVariant.primary);
      expect(button.expand, isTrue);
      await tester.tap(find.text('Search internships'));
      expect(actions, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('error state with Retry at $width dp', (tester) async {
      var retries = 0;
      await pumpThemed(
        tester,
        StateView.error(
          icon: Symbols.wifi_off_rounded,
          message: 'We could not load internships. Check your connection and try again.',
          onRetry: () => retries++,
        ),
        width: width,
      );
      expect(find.textContaining('Check your connection'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      expect(retries, 1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('error state without onRetry has no action', (tester) async {
    await pumpThemed(
      tester,
      const StateView.error(message: 'Something went wrong.'),
    );
    expect(find.byType(AppButton), findsNothing);
  });
}
