import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/state/view_state.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/main_tab_app_bar.dart';
import '../../../core/widgets/state_view.dart';
import '../../../services/crashlytics_service.dart';
import '../../../theme/app_spacing.dart';
import '../../auth/viewmodels/sign_out_viewmodel.dart';
import '../viewmodels/open_cv_viewmodel.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../widgets/edit_preferences_sheet.dart';
import '../widgets/edit_skills_sheet.dart';
import '../widgets/profile_header_card.dart';
import '../widgets/profile_sections.dart';
import '../widgets/update_cv_sheet.dart';

/// Profile tab (Lab 2 `profile-final.png`, `docs/design/screen-spec.md`
/// §Profile): identity and `Edit profile`, CV / Resume, technical skills,
/// internship preferences, and Settings & support with Sign out.
///
/// Data lives in Firestore `users/{uid}`; the CV file in Cloud Storage
/// `cvs/{uid}/…`. Email and photo come from the Google account.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileViewModelProvider);
    final isSigningOut = ref.watch(signOutViewModelProvider).isLoading;
    final isOpeningCv = ref.watch(openCvViewModelProvider).isLoading;

    // Both ViewModels store only AppException, whose message is safe to show.
    void showError(AsyncValue<void> next) {
      if (next.error case final AppException error) {
        _showMessage(context, error.message);
      }
    }

    ref
      ..listen(signOutViewModelProvider, (_, next) => showError(next))
      ..listen(openCvViewModelProvider, (_, next) => showError(next));

    final content = switch (state) {
      // ViewEmpty is never emitted: a missing document is an empty profile.
      ViewLoading<ProfileOverview>() ||
      ViewEmpty<ProfileOverview>() => const <Widget>[ProfileSkeleton()],
      ViewError<ProfileOverview>(:final error) => [
        StateView.error(
          message: error.message,
          onRetry: () => ref.read(profileViewModelProvider.notifier).retry(),
        ),
      ],
      ViewData<ProfileOverview>(:final data) => [
        ProfileHeaderCard(
          overview: data,
          onEdit: () => context.go(AppRoutes.editProfile),
        ),
        const SizedBox(height: AppSpacing.section),
        CvSection(
          cv: data.profile.cv,
          onUpload: () => showAppSheet<void>(
            context,
            (_) => UpdateCvSheet(current: data.profile.cv),
          ),
          onView: switch (data.profile.cv) {
            final cv? when !isOpeningCv =>
              () => ref.read(openCvViewModelProvider.notifier).open(cv),
            _ => null,
          },
        ),
        const SizedBox(height: AppSpacing.section),
        SkillsSection(
          skills: data.profile.skills,
          onEdit: () =>
              showAppSheet<void>(context, (_) => const EditSkillsSheet()),
        ),
        const SizedBox(height: AppSpacing.section),
        PreferencesSection(
          preferences: data.profile.preferences,
          onEdit: () =>
              showAppSheet<void>(context, (_) => const EditPreferencesSheet()),
        ),
      ],
    };

    return Scaffold(
      // Bell only, no avatar: this tab is the profile (DC-15, DC-31).
      appBar: MainTabAppBar(
        title: 'Profile',
        onNotifications: () => context.push(AppRoutes.notificationCenter),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        children: [
          ...content,
          const SizedBox(height: AppSpacing.section),
          DiagnosticsSection(
            onOpenFirebaseDemo: () => context.push(AppRoutes.firebaseDemo),
            onTestCrash: () => _confirmTestCrash(context, ref),
          ),
          const SizedBox(height: AppSpacing.section),
          SettingsSection(
            isSigningOut: isSigningOut,
            onNotifications: () => _showMessage(
              context,
              'Notification preferences are coming soon.',
            ),
            onLanguage: () => _showMessage(
              context,
              'Internly is available in English only for now.',
            ),
            onHelp: () =>
                _showMessage(context, 'Help and support are coming soon.'),
            onSignOut: () =>
                ref.read(signOutViewModelProvider.notifier).signOut(),
          ),
        ],
      ),
    );
  }

  /// Forces a native crash so Crashlytics has a report to upload on the next
  /// launch (Lab 3 §6). Always behind a confirmation: the app closes.
  static Future<void> _confirmTestCrash(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showAppDialog(
      context,
      title: 'Simulate a crash?',
      message:
          'Internly will close immediately. Reopen it so Crashlytics can '
          'send the report.',
      primaryLabel: 'Crash now',
    );
    if (confirmed != true) return;
    ref.read(crashlyticsServiceProvider).crashForTesting();
  }

  static void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
