import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';

/// Square company logo with the initials as fallback (Figma "Logo").
///
/// Shared by Internship Detail, the Apply Form, Application Review, Application
/// Success and Application Detail (design-system.md › components).
class CompanyLogo extends StatelessWidget {
  const CompanyLogo({
    super.key,
    required this.companyName,
    required this.size,
    this.url,
  });

  final String companyName;
  final double size;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: AppColors.primaryContainer,
      child: Text(
        initialsOf(companyName),
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(color: AppColors.primary),
      ),
    );
    final link = url;
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: AppRadii.mediumAll,
        child: link == null
            ? fallback
            : Image.network(
                link,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => fallback,
              ),
      ),
    );
  }

  /// First letters of the first two words, e.g. "FPT Software" → "FS".
  static String initialsOf(String name) {
    final words = name
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(2);
    final initials = words.map((word) => word.characters.first).join();
    return initials.toUpperCase();
  }
}
