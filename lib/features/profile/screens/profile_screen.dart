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
import '../../../models/user_profile.dart';
import '../../../services/crashlytics_service.dart';
import '../../../theme/app_spacing.dart';
import '../../auth/viewmodels/sign_out_viewmodel.dart';
import '../viewmodels/cv_library_viewmodel.dart';
import '../../notifications/viewmodels/unread_notifications_provider.dart';
import '../viewmodels/open_cv_viewmodel.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../widgets/add_cv_sheet.dart';
import '../widgets/edit_preferences_sheet.dart';
import '../widgets/edit_skills_sheet.dart';
import '../widgets/profile_header_card.dart';
import '../widgets/profile_sections.dart';

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
    final cvState = ref.watch(cvLibraryViewModelProvider);

    // Both ViewModels store only AppException, whose message is safe to show.
    void showError(AsyncValue<void> next) {
      if (next.error case final AppException error) {
        _showMessage(context, error.message);
      }
    }

    ref
      ..listen(signOutViewModelProvider, (_, next) => showError(next))
      ..listen(openCvViewModelProvider, (_, next) => showError(next))
      ..listen(cvLibraryViewModelProvider, (_, next) {
        if (next.notice case final notice?) {
          _showMessage(context, notice);
        }
      });

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
        CvLibrarySection(
          cvs: data.library,
          defaultCv: data.defaultCv,
          isBusy: cvState.isBusy,
          onAdd: () => showAppSheet<void>(context, (_) => const AddCvSheet()),
          onView: (cv) {
            if (!isOpeningCv) {
              ref.read(openCvViewModelProvider.notifier).open(cv);
            }
          },
          onSetDefault: (cv) => _setDefaultCv(context, ref, cv),
          onRemove: (cv) => _confirmRemoveCv(context, ref, cv),
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
        unreadNotifications:
            ref.watch(unreadNotificationCountProvider).value ?? 0,
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

  static Future<void> _setDefaultCv(
    BuildContext context,
    WidgetRef ref,
    CvFile cv,
  ) async {
    final saved = await ref
        .read(cvLibraryViewModelProvider.notifier)
        .setDefault(cv);
    if (saved || !context.mounted) return;
    _showCvErrorIfAny(context, ref);
  }

  /// Confirms removing a CV from the library. A submitted application keeps
  /// its own snapshot, so the copy is only removed when nothing references
  /// it (G-33).
  static Future<void> _confirmRemoveCv(
    BuildContext context,
    WidgetRef ref,
    CvFile cv,
  ) async {
    final confirmed = await showAppDialog(
      context,
      title: 'Remove this CV?',
      message:
          '"${cv.displayName}" will be removed from your library. A '
          'submitted application keeps its own copy.',
      primaryLabel: 'Remove',
    );
    if (confirmed != true || !context.mounted) return;
    final removed = await ref
        .read(cvLibraryViewModelProvider.notifier)
        .remove(cv);
    if (removed || !context.mounted) return;
    _showCvErrorIfAny(context, ref);
  }

  /// Shows the library action failure outside the Add CV sheet, where the
  /// sheet is not there to render it inline.
  static void _showCvErrorIfAny(BuildContext context, WidgetRef ref) {
    if (ref.read(cvLibraryViewModelProvider).error case final error?) {
      _showMessage(context, error.message);
    }
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
