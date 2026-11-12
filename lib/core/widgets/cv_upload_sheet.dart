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
    this.title,
    this.primaryLabel,
    this.library = const <CvFile>[],
    this.selectedPath,
    this.onSelectLibrary,
    this.selectedName,
    this.selectedSizeBytes,
    this.progress,
    this.error,
  });

  final String subtitle;

  /// Defaults to `Update CV` / `Upload CV`, as the Profile sheet did before
  /// the library existed. The library's add flow says `Add CV`.
  final String? title;
  final String? primaryLabel;

  /// The student's CV library, offered before the file picker so a CV that
  /// already exists is one tap away (G-33). Empty everywhere except the
  /// Apply Form sheet, which has a library to choose from.
  final List<CvFile> library;

  /// The `storagePath` of the CV currently used, so the list marks it.
  final String? selectedPath;

  /// `Choose` on a library entry. `null` hides the library part.
  final ValueChanged<CvFile>? onSelectLibrary;

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
    final library = this.library;
    final onSelectLibrary = this.onSelectLibrary;

    return AppSheet(
      icon: Symbols.upload_file_rounded,
      title: title ?? (replacing ? 'Update CV' : 'Upload CV'),
      subtitle: subtitle,
      primaryLabel: primaryLabel ?? (replacing ? 'Update CV' : 'Upload CV'),
      primaryIcon: Symbols.sync_rounded,
      isLoading: progress != null,
      error: error,
      onPrimary: selectedName == null ? null : onPrimary,
      children: [
        if (onSelectLibrary != null && library.isNotEmpty) ...[
          Semantics(
            header: true,
            child: Text('From your library', style: textTheme.labelLarge),
          ),
          const SizedBox(height: AppSpacing.s8),
          for (var i = 0; i < library.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.s12),
            _LibraryTile(
              cv: library[i],
              isSelected: library[i].storagePath == selectedPath,
              enabled: progress == null,
              onTap: () => onSelectLibrary(library[i]),
            ),
          ],
          const SizedBox(height: AppSpacing.section),
          Semantics(
            header: true,
            child: Text('Or upload a new CV', style: textTheme.labelLarge),
          ),
          const SizedBox(height: AppSpacing.s8),
        ],
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

/// One CV from the student's library, tappable to use it for this
/// application. The selected entry carries a check and a primary outline, so
/// the choice is never shown by colour alone.
class _LibraryTile extends StatelessWidget {
  const _LibraryTile({
    required this.cv,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
  });

  final CvFile cv;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: '${cv.displayName}, ${isSelected ? 'selected' : 'choose'}',
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: AppRadii.mediumAll,
        child: Container(
          constraints: const BoxConstraints(minHeight: AppSizes.tagLarge),
          padding: const EdgeInsets.all(AppSpacing.s12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: AppRadii.mediumAll,
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: CvFileTile(
            fileName: cv.displayName,
            details:
                '${formatFileSize(cv.sizeBytes)} · '
                'Uploaded ${formatShortDate(cv.uploadedAt)}',
            trailing: isSelected
                ? const Icon(
                    Symbols.check_circle_rounded,
                    color: AppColors.primary,
                    size: AppSizes.iconSmall,
                  )
                : const Icon(
                    Symbols.chevron_right_rounded,
                    color: AppColors.textSecondary,
                    size: AppSizes.iconSmall,
                  ),
          ),
        ),
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
