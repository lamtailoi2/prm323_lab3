import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/widgets/app_button.dart';
import '../../../models/internship.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_spacing.dart';
import '../models/search_filter_criteria.dart';

/// Modal bottom sheet allowing the student to adjust filters:
/// Work mode (single/multiple), Location, Skills, Job type, and Allowance range.
class SearchResultsFilterSheet extends StatefulWidget {
  const SearchResultsFilterSheet({
    super.key,
    required this.initialCriteria,
    required this.matchingCountCalculator,
    required this.onApply,
    required this.suggestedSkills,
  });

  final SearchFilterCriteria initialCriteria;
  final int Function(SearchFilterCriteria) matchingCountCalculator;
  final ValueChanged<SearchFilterCriteria> onApply;

  /// Skills the current pool mentions, from `suggestedFilterSkills`, so every
  /// chip narrows the list instead of offering a fixed vocabulary.
  final List<String> suggestedSkills;

  /// Opens the sheet. [matchingCountCalculator] and [suggestedSkills] read the
  /// caller's listings; [listingsChanged] is the provider those listings live
  /// in, so the count and the skill chips follow it while the sheet is open.
  static Future<void> show({
    required BuildContext context,
    required SearchFilterCriteria currentCriteria,
    required int Function(SearchFilterCriteria) matchingCountCalculator,
    required ValueChanged<SearchFilterCriteria> onApply,
    required List<String> Function() suggestedSkills,
    required ProviderListenable<Object?> listingsChanged,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.large),
        ),
      ),
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.85,
        // Rebuilt when the listings change: opened before the first pool
        // snapshot, the sheet otherwise kept `Show 0 results` and no skill
        // chips until the next selection (CR-11). The State below keeps the
        // criteria being edited across rebuilds.
        child: Consumer(
          builder: (context, ref, _) {
            ref.watch(listingsChanged);
            return SearchResultsFilterSheet(
              initialCriteria: currentCriteria,
              matchingCountCalculator: matchingCountCalculator,
              onApply: onApply,
              suggestedSkills: suggestedSkills(),
            );
          },
        ),
      ),
    );
  }

  @override
  State<SearchResultsFilterSheet> createState() =>
      _SearchResultsFilterSheetState();
}

class _SearchResultsFilterSheetState extends State<SearchResultsFilterSheet> {
  late SearchFilterCriteria _criteria;

  static const List<String> _locationOptions = [
    'Any location',
    'Ho Chi Minh City',
    'Ha Noi',
    'Da Nang',
  ];

  static const List<String> _jobTypeOptions = [
    'Any job type',
    'Internship',
    'Full-time',
    'Part-time',
  ];

  static const List<String> _allowanceOptions = [
    'Any allowance',
    'Paid only',
    'Above 5M VND/mo',
    'Negotiable',
  ];

  @override
  void initState() {
    super.initState();
    _criteria = widget.initialCriteria;
  }

  void _toggleWorkMode(WorkMode mode) {
    final nextModes = Set<WorkMode>.from(_criteria.workModes);
    if (nextModes.contains(mode)) {
      nextModes.remove(mode);
    } else {
      nextModes.add(mode);
    }
    setState(() {
      _criteria = _criteria.copyWith(workModes: nextModes);
    });
  }

  void _toggleSkill(String skill) {
    final nextSkills = Set<String>.from(_criteria.skills);
    if (nextSkills.contains(skill)) {
      nextSkills.remove(skill);
    } else {
      nextSkills.add(skill);
    }
    setState(() {
      _criteria = _criteria.copyWith(skills: nextSkills);
    });
  }

  void _clearAll() {
    setState(() {
      _criteria = const SearchFilterCriteria();
    });
  }

