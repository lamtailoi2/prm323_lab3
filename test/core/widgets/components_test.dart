import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internly/core/widgets/app_dialog.dart';
import 'package:internly/core/widgets/app_search_field.dart';
import 'package:internly/core/widgets/app_text_field.dart';
import 'package:internly/core/widgets/app_top_bar.dart';
import 'package:internly/core/widgets/internship_card.dart';
import 'package:internly/core/widgets/main_tab_app_bar.dart';
import 'package:internly/core/widgets/skeleton.dart';
import 'package:internly/core/widgets/status_badge.dart';
import 'package:internly/models/app_user.dart';
import 'package:internly/theme/app_colors.dart';
import 'package:internly/theme/app_theme.dart';
import 'package:internly/theme/app_typography.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump.dart';

void main() {
  group('AppTextField', () {
    testWidgets('label persists above the field with helper text', (
      tester,
    ) async {
      await pumpThemed(
        tester,
        const AppTextField(
          label: 'Full name',
          hintText: 'Enter your full name',
          helperText: 'Use the name shown on your CV.',
        ),
      );
      expect(find.text('Full name'), findsOneWidget);
      expect(find.text('Use the name shown on your CV.'), findsOneWidget);
      expect(find.byIcon(Symbols.error_rounded), findsNothing);
      expect(
        tester.getTopLeft(find.text('Full name')).dy,
        lessThan(tester.getTopLeft(find.byType(TextField)).dy),
      );
    });

    testWidgets('error shows icon and message, not color alone', (
      tester,
    ) async {
      await pumpThemed(
        tester,
        const AppTextField(
          label: 'Full name',
          errorText: 'Enter your full name to continue.',
        ),
      );
      expect(find.text('Enter your full name to continue.'), findsOneWidget);
      expect(find.byIcon(Symbols.error_rounded), findsOneWidget);
    });

    testWidgets('input is at least 48 dp tall', (tester) async {
      await pumpThemed(tester, const AppTextField(label: 'Email'));
      expect(
        tester.getSize(find.byType(TextField)).height,
        greaterThanOrEqualTo(48),
      );
    });
  });

  group('AppSearchField', () {
    testWidgets('clear action appears with text and clears it', (tester) async {
      var filters = 0;
      await pumpThemed(
        tester,
        AppSearchField(onFilterPressed: () => filters++),
      );
      expect(find.byTooltip('Clear search'), findsNothing);
      expect(find.byTooltip('Filters'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Flutter');
      await tester.pump();
      expect(find.byTooltip('Clear search'), findsOneWidget);

      await tester.tap(find.byTooltip('Clear search'));
      await tester.pump();
      expect(find.text('Flutter'), findsNothing);

      await tester.tap(find.byTooltip('Filters'));
      expect(filters, 1);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });

    testWidgets('long placeholder wraps without overflow at 360 dp', (
      tester,
    ) async {
      await pumpThemed(tester, AppSearchField(onFilterPressed: () {}));
      expect(tester.takeException(), isNull);
    });
  });

  group('InternshipCard', () {
    Widget card({
      bool saved = false,
      VoidCallback? onSave,
      VoidCallback? onTap,
    }) {
      return InternshipCard(
        title: 'Software Engineering Intern - Mobile Platform Team',
        companyName: 'Northstar Labs',
        location: 'District 1, Ho Chi Minh City',
        workMode: 'Hybrid',
        tags: const ['Flutter', 'Dart', 'Firebase', 'REST API'],
        allowanceText: 'Allowance text',
        postedText: 'Posted 2 days ago',
        isSaved: saved,
        onSaveToggle: onSave,
        onTap: onTap,
      );
    }

    for (final width in checkWidths) {
      testWidgets('renders all content without overflow at $width dp', (
        tester,
      ) async {
        await pumpThemed(tester, card(onSave: () {}), width: width);
        expect(tester.takeException(), isNull);
        expect(find.text('Northstar Labs'), findsOneWidget);
        expect(find.text('Hybrid'), findsOneWidget);
        expect(find.text('Posted 2 days ago'), findsOneWidget);
      });
    }

    testWidgets('card exposes one summary label for ARTEMIS', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpThemed(tester, card(saved: true, onSave: () {}, onTap: () {}));
      expect(
        find.bySemanticsLabel(
          RegExp(
            r'^Software Engineering Intern - Mobile Platform Team at '
            r'Northstar Labs\. District 1, Ho Chi Minh City, Hybrid\. '
            r'Skills: Flutter, Dart, Firebase, REST API\..*Saved$',
          ),
        ),
        findsOneWidget,
      );
      // The save action stays a separate node with its own description.
      final saveNode = tester.getSemantics(find.byTooltip('Remove from saved'));
      expect(saveNode.getSemanticsData().tooltip, 'Remove from saved');
      expect(saveNode.label, isNot(contains('Northstar')));
      handle.dispose();
    });

    testWidgets('save action has a 48 dp target and saved state', (
      tester,
    ) async {
      var saves = 0;
      var opens = 0;
      await pumpThemed(
        tester,
        card(saved: true, onSave: () => saves++, onTap: () => opens++),
      );
      final saveButton = find.byTooltip('Remove from saved');
      expect(saveButton, findsOneWidget);
      expect(tester.getSize(saveButton).height, greaterThanOrEqualTo(48));
      final icon = tester.widget<Icon>(find.byIcon(Symbols.bookmark_rounded));
      expect(icon.fill, 1);
      expect(icon.color, AppColors.primary);

      await tester.tap(saveButton);
      expect(saves, 1);
      expect(opens, 0);
      await tester.tap(find.text('Northstar Labs'));
      expect(opens, 1);
    });
  });

  testWidgets('StatusBadge shows icon and label on surfaceVariant', (
    tester,
  ) async {
    await pumpThemed(
      tester,
      const StatusBadge(
        label: 'Under review',
        icon: Symbols.hourglass_top_rounded,
        color: AppColors.warning,
      ),
    );
    expect(find.byIcon(Symbols.hourglass_top_rounded), findsOneWidget);
    expect(find.bySemanticsLabel('Status: Under review'), findsOneWidget);
    final box = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byType(StatusBadge),
        matching: find.byType(DecoratedBox),
      ),
    );
    expect((box.decoration as BoxDecoration).color, AppColors.surfaceVariant);
  });

  group('AppTopBar', () {
    testWidgets('main variant uses the heading/large title', (tester) async {
      setScreenSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(appBar: AppTopBar.main(title: 'Home')),
        ),
      );
      final title = tester.widget<AppBar>(find.byType(AppBar));
      expect(title.titleTextStyle, AppTypography.headingLarge);
      expect(find.byTooltip('Back'), findsNothing);
    });

    testWidgets('back variant pops the route', (tester) async {
      setScreenSize(tester);
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          theme: AppTheme.light(),
          home: const Scaffold(body: Text('List')),
        ),
      );
      navigatorKey.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(
            appBar: AppTopBar.back(title: 'Internship details'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Internship details'), findsOneWidget);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('List'), findsOneWidget);
    });
  });

  group('MainTabAppBar', () {
    Future<void> pumpBar(
      WidgetTester tester, {
      double width = 360,
      AppUser? user,
    }) async {
      setScreenSize(tester, width: width);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            appBar: MainTabAppBar(title: 'Saved', user: user, onProfile: () {}),
          ),
        ),
      );
    }

    for (final width in checkWidths) {
      testWidgets('every tab shows bell and avatar at $width dp', (
        tester,
      ) async {
        await pumpBar(tester, width: width, user: testUser);

        expect(find.text('Saved'), findsOneWidget);
        // No brand mark in the leading slot (DC-15).
        expect(find.byIcon(Symbols.school_rounded), findsNothing);
        expect(find.byIcon(Symbols.notifications_rounded), findsOneWidget);
        expect(find.byTooltip('Notifications'), findsOneWidget);
        expect(find.byTooltip('Profile'), findsOneWidget);
        // No photo, so the avatar falls back to the person glyph.
        expect(find.byIcon(Symbols.person_rounded), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('touch targets are at least 48 dp', (tester) async {
      await pumpBar(tester, user: testUser);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });
  });

  testWidgets('showAppDialog returns true for primary, false for secondary', (
    tester,
  ) async {
    setScreenSize(tester);
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (c) {
            context = c;
            return const Scaffold();
          },
        ),
      ),
    );

    Future<bool?> open() => showAppDialog(
      context,
      title: 'Apply for this internship?',
      message: 'Send your profile and CV to Northstar Labs for review.',
      primaryLabel: 'Apply now',
    );

    var result = open();
    await tester.pumpAndSettle();
    expect(find.text('Apply for this internship?'), findsOneWidget);
    await tester.tap(find.text('Apply now'));
    await tester.pumpAndSettle();
    expect(await result, isTrue);

    result = open();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(await result, isFalse);
  });

  testWidgets('InternshipCardSkeleton renders without overflow', (
    tester,
  ) async {
    await pumpThemed(tester, const InternshipCardSkeleton());
    expect(find.byType(SkeletonBox), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
