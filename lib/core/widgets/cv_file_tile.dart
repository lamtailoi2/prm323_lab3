import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_sizes.dart';
import '../../theme/app_spacing.dart';

/// A PDF file row: icon tile, file name, metadata line and an optional
/// badge and trailing action.
///
/// Lab 2 "CV File Card", shared by Profile and the Apply Form (CV / Resume
/// section); its Figma component spec is still missing (G-16).
class CvFileTile extends StatelessWidget {
  const CvFileTile({
    super.key,
    required this.fileName,
    required this.details,
    this.badge,
    this.trailing,
  });

  final String fileName;

  /// e.g. "Oct 14, 2024 · 420 KB".
  final String details;
  final Widget? badge;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ExcludeSemantics(child: FileTileIcon()),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: textTheme.labelLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  Text(details, style: textTheme.bodyMedium),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
        // Below the row, aligned with the text, so the badge keeps one line
        // next to a trailing action at 360 dp.
        if (badge case final badge?)
          Padding(
            padding: const EdgeInsets.only(
              left: AppSizes.fileTile + AppSpacing.s12,
              top: AppSpacing.s8,
            ),
            child: badge,
          ),
      ],
    );
  }
}

/// 40 dp rounded tile with a primary icon, as in the Profile CV card and the
/// sheet headers.
class FileTileIcon extends StatelessWidget {
  const FileTileIcon({super.key, this.icon = Symbols.picture_as_pdf_rounded});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: AppSizes.fileTile,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.primaryContainer,
          borderRadius: AppRadii.mediumAll,
        ),
        child: Icon(icon, size: AppSizes.iconSmall, color: AppColors.primary),
      ),
    );
  }
}