  Future<void> _selectOption({
    required String title,
    required List<String> options,
    required String current,
    required ValueChanged<String> onSelected,
  }) async {
    final chosen = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(title),
        children: [
          for (final option in options)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, option),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
                child: Row(
                  children: [
                    if (option == current)
                      const Icon(
                        Symbols.check_rounded,
                        size: 20,
                        color: AppColors.primary,
                      )
                    else
                      const SizedBox(width: 20),
                    const SizedBox(width: AppSpacing.s12),
                    Text(option),
                  ],
                ),
              ),
            ),
        ],
      ),
    );

    if (chosen != null) {
      onSelected(chosen);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final criteriaCount = _criteria.criteriaCount;
    final matchingCount = widget.matchingCountCalculator(_criteria);
    // A selected skill stays visible even when the pool no longer mentions
    // it, so it can still be removed from the sheet.
    final skillOptions = <String>[
      ...widget.suggestedSkills,
      for (final skill in _criteria.skills)
        if (!widget.suggestedSkills.contains(skill)) skill,
    ];

    return SafeArea(
      child: Column(
        children: [
          // No handle here: BottomSheetThemeData.showDragHandle already draws
          // one, as on the Profile sheets.
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenHorizontal,
              AppSpacing.s8,
              AppSpacing.s8,
              AppSpacing.s8,
            ),
            child: Row(
              children: [
                Text(
                  'Filters',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (criteriaCount > 0) ...[
                  const SizedBox(width: AppSpacing.s8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s8,
                      vertical: AppSpacing.s4,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: AppRadii.fullAll,
                    ),
                    child: Text(
                      '$criteriaCount active',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                IconButton(
                  icon: const Icon(Symbols.close_rounded),
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.surfaceVariant),
          // Scrollable Filter Sections
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
                vertical: AppSpacing.s16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Work mode section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Work mode',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Single or multiple',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  Wrap(
                    spacing: AppSpacing.s8,
                    runSpacing: AppSpacing.s8,
                    children: [
                      _FilterSelectionChip(
                        label: 'On-site',
                        selected: _criteria.workModes.contains(WorkMode.onSite),
                        onSelected: (_) => _toggleWorkMode(WorkMode.onSite),
                      ),
                      _FilterSelectionChip(
                        label: 'Remote',
                        selected: _criteria.workModes.contains(WorkMode.remote),
                        onSelected: (_) => _toggleWorkMode(WorkMode.remote),
                      ),
                      _FilterSelectionChip(
                        label: 'Hybrid',
                        selected: _criteria.workModes.contains(WorkMode.hybrid),
                        onSelected: (_) => _toggleWorkMode(WorkMode.hybrid),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  // Location section
                  _FilterDropdownTile(
                    title: 'Location',
                    value: _criteria.location ?? 'Any location',
                    onTap: () => _selectOption(
                      title: 'Select location',
                      options: _locationOptions,
                      current: _criteria.location ?? 'Any location',
                      onSelected: (val) {
                        setState(() {
                          _criteria = _criteria.copyWith(
                            location: val,
                            clearLocation: val == 'Any location',
                          );
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s24),
                  // Skills section: only skills the pool mentions, hidden
                  // until the first snapshot arrives.
                  if (skillOptions.isNotEmpty) ...[
                    Text(
                      'Skills',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s12),
                    Wrap(
                      spacing: AppSpacing.s8,
                      runSpacing: AppSpacing.s8,
                      children: [
                        for (final skill in skillOptions)
                          _FilterSelectionChip(
                            label: skill,
                            selected: _criteria.skills.contains(skill),
                            onSelected: (_) => _toggleSkill(skill),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s16),
                  ],
                  // Job type section
                  _FilterDropdownTile(
                    title: 'Job type',
                    value: _criteria.jobType ?? 'Any job type',
                    onTap: () => _selectOption(
                      title: 'Select job type',
                      options: _jobTypeOptions,
                      current: _criteria.jobType ?? 'Any job type',
                      onSelected: (val) {
                        setState(() {
                          _criteria = _criteria.copyWith(
                            jobType: val,
                            clearJobType: val == 'Any job type',
                          );
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  // Allowance range section
                  _FilterDropdownTile(
                    title: 'Allowance range',
                    value: _criteria.allowanceRange ?? 'Any allowance',
                    onTap: () => _selectOption(
                      title: 'Select allowance range',
                      options: _allowanceOptions,
                      current: _criteria.allowanceRange ?? 'Any allowance',
                      onSelected: (val) {
                        setState(() {
                          _criteria = _criteria.copyWith(
                            allowanceRange: val,
                            clearAllowanceRange: val == 'Any allowance',
                          );
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s24),
                ],
              ),
            ),
          ),
          // Sticky Bottom Section
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenHorizontal,
              AppSpacing.s12,
              AppSpacing.screenHorizontal,
              AppSpacing.s16,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(
                            text: 'Filters applied: ',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          TextSpan(
                            text:
                                '$criteriaCount ${criteriaCount == 1 ? 'criterion' : 'criteria'}',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      style: textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: _clearAll,
                      child: const Text(
                        'Clear filters',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s8),
                AppButton(
                  label: 'Show $matchingCount results →',
                  expand: true,
                  onPressed: () {
                    widget.onApply(_criteria);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterSelectionChip extends StatelessWidget {
  const _FilterSelectionChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onSelected(!selected),
      borderRadius: AppRadii.mediumAll,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s12,
          vertical: AppSpacing.s12,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryContainer
              : AppColors.surfaceVariant,
          borderRadius: AppRadii.mediumAll,
          border: selected
              ? Border.all(color: AppColors.primary, width: 1.5)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (selected) ...[
              const Icon(
                Symbols.check_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.s4),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterDropdownTile extends StatelessWidget {
  const _FilterDropdownTile({
    required this.title,
    required this.value,
    required this.onTap,
  });

  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.mediumAll,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s12,
          vertical: AppSpacing.s12,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadii.mediumAll,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    value,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Symbols.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
