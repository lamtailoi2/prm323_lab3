import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../models/user_profile.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_sizes.dart';
import '../../../theme/app_spacing.dart';
import '../viewmodels/edit_preferences_viewmodel.dart';

/// Update preferences sheet (Lab 2 `profile-preferences.png`): target roles
/// and work modes (multi-select chips with a check and outline), experience
/// (single-select) and a location field with quick-select cities.
class EditPreferencesSheet extends ConsumerStatefulWidget {
  const EditPreferencesSheet({super.key});

  @override
  ConsumerState<EditPreferencesSheet> createState() =>
      _EditPreferencesSheetState();
}

class _EditPreferencesSheetState extends ConsumerState<EditPreferencesSheet> {
  late final TextEditingController _location = TextEditingController(
    text: ref.read(editPreferencesViewModelProvider).location,
  );

  @override
  void dispose() {
    _location.dispose();
    super.dispose();
  }

  void _setLocation(String location) {
    _location.text = location;
    ref.read(editPreferencesViewModelProvider.notifier).setLocation(location);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editPreferencesViewModelProvider);
    final viewModel = ref.read(editPreferencesViewModelProvider.notifier);
    final typedLocation = state.location.trim().toLowerCase();

    return AppSheet(
      title: 'Update preferences',
      subtitle:
          'Customize roles, experience, work mode, and location for tailored '
          'matches',
      primaryLabel: 'Save preferences',
      isLoading: state.save.isLoading,
      error: switch (state.save.error) {
        final AppException error => error,
        _ => null,
      },
      onPrimary: () async {
        if (await viewModel.save() && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      children: [
        const SheetGroupHeader(
          title: 'Target roles',
          helper: 'Select roles you are interested in (multi-select)',
        ),
        Wrap(
          spacing: AppSpacing.s8,
          runSpacing: AppSpacing.s4,
          children: [
            for (final role in TargetRole.values)
              SheetChip(
                label: role.label,
                selected: state.targetRoles.contains(role),
                onSelected: () => viewModel.toggleRole(role),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.section),
        const SheetGroupHeader(
          title: 'Experience',
          helper:
              'Choose one; used to rank internships, never to hide listings',
        ),
        Wrap(
          spacing: AppSpacing.s8,
          runSpacing: AppSpacing.s4,
          children: [
            for (final range in ExperienceRange.values)
              SheetChip(
                label: range.label,
                selected: state.experience == range,
                onSelected: () => viewModel.selectExperience(range),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.section),
        const SheetGroupHeader(
          title: 'Work mode',
          helper: 'Preferred arrangement (multi-select)',
        ),
        Wrap(
          spacing: AppSpacing.s8,
          runSpacing: AppSpacing.s4,
          children: [
            for (final mode in EditPreferencesViewModel.workModeOptions)
              SheetChip(
                label: mode.label,
                selected: state.workModes.contains(mode),
                onSelected: () => viewModel.toggleWorkMode(mode),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.section),
        const SheetGroupHeader(
          title: 'Location',
          helper: 'Internships within your commuting distance',
        ),
        Semantics(
          label: 'Location',
          child: TextField(
            controller: _location,
            textInputAction: TextInputAction.done,
            onChanged: viewModel.setLocation,
            decoration: InputDecoration(
              hintText: 'e.g. Ho Chi Minh City',
              errorText: state.locationError,
              prefixIcon: const Icon(
                Symbols.location_on_rounded,
                color: AppColors.primary,
              ),
              suffixIcon: state.location.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear location',
                      icon: const Icon(
                        Symbols.cancel_rounded,
                        size: AppSizes.iconSmall,
                      ),
                      color: AppColors.textSecondary,
                      onPressed: () => _setLocation(''),
                    ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s12),
        Text('Quick select:', style: Theme.of(context).textTheme.bodyMedium),
        Wrap(
          spacing: AppSpacing.s8,
          runSpacing: AppSpacing.s4,
          children: [
            for (final city in EditPreferencesViewModel.quickLocations)
              SheetChip(
                label: city,
                selected: typedLocation == city.toLowerCase(),
                compact: true,
                showCheckmark: false,
                onSelected: () => _setLocation(city),
              ),
          ],
        ),
      ],
    );
  }
}
