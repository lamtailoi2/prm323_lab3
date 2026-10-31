import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../theme/app_spacing.dart';
import '../viewmodels/edit_profile_viewmodel.dart';
import 'profile_sheet.dart';

/// Picker behind the "Academic standing & graduation" field of Edit profile.
/// The frame shows only the field ("Year 3 · Graduating 2026"), so the
/// picker reuses the sheet layout and Filter Chips (DC-14): year of study
/// as a wrap, graduation years as one horizontally scrolling row. Each tap
/// updates the form at once; the form is saved with `Save changes`.
class AcademicStandingSheet extends ConsumerStatefulWidget {
  const AcademicStandingSheet({super.key});

  @override
  ConsumerState<AcademicStandingSheet> createState() =>
      _AcademicStandingSheetState();
}

class _AcademicStandingSheetState extends ConsumerState<AcademicStandingSheet> {
  /// The graduation year chosen when the sheet opened, scrolled into view.
  final GlobalKey _openingYear = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _openingYear.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(context, alignment: 0.5);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editProfileViewModelProvider);
    final viewModel = ref.read(editProfileViewModelProvider.notifier);
    final textTheme = Theme.of(context).textTheme;
    final openingYear = ref.read(editProfileViewModelProvider).graduationYear;
    final years = {
      ...EditProfileViewModel.graduationYears(DateTime.now()),
      ?state.graduationYear,
    }.toList()..sort();

    return ProfileSheet(
      icon: Symbols.event_rounded,
      title: 'Academic standing',
      subtitle: 'Choose your year of study and expected graduation',
      primaryLabel: 'Done',
      showCancel: false,
      onPrimary: () => Navigator.of(context).pop(),
      children: [
        Semantics(
          header: true,
          child: Text('Year of study', style: textTheme.labelLarge),
        ),
        Wrap(
          spacing: AppSpacing.s8,
          runSpacing: AppSpacing.s4,
          children: [
            for (
              var year = 1;
              year <= EditProfileViewModel.maxYearOfStudy;
              year++
            )
              SheetChip(
                label: 'Year $year',
                selected: state.yearOfStudy == year,
                onSelected: () => viewModel.selectYearOfStudy(year),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.section),
        Semantics(
          header: true,
          child: Text('Expected graduation', style: textTheme.labelLarge),
        ),
        // About nine years: all built at once, so the opening year can be
        // scrolled into view.
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final year in years) ...[
                if (year != years.first) const SizedBox(width: AppSpacing.s8),
                SheetChip(
                  key: year == openingYear ? _openingYear : null,
                  label: '$year',
                  selected: state.graduationYear == year,
                  onSelected: () => viewModel.selectGraduationYear(year),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
