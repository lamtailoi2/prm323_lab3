import 'package:flutter/material.dart';

import '../../../core/widgets/skeleton.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_sizes.dart';
import '../../../theme/app_spacing.dart';

/// Loading state of Internship Detail (Figma "Detail · Loading"): white
/// cards of skeleton blocks in the shape of the real sections.
class DetailSkeleton extends StatelessWidget {
  const DetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading internship',
      child: ExcludeSemantics(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.s16),
          physics: const NeverScrollableScrollPhysics(),
          children: const [
            _SkeletonCard(
              children: [
                SkeletonBox(
                  width: AppSizes.companyLogoLarge,
                  height: AppSizes.companyLogoLarge,
                  borderRadius: AppRadii.mediumAll,
                ),
                SkeletonBox(height: 24),
                FractionallySizedBox(
                  widthFactor: 0.6,
                  child: SkeletonBox(height: 16),
                ),
                Row(
                  children: [
                    Expanded(child: SkeletonBox(height: 64)),
                    SizedBox(width: AppSpacing.s8),
                    Expanded(child: SkeletonBox(height: 64)),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: SkeletonBox(height: 64)),
                    SizedBox(width: AppSpacing.s8),
                    Expanded(child: SkeletonBox(height: 64)),
                  ],
                ),
              ],
            ),
            SizedBox(height: AppSpacing.s16),
            _SkeletonCard(
              children: [
                FractionallySizedBox(
                  widthFactor: 0.4,
                  child: SkeletonBox(height: 20),
                ),
                SkeletonBox(height: 16),
                SkeletonBox(height: 16),
                FractionallySizedBox(
                  widthFactor: 0.7,
                  child: SkeletonBox(height: 16),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.s16),
            _SkeletonCard(
              children: [
                FractionallySizedBox(
                  widthFactor: 0.4,
                  child: SkeletonBox(height: 20),
                ),
                SkeletonBox(height: 16),
                FractionallySizedBox(
                  widthFactor: 0.8,
                  child: SkeletonBox(height: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.mediumAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.s12),
            children[i],
          ],
        ],
      ),
    );
  }
}
