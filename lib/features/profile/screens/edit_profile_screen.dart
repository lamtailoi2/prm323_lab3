import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/state/view_state.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/state_view.dart';
import '../../../models/user_profile.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_sizes.dart';
import '../../../theme/app_spacing.dart';
import '../viewmodels/edit_profile_viewmodel.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../widgets/academic_standing_sheet.dart';
import '../widgets/profile_sheet.dart';

/// Edit profile (`/profile/edit`, no bottom navigation), following the
/// Edit Profile frame: photo, "Academic & personal details" and "Contact &
/// location" cards, `Save changes` and `Cancel`. Deviations: DC-14.
class EditProfileScreen extends ConsumerWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(profileViewModelProvider)) {
      ViewData<ProfileOverview>(:final data) => _EditProfileForm(
        overview: data,
      ),
      ViewError<ProfileOverview>(:final error) => Scaffold(
        appBar: const AppTopBar.back(title: 'Edit profile'),
        body: StateView.error(
          message: error.message,
          onRetry: () => ref.read(profileViewModelProvider.notifier).retry(),
        ),
      ),
      _ => const Scaffold(
        appBar: AppTopBar.back(title: 'Edit profile'),
        body: StateView.loading(message: 'Loading your profile'),
      ),
    };
  }
}

class _EditProfileForm extends ConsumerStatefulWidget {
  const _EditProfileForm({required this.overview});

  final ProfileOverview overview;

