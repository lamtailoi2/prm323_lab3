import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/utils/display_format.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_tag.dart';
import '../../../core/widgets/cv_file_tile.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/user_profile.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_sizes.dart';
import '../../../theme/app_spacing.dart';
import 'profile_section.dart';

/// "CV library": every CV with its metadata, a default badge, and per-file
/// actions, plus `Add CV`. There is no Figma frame for the library yet, so it
/// reuses the Profile section and `CvFileTile` (G-33, DC-31).
class CvLibrarySection extends StatelessWidget {
  const CvLibrarySection({
    super.key,
    required this.cvs,
    required this.onAdd,
    required this.onView,
    required this.onSetDefault,
    required this.onRemove,
    this.defaultCv,
    this.isBusy = false,
  });

  final List<CvFile> cvs;
  final CvFile? defaultCv;
  final VoidCallback onAdd;
  final ValueChanged<CvFile> onView;
  final ValueChanged<CvFile> onSetDefault;
  final ValueChanged<CvFile> onRemove;

  /// Disables the actions while a library write is in flight.
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return ProfileSection(
      icon: Symbols.description_rounded,
      title: 'CV library',
      trailingText: cvs.isEmpty ? null : _fileCount(cvs.length),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (cvs.isEmpty)
            const ProfileHint('No CV yet. Add a PDF to use when you apply.')
          else
            for (var i = 0; i < cvs.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.s16),
              _CvLibraryTile(
                cv: cvs[i],
                isDefault: defaultCv?.storagePath == cvs[i].storagePath,
                isBusy: isBusy,
                onView: onView,
                onSetDefault: onSetDefault,
                onRemove: onRemove,
              ),
            ],
          const SizedBox(height: AppSpacing.s16),
          AppButton(
            label: 'Add CV',
            icon: Symbols.upload_file_rounded,
            variant: AppButtonVariant.secondary,
            expand: true,
            onPressed: isBusy ? null : onAdd,
          ),
        ],
      ),
    );
  }

  static String _fileCount(int count) => count == 1 ? '1 file' : '$count files';
}

class _CvLibraryTile extends StatelessWidget {
  const _CvLibraryTile({
    required this.cv,
    required this.isDefault,
    required this.isBusy,
    required this.onView,
    required this.onSetDefault,
    required this.onRemove,
  });

  final CvFile cv;
  final bool isDefault;
  final bool isBusy;
  final ValueChanged<CvFile> onView;
  final ValueChanged<CvFile> onSetDefault;
  final ValueChanged<CvFile> onRemove;

  @override
  Widget build(BuildContext context) {
    return CvFileTile(
      fileName: cv.displayName,
      details:
          '${formatShortDate(cv.uploadedAt)} · '
          '${formatFileSize(cv.sizeBytes)}',
      badge: isDefault
          ? const StatusBadge(
              label: 'Default for applications',
              icon: Symbols.check_circle_rounded,
              color: AppColors.success,
            )
          : null,
      trailing: PopupMenuButton<String>(
        tooltip: 'CV actions',
        enabled: !isBusy,
        icon: const Icon(
          Symbols.more_vert_rounded,
          color: AppColors.textSecondary,
        ),
        onSelected: (action) => switch (action) {
          'view' => onView(cv),
          'default' => onSetDefault(cv),
          'remove' => onRemove(cv),
          _ => null,
        },
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'view', child: Text('View')),
          PopupMenuItem(
            value: 'default',
            enabled: !isDefault,
            child: const Text('Set as default'),
          ),
          const PopupMenuItem(value: 'remove', child: Text('Remove')),
        ],
      ),
    );
  }
}

/// "Technical skills" as tags, with `Add skill` opening the Edit skills
/// sheet.
class SkillsSection extends StatelessWidget {
  const SkillsSection({super.key, required this.skills, required this.onEdit});

  final List<String> skills;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return ProfileSection(
      icon: Symbols.code_rounded,
      title: 'Technical skills',
      actionLabel: 'Add skill',
      actionIcon: Symbols.add_rounded,
      onAction: onEdit,
      child: skills.isEmpty
          ? const ProfileHint(
              'Add the skills you have, such as Flutter or SQL.',
            )
          : Wrap(
              spacing: AppSpacing.s8,
              runSpacing: AppSpacing.s8,
              children: [
                for (final skill in skills)
                  AppTag(label: skill, size: AppTagSize.large),
              ],
            ),
    );
  }
}

/// "Internship preferences": target roles, experience, work modes and
/// location, with `Update` opening the Update preferences sheet.
class PreferencesSection extends StatelessWidget {
  const PreferencesSection({
    super.key,
    required this.preferences,
    required this.onEdit,
  });

