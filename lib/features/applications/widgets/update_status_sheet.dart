import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/state/view_state.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../models/internship_application.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_spacing.dart';
import '../viewmodels/application_detail_viewmodel.dart';
import 'application_status_badge.dart';

/// `Update status` picker of Application Detail.
///
/// Internly only records that an application was sent; the student reports
/// every later stage themselves (G-25 #6), so this is the writer for
/// `under_review`, `interview`, `accepted` and `rejected`.
/// `withdrawn` is missing on purpose: Withdraw / Undo own that transition
/// because it also stamps `withdrawnAt` and keeps `previousStatus`.
class UpdateStatusSheet extends ConsumerStatefulWidget {
  const UpdateStatusSheet({super.key, required this.internshipKey});

  final String internshipKey;

  @override
  ConsumerState<UpdateStatusSheet> createState() => _UpdateStatusSheetState();
}

class _UpdateStatusSheetState extends ConsumerState<UpdateStatusSheet> {
  /// The stage the student picked; starts as the stored one.
  late ApplicationStatus _selected;

  @override
  void initState() {
    super.initState();
    _selected =
        _currentStatus(
          ref.read(applicationDetailViewModelProvider(widget.internshipKey)),
        ) ??
        ApplicationStatus.submitted;
  }

  @override
  Widget build(BuildContext context) {
    final provider = applicationDetailViewModelProvider(widget.internshipKey);
    final state = ref.watch(provider);
    final viewModel = ref.read(provider.notifier);
    final textTheme = Theme.of(context).textTheme;
    final current = _currentStatus(state);
    final unchanged = _selected == current;

    return AppSheet(
      icon: Symbols.timeline_rounded,
      title: 'Update status',
      subtitle:
          'Set the stage your application reached. Internly only tracks it; '
          'the company is not notified.',
      primaryLabel: 'Save status',
      isLoading: state.statusAction.isLoading,
      error: switch (state.statusAction) {
        AsyncError(:final error) when error is AppException => error,
        _ => null,
      },
      onPrimary: unchanged
          ? null
          : () async {
              if (await viewModel.updateStatus(_selected) && context.mounted) {
                Navigator.of(context).pop();
              }
            },
      children: [
        Semantics(
          header: true,
          child: Text('Stage', style: textTheme.labelLarge),
        ),
        const SizedBox(height: AppSpacing.s8),
        for (final status in ApplicationStatus.trackable)
          _StatusOption(
            status: status,
            selected: _selected == status,
            onSelected: () => setState(() => _selected = status),
          ),
      ],
    );
  }

  /// The status the live document has, so the sheet disables `Save status`
  /// when nothing changed and follows a write from another device.
  ApplicationStatus? _currentStatus(ApplicationDetailState state) {
    final detail = state.detail;
    if (detail is! ViewData<ApplicationDetail>) return null;
    return detail.data.application.status;
  }
}

/// One stage row: the shared status badge (label + icon, never color alone)
/// with a radio marker on the selected row.
class _StatusOption extends StatelessWidget {
  const _StatusOption({
    required this.status,
    required this.selected,
    required this.onSelected,
  });

  final ApplicationStatus status;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      selected: selected,
      button: true,
      label: status.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onSelected,
        borderRadius: AppRadii.mediumAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
          child: Row(
            children: [
              Icon(
                selected
                    ? Symbols.radio_button_checked_rounded
                    : Symbols.radio_button_unchecked_rounded,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.s12),
              ApplicationStatusBadge(status: status),
            ],
          ),
        ),
      ),
    );
  }
}
