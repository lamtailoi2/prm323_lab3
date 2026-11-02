import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../models/user_profile.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_sizes.dart';
import '../../theme/app_spacing.dart';
import '../errors/app_exception.dart';
import '../utils/display_format.dart';
import 'app_button.dart';
import 'app_sheet.dart';
import 'cv_file_tile.dart';
import 'status_badge.dart';

/// Upload / Update CV sheet (Lab 2 `profile-cv-upload.png`, Figma "CV Upload
/// Modal"): the current CV with its badge, a picker area, the file selected
/// for upload with its progress, and the primary `Update CV` (or `Upload CV`
/// when there is no CV yet). Profile and the Apply Form show the same sheet;
/// each passes its own copy, state and actions.
class CvUploadSheet extends StatelessWidget {
  const CvUploadSheet({
    super.key,
    required this.subtitle,
    required this.current,
    required this.currentBadge,
    required this.onChoose,
    required this.onRemove,
    required this.onPrimary,
    this.selectedName,
    this.selectedSizeBytes,
    this.progress,
    this.error,
  });

  final String subtitle;

  /// The CV being replaced; `null` for a first upload.
  final CvFile? current;

  /// Badge next to "Current active CV", e.g. `Active default`.
  final String currentBadge;

  /// The PDF chosen for upload, until it is stored or removed.
  final String? selectedName;
  final int? selectedSizeBytes;

  /// Upload progress from 0 to 1; non-null only while uploading.
  final double? progress;

  /// Why the last pick or upload failed, shown above the primary action.
  final AppException? error;
  final VoidCallback onChoose;
  final VoidCallback onRemove;

  /// Uploads the selected file; enabled once a file is selected.
  final VoidCallback onPrimary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final replacing = current != null;

    return AppSheet(
      icon: Symbols.upload_file_rounded,
      title: replacing ? 'Update CV' : 'Upload CV',
      subtitle: subtitle,
      primaryLabel: replacing ? 'Update CV' : 'Upload CV',
      primaryIcon: Symbols.sync_rounded,
      isLoading: progress != null,
      error: error,
      onPrimary: selectedName == null ? null : onPrimary,
      children: [
        if (current case final cv?) ...[
          _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PanelLabel(
                  icon: Symbols.history_rounded,
                  text: 'Current active CV',
                  trailing: StatusBadge(
                    label: currentBadge,
                    icon: Symbols.check_circle_rounded,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: AppSpacing.s12),
                CvFileTile(
                  fileName: cv.fileName,
                  details:
                      '${formatFileSize(cv.sizeBytes)} · '
                      'Uploaded ${formatShortDate(cv.uploadedAt)}',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.section),
        ],
        Semantics(
          header: true,
          child: Text(
            replacing ? 'Select new CV file' : 'Select a CV file',
            style: textTheme.labelLarge,
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        _PickerArea(
          replacing: replacing,
          onChoose: progress != null ? null : onChoose,
        ),
        if (selectedName case final name?) ...[
          const SizedBox(height: AppSpacing.s16),
          _Panel(
            highlighted: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PanelLabel(
                  icon: Symbols.task_alt_rounded,
                  text: 'Selected for update',
                  trailing: AppButton(
                    label: 'Remove',
                    icon: Symbols.delete_rounded,
                    variant: AppButtonVariant.text,
                    onPressed: progress != null ? null : onRemove,
                  ),
                ),
                CvFileTile(
                  fileName: name,
                  details: '${formatFileSize(selectedSizeBytes ?? 0)} · PDF',
                ),
                if (progress case final progress?) ...[
                  const SizedBox(height: AppSpacing.s12),
                  Semantics(
                    label: 'Uploading CV',
                    value: '${(progress * 100).round()}%',
                    child: LinearProgressIndicator(value: progress),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  ExcludeSemantics(
                    child: Text(
                      'Uploading… ${(progress * 100).round()}%',
                      style: textTheme.bodyMedium,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Where the student starts choosing a file. A solid border stands in for
/// the dashed "Upload Dropzone" outline of the Lab 2 frame.
class _PickerArea extends StatelessWidget {
  const _PickerArea({required this.replacing, required this.onChoose});

  final bool replacing;
  final VoidCallback? onChoose;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return _Panel(
      child: Column(
        children: [
          const ExcludeSemantics(
            child: FileTileIcon(icon: Symbols.cloud_upload_rounded),
          ),
          const SizedBox(height: AppSpacing.s12),
          Text(
            replacing ? 'Choose a PDF file to replace' : 'Choose a PDF file',
            style: textTheme.labelLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            'Browse phone storage or Google Drive',
            style: textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.s12),
          AppButton(
            label: 'Choose file',
            icon: Symbols.folder_open_rounded,
            variant: AppButtonVariant.secondary,
            onPressed: onChoose,
          ),
          const SizedBox(height: AppSpacing.s8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Symbols.verified_user_rounded,
                size: AppSizes.iconSmall,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.s4),
              Flexible(
                child: Text(
                  'Accepted format: PDF, up to 10 MB',
                  style: textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.highlighted = false});

  final Widget child;

  /// Primary outline for the file about to be uploaded.
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: highlighted ? AppColors.surface : AppColors.background,
        borderRadius: AppRadii.mediumAll,
        border: Border.all(
          color: highlighted ? AppColors.primary : AppColors.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: child,
      ),
    );
  }
}

class _PanelLabel extends StatelessWidget {
  const _PanelLabel({
    required this.icon,
    required this.text,
    required this.trailing,
  });

  final IconData icon;
  final String text;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: AppSizes.iconSmall, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.s8),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.labelLarge),
        ),
        trailing,
      ],
    );
  }
}