  final InternshipPreferences preferences;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ProfileSection(
      icon: Symbols.tune_rounded,
      title: 'Internship preferences',
      actionLabel: 'Update',
      onAction: onEdit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TagGroup(
            label: 'Target roles',
            tags: [for (final role in preferences.targetRoles) role.label],
          ),
          const SizedBox(height: AppSpacing.s16),
          _TagGroup(
            label: 'Experience',
            tags: [
              if (preferences.experience case final experience?)
                experience.label,
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
          _TagGroup(
            label: 'Work mode',
            tags: [for (final mode in preferences.workModes) mode.label],
          ),
          const SizedBox(height: AppSpacing.s16),
          Row(
            children: [
              const Icon(
                Symbols.location_on_rounded,
                size: AppSizes.iconSmall,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.s8),
              Text('Location', style: textTheme.bodyMedium),
              const SizedBox(width: AppSpacing.s16),
              Expanded(
                child: Text(
                  preferences.location ?? 'Not set',
                  style: preferences.location == null
                      ? textTheme.bodyMedium
                      : textTheme.labelLarge,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TagGroup extends StatelessWidget {
  const _TagGroup({required this.label, required this.tags});

  final String label;
  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.s8),
        if (tags.isEmpty)
          const ProfileHint('Not set')
        else
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: [
              for (final tag in tags)
                AppTag(label: tag, size: AppTagSize.large),
            ],
          ),
      ],
    );
  }
}

/// "Settings & support" list. Sign out stays reachable in every state of
/// the screen, including when the profile fails to load.
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.onNotifications,
    required this.onLanguage,
    required this.onHelp,
    required this.onSignOut,
    required this.isSigningOut,
  });

  final VoidCallback onNotifications;
  final VoidCallback onLanguage;
  final VoidCallback onHelp;
  final VoidCallback onSignOut;
  final bool isSigningOut;

  @override
  Widget build(BuildContext context) {
    const chevron = Icon(
      Symbols.chevron_right_rounded,
      color: AppColors.textSecondary,
    );
    return ProfileSection(
      icon: Symbols.settings_rounded,
      title: 'Settings & support',
      padded: false,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Symbols.notifications_rounded),
            title: const Text('Notification preferences'),
            trailing: chevron,
            onTap: onNotifications,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Symbols.language_rounded),
            title: const Text('Language'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('English', style: Theme.of(context).textTheme.bodyMedium),
                chevron,
              ],
            ),
            onTap: onLanguage,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Symbols.help_rounded),
            title: const Text('Help & support'),
            trailing: chevron,
            onTap: onHelp,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Symbols.logout_rounded),
            title: const Text('Sign out'),
            iconColor: AppColors.error,
            textColor: AppColors.error,
            enabled: !isSigningOut,
            trailing: isSigningOut
                ? const SizedBox.square(
                    dimension: AppSizes.iconSmall,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            onTap: onSignOut,
          ),
        ],
      ),
    );
  }
}

/// "Diagnostics": the Crashlytics test control (G-06) and the entry point to
/// the Firebase demo area. The crash stays on Profile so a student can run it
/// without opening the demo screen.
class DiagnosticsSection extends StatelessWidget {
  const DiagnosticsSection({
    super.key,
    required this.onOpenFirebaseDemo,
    required this.onTestCrash,
  });

  final VoidCallback onOpenFirebaseDemo;
  final VoidCallback onTestCrash;

  @override
  Widget build(BuildContext context) {
    const chevron = Icon(
      Symbols.chevron_right_rounded,
      color: AppColors.textSecondary,
    );
    return ProfileSection(
      icon: Symbols.bug_report_rounded,
      title: 'Diagnostics',
      padded: false,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Symbols.bug_report_rounded),
            title: const Text('Simulate app crash'),
            subtitle: const Text('Closes the app and sends a crash report.'),
            trailing: chevron,
            onTap: onTestCrash,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Symbols.tune_rounded),
            title: const Text('Firebase demo'),
            subtitle: const Text(
              'Remote Config values, non-fatal test and links.',
            ),
            trailing: chevron,
            onTap: onOpenFirebaseDemo,
          ),
        ],
      ),
    );
  }
}

/// Card-shaped placeholders while the profile loads.
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Loading your profile',
      child: const ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.s16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        SkeletonBox(
                          width: AppSizes.profileHeaderAvatar,
                          height: AppSizes.profileHeaderAvatar,
                          borderRadius: AppRadii.fullAll,
                        ),
                        SizedBox(width: AppSpacing.s16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SkeletonBox(height: 20),
                              SizedBox(height: AppSpacing.s8),
                              FractionallySizedBox(
                                widthFactor: 0.6,
                                child: SkeletonBox(height: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.s16),
                    FractionallySizedBox(
                      widthFactor: 0.7,
                      alignment: Alignment.centerLeft,
                      child: SkeletonBox(height: 14),
                    ),
                    SizedBox(height: AppSpacing.s16),
                    SkeletonBox(
                      height: AppSizes.buttonHeight,
                      borderRadius: AppRadii.mediumAll,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: AppSpacing.section),
            Card(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.s16),
                child: Row(
                  children: [
                    SkeletonBox(
                      width: AppSizes.fileTile,
                      height: AppSizes.fileTile,
                    ),
                    SizedBox(width: AppSpacing.s12),
                    Expanded(child: SkeletonBox(height: 14)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