  @override
  ConsumerState<_EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends ConsumerState<_EditProfileForm> {
  late final TextEditingController _fullName;
  late final TextEditingController _headline;
  late final TextEditingController _university;
  late final TextEditingController _major;
  late final TextEditingController _academic;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _city;
  late final TextEditingController _bio;
  late final ProfileDetails _initial;

  @override
  void initState() {
    super.initState();
    final details = widget.overview.profile.details;
    // A new profile starts from the Google name, so most students only add
    // what Google does not know.
    _fullName = TextEditingController(
      text: details.fullName ?? widget.overview.account.displayName ?? '',
    );
    _headline = TextEditingController(text: details.headline ?? '');
    _university = TextEditingController(text: details.university ?? '');
    _major = TextEditingController(text: details.major ?? '');
    _academic = TextEditingController(
      text: EditProfileViewModel.academicStanding(
        details.yearOfStudy,
        details.graduationYear,
      ),
    );
    _email = TextEditingController(text: widget.overview.account.email ?? '');
    _phone = TextEditingController(text: details.phone ?? '');
    _city = TextEditingController(text: details.city ?? '');
    _bio = TextEditingController(text: details.bio ?? '');
    _initial = ref.read(editProfileViewModelProvider.notifier).details(_form);
  }

  @override
  void dispose() {
    for (final controller in [
      _fullName,
      _headline,
      _university,
      _major,
      _academic,
      _email,
      _phone,
      _city,
      _bio,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  ProfileForm get _form => (
    fullName: _fullName.text,
    headline: _headline.text,
    university: _university.text,
    major: _major.text,
    phone: _phone.text,
    city: _city.text,
    bio: _bio.text,
  );

  Future<void> _save() async {
    final saved = await ref
        .read(editProfileViewModelProvider.notifier)
        .save(_form);
    if (saved && mounted) Navigator.of(context).pop();
  }

  Future<void> _confirmLeave() async {
    final changed =
        ref.read(editProfileViewModelProvider.notifier).details(_form) !=
        _initial;
    final leave =
        !changed ||
        (await showAppDialog(
              context,
              title: 'Discard your changes?',
              message: 'Your profile changes have not been saved yet.',
              primaryLabel: 'Discard',
              secondaryLabel: 'Keep editing',
            ) ??
            false);
    if (leave && mounted) Navigator.of(context).pop();
  }

  void _leave() => unawaited(_confirmLeave());

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editProfileViewModelProvider);
    final errors = state.errors;
    ref.listen(editProfileViewModelProvider, (_, next) {
      _academic.text = EditProfileViewModel.academicStanding(
        next.yearOfStudy,
        next.graduationYear,
      );
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        appBar: AppTopBar.back(
          title: 'Edit profile',
          actions: [
            AppButton(
              label: 'Cancel',
              variant: AppButtonVariant.text,
              onPressed: _leave,
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          children: [
            _Photo(photoUrl: widget.overview.account.photoUrl),
            const SizedBox(height: AppSpacing.section),
            _FormCard(
              icon: Symbols.school_rounded,
              title: 'Academic & personal details',
              children: [
                ListenableBuilder(
                  listenable: _fullName,
                  builder: (context, _) => AppTextField(
                    label: 'Full name',
                    isRequired: true,
                    controller: _fullName,
                    hintText: 'e.g. Minh Nguyen',
                    errorText: errors.fullName,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    suffix: _fullName.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear full name',
                            icon: const Icon(
                              Symbols.cancel_rounded,
                              size: AppSizes.iconSmall,
                            ),
                            color: AppColors.textSecondary,
                            onPressed: _fullName.clear,
                          ),
                  ),
                ),
                AppTextField(
                  // "Headline" only: target roles are chosen in
                  // Update preferences (DC-14).
                  label: 'Headline',
                  isRequired: true,
                  controller: _headline,
                  hintText: 'e.g. Software Engineering Student',
                  helperText: 'Shown under your name on your profile.',
                  errorText: errors.headline,
                  textInputAction: TextInputAction.next,
                ),
                AppTextField(
                  label: 'University / institution',
                  controller: _university,
                  prefixIcon: Symbols.account_balance_rounded,
                  hintText: 'e.g. HCMC University of Technology',
                  errorText: errors.university,
                  textInputAction: TextInputAction.next,
                ),
                AppTextField(
                  label: 'Major / degree program',
                  controller: _major,
                  prefixIcon: Symbols.menu_book_rounded,
                  hintText: 'e.g. Software Engineering',
                  errorText: errors.major,
                  textInputAction: TextInputAction.next,
                ),
                AppTextField(
                  label: 'Academic standing & graduation',
                  controller: _academic,
                  prefixIcon: Symbols.calendar_month_rounded,
                  hintText: 'Tap to choose',
                  readOnly: true,
                  // Wraps instead of cutting "Graduating 2026" at 360 dp.
                  maxLines: null,
                  onTap: () => showProfileSheet(
                    context,
                    (_) => const AcademicStandingSheet(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.section),
            _FormCard(
              icon: Symbols.contact_page_rounded,
              title: 'Contact & location',
              children: [
                AppTextField(
                  label: 'Email',
                  controller: _email,
                  prefixIcon: Symbols.alternate_email_rounded,
                  helperText: 'From your Google account',
                  enabled: false,
                  suffix: const Icon(
                    Symbols.lock_rounded,
                    size: AppSizes.iconSmall,
                    color: AppColors.disabled,
                  ),
                ),
                AppTextField(
                  label: 'Phone number',
                  controller: _phone,
                  prefixIcon: Symbols.call_rounded,
                  hintText: 'e.g. 0908 123 456',
                  errorText: errors.phone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.telephoneNumber],
                ),
                AppTextField(
                  label: 'Location / current city',
                  controller: _city,
                  prefixIcon: Symbols.location_on_rounded,
                  hintText: 'e.g. Ho Chi Minh City',
                  errorText: errors.city,
                  textInputAction: TextInputAction.next,
                ),
                AppTextField(
                  label: 'Short bio / introduction',
                  controller: _bio,
                  hintText:
                      'e.g. Third-year student looking for a mobile '
                      'internship.',
                  errorText: errors.bio,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  minLines: 4,
                  maxLines: 6,
                  maxLength: EditProfileViewModel.maxBioLength,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.section),
            if (state.save.error case final AppException error) ...[
              FormMessage(message: error.message, isInfo: error.isCancelled),
              const SizedBox(height: AppSpacing.s12),
            ],
            AppButton(
              label: 'Save changes',
              icon: Symbols.save_rounded,
              isLoading: state.save.isLoading,
              expand: true,
              onPressed: _save,
            ),
            const SizedBox(height: AppSpacing.s4),
            AppButton(
              label: 'Cancel',
              variant: AppButtonVariant.text,
              expand: true,
              onPressed: _leave,
            ),
          ],
        ),
      ),
    );
  }
}

/// The current photo. It comes from the Google account: uploading another
/// photo would need an image folder in `storage.rules` (G-29).
class _Photo extends StatelessWidget {
  const _Photo({required this.photoUrl});

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl;
    return Column(
      children: [
        ExcludeSemantics(
          child: ClipOval(
            child: SizedBox.square(
              dimension: AppSizes.editProfileAvatar,
              child: ColoredBox(
                color: AppColors.primaryContainer,
                child: url == null
                    ? const Icon(
                        Symbols.person_rounded,
                        color: AppColors.primary,
                      )
                    : Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                          Symbols.person_rounded,
                          color: AppColors.primary,
                        ),
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          'Your photo comes from your Google account.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// A white card with a heading row and fields 16 dp apart.
class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: AppSizes.iconSmall, color: AppColors.primary),
                const SizedBox(width: AppSpacing.s8),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
              ],
            ),
            for (final child in children) ...[
              const SizedBox(height: AppSpacing.s16),
              child,
            ],
          ],
        ),
      ),
    );
  }
}
