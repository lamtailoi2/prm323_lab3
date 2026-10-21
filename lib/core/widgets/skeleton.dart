import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';

/// A `surfaceVariant` placeholder block (Figma page 05 "Loading / Skeleton").
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = AppRadii.smallAll,
  });

  final double? width;
  final double height;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: borderRadius,
      ),
    );
  }
}

/// Card-shaped skeleton matching the Internship Card layout. Use it for list
/// loading states instead of a spinner or a blank screen.
class InternshipCardSkeleton extends StatelessWidget {
  const InternshipCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const ExcludeSemantics(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(height: 18),
                        SizedBox(height: AppSpacing.s8),
                        FractionallySizedBox(
                          widthFactor: 0.5,
                          child: SkeletonBox(height: 14),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: AppSpacing.s16),
                  SkeletonBox(width: 32, height: 32),
                ],
              ),
              SizedBox(height: AppSpacing.s16),
              FractionallySizedBox(
                widthFactor: 0.7,
                child: SkeletonBox(height: 14),
              ),
              SizedBox(height: AppSpacing.s12),
              Row(
                children: [
                  SkeletonBox(width: 56, height: 24),
                  SizedBox(width: AppSpacing.s8),
                  SkeletonBox(width: 56, height: 24),
                ],
              ),
              SizedBox(height: AppSpacing.s12),
              FractionallySizedBox(
                widthFactor: 0.4,
                child: SkeletonBox(height: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
