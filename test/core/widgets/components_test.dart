import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internly/core/widgets/app_dialog.dart';
import 'package:internly/core/widgets/app_search_field.dart';
import 'package:internly/core/widgets/app_tag.dart';
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

    testWidgets('required marker is read as "required"', (tester) async {
      await pumpThemed(
        tester,
        const AppTextField(label: 'Full name', isRequired: true),
      );
      final label = tester.widget<Text>(find.byType(Text).first);
      expect(
        label.textSpan?.toPlainText(includeSemanticsLabels: false),
        'Full name *',
      );
      expect(find.text('Full name, required'), findsOneWidget);
    });

    testWidgets('prefix icon and suffix; the error icon replaces the suffix', (
      tester,
    ) async {
      const lock = Icon(Symbols.lock_rounded);
      await pumpThemed(
        tester,
        const AppTextField(
          label: 'Phone number',
          prefixIcon: Symbols.call_rounded,
          suffix: lock,
        ),
      );
      expect(find.byIcon(Symbols.call_rounded), findsOneWidget);
      expect(find.byIcon(Symbols.lock_rounded), findsOneWidget);

      await pumpThemed(
        tester,
        const AppTextField(
          label: 'Phone number',
          prefixIcon: Symbols.call_rounded,
          suffix: lock,
          errorText: 'Enter a valid phone number, e.g. 0908 123 456.',
        ),
      );
      expect(find.byIcon(Symbols.lock_rounded), findsNothing);
      expect(find.byIcon(Symbols.error_rounded), findsOneWidget);
    });

    testWidgets('read-only field opens a picker on tap', (tester) async {
      var taps = 0;
      await pumpThemed(
        tester,
        AppTextField(
          label: 'Academic standing & graduation',
          readOnly: true,
          onTap: () => taps++,
        ),
      );
      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(taps, 1);
      expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);
    });
  });

  group('AppTag', () {
    testWidgets('compact tag hugs its label (Internship Card)', (tester) async {
      await pumpThemed(
        tester,
        const Align(
          alignment: Alignment.topLeft,
          child: AppTag(label: 'Flutter'),
        ),
      );
      // 12 sp caption (16 line height) + 4 dp padding above and below.
      expect(tester.getSize(find.byType(AppTag)).height, 24);
    });

    testWidgets('large tag is 44 dp tall with the label centred', (
      tester,
    ) async {
      await pumpThemed(
        tester,
        const Align(
          alignment: Alignment.topLeft,
          child: AppTag(label: 'Flutter', size: AppTagSize.large),
        ),
      );
      final tag = tester.getRect(find.byType(AppTag));
      final label = tester.getRect(find.text('Flutter'));
      expect(tag.height, 44);
      expect(label.center.dy, closeTo(tag.center.dy, 0.5));
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

    for (final width in checkWidths) {
      testWidgets('default placeholder stays on one line at $width dp', (
        tester,
      ) async {
        await pumpThemed(
          tester,
          AppSearchField(onFilterPressed: () {}),
          width: width,
        );
        final hint = tester.renderObject<RenderParagraph>(
          find.text('Search role, company, skill'),
        );
        expect(hint.maxLines, 1);
        expect(hint.didExceedMaxLines, isFalse);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('wrapHint lets a long placeholder wrap without overflow', (
      tester,
    ) async {
      await pumpThemed(
        tester,
        const AppSearchField(
          hintText: 'Search skills (e.g. Flutter, SQL, Python)',
          wrapHint: true,
        ),
      );
      final hint = tester.renderObject<RenderParagraph>(
        find.text('Search skills (e.g. Flutter, SQL, Python)'),
      );
      expect(hint.maxLines, 2);
      expect(tester.takeException(), isNull);
    });
  });

  group('InternshipCard', () {
    Widget card({
      bool saved = false,
      bool applied = false,
      String allowance = 'Allowance text',
      VoidCallback? onSave,
      VoidCallback? onTap,
    }) {
      return InternshipCard(
        title: 'Software Engineering Intern - Mobile Platform Team',
        companyName: 'Northstar Labs',
        location: 'District 1, Ho Chi Minh City',
        workMode: 'Hybrid',
        tags: const ['Flutter', 'Dart', 'Firebase', 'REST API'],
        allowanceText: allowance,
        postedText: 'Posted 2 days ago',
        isSaved: saved,
        isApplied: applied,
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

    for (final width in checkWidths) {
      testWidgets(
        'Applied badge fits next to a long allowance at $width dp (CR-14)',
        (tester) async {
          final handle = tester.ensureSemantics();
          await pumpThemed(
            tester,
            card(
              applied: true,
              allowance: 'About 5,000,000–7,000,000 VND / mo',
              onSave: () {},
              onTap: () {},
            ),
            width: width,
          );
          expect(tester.takeException(), isNull);
          expect(find.text('Applied'), findsOneWidget);
          expect(find.bySemanticsLabel(RegExp(r'Applied$')), findsOneWidget);
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          handle.dispose();
        },
      );
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
            appBar: MainTabAppBar(
              title: 'Saved',
              user: user,
              onProfile: () {},
              onNotifications: () {},
            ),
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
        // No brand mark in the leading slot (DC-20).
        expect(find.byIcon(Symbols.school_rounded), findsNothing);
        expect(find.byIcon(Symbols.notifications_rounded), findsOneWidget);
        expect(find.byTooltip('Notifications'), findsOneWidget);
        expect(find.byTooltip('Profile'), findsOneWidget);
        // No photo, so the avatar falls back to the person glyph.
        expect(find.byIcon(Symbols.person_rounded), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    for (final (count, label) in [(3, '3'), (12, '9+')]) {
      testWidgets('$count unread shows a red badge with $label', (
        tester,
      ) async {
        setScreenSize(tester);
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              appBar: MainTabAppBar(
                title: 'Saved',
                user: testUser,
                onProfile: () {},
                onNotifications: () {},
                unreadNotifications: count,
              ),
            ),
          ),
        );

        final badge = tester.widget<Badge>(find.byType(Badge));
        expect(badge.isLabelVisible, isTrue);
        expect(badge.backgroundColor, AppColors.error);
        expect(find.text(label), findsOneWidget);
        // The tooltip is unchanged; the count is the button's value.
        expect(find.byTooltip('Notifications'), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                widget.properties.value == '$count unread',
          ),
          findsOneWidget,
        );
      });
    }

    testWidgets('no unread notifications shows no badge', (tester) async {
      await pumpBar(tester, user: testUser);
      expect(tester.widget<Badge>(find.byType(Badge)).isLabelVisible, isFalse);
    });

    testWidgets('touch targets are at least 48 dp', (tester) async {
      await pumpBar(tester, user: testUser);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });

    for (final width in checkWidths) {
      testWidgets('a long name steps down the heading at $width dp', (
        tester,
      ) async {
        setScreenSize(tester, width: width);
        Future<double?> sizeFor(String name) async {
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.light(),
              home: Scaffold(
                appBar: MainTabAppBar(
                  title: name,
                  greeting: 'Good evening',
                  user: testUser,
                  onProfile: () {},
                  onNotifications: () {},
                ),
              ),
            ),
          );
          return tester.widget<Text>(find.text(name)).style?.fontSize;
        }

        expect(await sizeFor('Anh'), 24);
        expect(await sizeFor('Phạm Nguyễn Hoàng Anh'), lessThan(24));
        expect(
          await sizeFor('Phạm Nguyễn Hoàng Anh Christopher Alexander'),
          18,
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('Home: greeting and avatar; the avatar opens Profile', (
      tester,
    ) async {
      setScreenSize(tester);
      var opened = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            appBar: MainTabAppBar(
              title: 'Test Student',
              greeting: 'Good morning',
              user: testUser,
              onProfile: () => opened = true,
              onNotifications: () {},
            ),
          ),
        ),
      );

      expect(find.text('Good morning'), findsOneWidget);
      expect(find.text('Test Student'), findsOneWidget);
      await tester.tap(find.byTooltip('Profile'));
      expect(opened, isTrue);
      expect(tester.takeException(), isNull);
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
