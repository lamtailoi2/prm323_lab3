import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/data/vietnamese_universities.dart';
import '../../../core/widgets/app_search_field.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_sizes.dart';
import '../../../theme/app_spacing.dart';

/// `Select your university` (Apply Form frames): search the curated list, tap
/// a name, or type an institution that is not listed.
///
/// Pops the chosen name; `null` when the sheet is dismissed.
class UniversitySheet extends StatefulWidget {
  const UniversitySheet({super.key, this.selected});

  final String? selected;

  @override
  State<UniversitySheet> createState() => _UniversitySheetState();
}

class _UniversitySheetState extends State<UniversitySheet> {
  final TextEditingController _manual = TextEditingController();
  String _query = '';
  bool _enteringManually = false;

  @override
  void dispose() {
    _manual.dispose();
    super.dispose();
  }

  void _choose(String name) {
    final trimmed = name.trim();
    if (trimmed.isNotEmpty) Navigator.of(context).pop(trimmed);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final query = _query.trim().toLowerCase();
    final matches = <String>[
      for (final name in vietnameseUniversities)
        if (query.isEmpty || name.toLowerCase().contains(query)) name,
    ];

    return AppSheet(
      icon: Symbols.school_rounded,
      title: 'Select your university',
      subtitle: _enteringManually
          ? 'Type your institution'
          : 'Search the list or add your institution',
      primaryLabel: _enteringManually ? 'Use this university' : 'Close',
      primaryIcon: _enteringManually ? Symbols.check_rounded : null,
      showCancel: false,
      onPrimary: _enteringManually
          ? () => _choose(_manual.text)
          : () => Navigator.of(context).pop(),
      children: _enteringManually
          ? [
              AppTextField(
                label: 'University / institution',
                controller: _manual,
                hintText: 'e.g. HCMC University of Technology',
                textInputAction: TextInputAction.done,
                onSubmitted: _choose,
              ),
              const SizedBox(height: AppSpacing.s8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => setState(() => _enteringManually = false),
                  child: const Text('Back to the list'),
                ),
              ),
            ]
          : [
              AppSearchField(
                hintText: 'Search university',
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: AppSpacing.s16),
              if (matches.isEmpty)
                Text(
                  'No university matches "$_query".',
                  style: textTheme.bodyMedium,
                )
              else
                for (final name in matches)
                  _UniversityRow(
                    name: name,
                    isSelected: name == widget.selected,
                    onTap: () => _choose(name),
                  ),
              const SizedBox(height: AppSpacing.s8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => setState(() => _enteringManually = true),
                  child: const Text(
                    "Can't find your university? Enter manually",
                  ),
                ),
              ),
            ],
    );
  }
}

/// One university of the list, with a check on the stored choice.
class _UniversityRow extends StatelessWidget {
  const _UniversityRow({
    required this.name,
    required this.isSelected,
    required this.onTap,
  });

  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: isSelected,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Symbols.check_rounded,
                    size: AppSizes.iconSmall,
                    color: AppColors.primary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// `Year of study` picker of the Apply Form. The frame shows a dropdown; the
/// app reuses the sheet and Filter Chips (as AcademicStandingSheet does).
///
/// Pops the chosen year; `null` when the sheet is dismissed.
class YearOfStudySheet extends StatelessWidget {
  const YearOfStudySheet({super.key, this.selected});

  final int? selected;

  /// Same range as Edit profile's academic standing.
  static const int maxYear = 6;

  @override
  Widget build(BuildContext context) {
    return AppSheet(
      icon: Symbols.calendar_month_rounded,
      title: 'Year of study',
      subtitle: 'Which year are you in?',
      primaryLabel: 'Close',
      showCancel: false,
      onPrimary: () => Navigator.of(context).pop(),
      children: [
        Wrap(
          spacing: AppSpacing.s8,
          runSpacing: AppSpacing.s4,
          children: [
            for (var year = 1; year <= maxYear; year++)
              SheetChip(
                label: 'Year $year',
                selected: selected == year,
                onSelected: () => Navigator.of(context).pop(year),
              ),
          ],
        ),
      ],
    );
  }
}
