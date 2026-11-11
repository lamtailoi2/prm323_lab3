import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/router.dart';
import '../../../core/state/view_state.dart';
import '../../../core/utils/distinct_listings.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/company_logo.dart';
import '../../../core/widgets/detail_section_card.dart';
import '../../../core/widgets/state_view.dart';
import '../../../models/internship.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_sizes.dart';
import '../../../theme/app_spacing.dart';
import '../../saved/viewmodels/saved_providers.dart';
import '../../saved/viewmodels/saved_viewmodel.dart';
import '../viewmodels/internship_detail_viewmodel.dart';
import '../widgets/detail_bottom_bar.dart';
import '../widgets/detail_parts.dart';
import '../widgets/detail_skeleton.dart';
import '../widgets/job_hero_card.dart';
import '../widgets/skill_match_card.dart';

/// Internship Detail (Lab 2 screen 4, Flow 1 end / Flow 2 start).
///
/// Opened from a card on Home, Search or Saved at
/// `/{tab}/internships/:jobKey`; [source] is that tab.
class InternshipDetailScreen extends ConsumerWidget {
  const InternshipDetailScreen({
    super.key,
    required this.internshipKey,
    required this.source,
  });

  final String internshipKey;
  final String source;

  static const String notAvailableTitle =
      'This internship is no longer available';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = (internshipKey: internshipKey, source: source);
    final state = ref.watch(internshipDetailViewModelProvider(args));
    final savedJobs = ref.watch(savedJobsProvider);
    // Keeps the save ViewModel alive while a write from this screen runs.
    ref.watch(savedViewModelProvider);

    return Scaffold(
      appBar: AppTopBar.back(
        title: 'Internship details',
        actions: [
          IconButton(
            icon: const Icon(Symbols.notifications_rounded),
            tooltip: 'Notifications',
            onPressed: () => context.push(AppRoutes.notificationCenter),
          ),
        ],
      ),
      body: switch (state) {
        ViewLoading() => const DetailSkeleton(),
        ViewEmpty() => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: StateView.empty(
              icon: Symbols.work_off_rounded,
              title: notAvailableTitle,
              message: 'It may have closed or been removed from Google Jobs.',
              actionLabel: 'Back',
              onAction: () => Navigator.maybePop(context),
            ),
          ),
        ),
        ViewError(:final error) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: StateView.error(
              message: error.message,
              onRetry: () => ref
                  .read(internshipDetailViewModelProvider(args).notifier)
                  .retry(),
            ),
          ),
        ),
        ViewData(:final data) => _DetailContent(detail: data),
      },
      bottomNavigationBar: switch (state) {
        ViewData(:final data) => DetailBottomBar(
          isSaved: _isSaved(savedJobs, data.internship),
          onToggleSave: () => unawaited(
            _toggleSave(
              context,
              ref,
              data.internship,
              wasSaved: _isSaved(savedJobs, data.internship),
            ),
          ),
          isApplied: data.application != null,
          onPrimary: switch (data.application) {
            // Flow 3c: `View application` opens the tracked application
            // (DC-24 item 11).
            final application? => () => context.push(
              AppRoutes.applicationDetail(application.jobKey),
            ),
            // Flow 1 pre-submit; push keeps this Detail underneath.
            null => () => context.push(
              AppRoutes.applyForm('/$source', data.internship.key),
            ),
          },
        ),
        _ => null,
      },
    );
  }

  /// Saved when any synced copy of this job is in Saved, so a detail opened
  /// from another copy than the one saved still shows `Saved` (CR-07).
  static bool _isSaved(Set<String> savedJobs, Internship internship) =>
      savedJobs.contains(jobIdentity(internship.title, internship.companyName));

  Future<void> _toggleSave(
    BuildContext context,
    WidgetRef ref,
    Internship internship, {
    required bool wasSaved,
  }) async {
    final result = await ref
        .read(savedViewModelProvider.notifier)
        .toggleAndReport(internship, source: 'detail');
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    // The SnackBar lives on the root messenger and can outlive this Detail
    // (CR-01): its actions must not use a closed screen's context or ref.
    final router = GoRouter.of(context);
    if (result.error case final error?) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(error.message),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () {
              if (!context.mounted) return;
              unawaited(
                _toggleSave(context, ref, internship, wasSaved: wasSaved),
              );
            },
          ),
        ),
      );
    } else if (result.done && !wasSaved) {
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Saved to your list'),
          // An action makes a SnackBar stay by default; this one hides after
          // the theme duration (design-system: 4 s even with an action).
          persist: false,
          action: SnackBarAction(
            label: 'View saved',
            onPressed: () => router.go(AppRoutes.saved),
          ),
        ),
      );
    }
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.detail});

  final InternshipDetail detail;

  @override
  Widget build(BuildContext context) {
    final internship = detail.internship;
    final match = detail.skillMatch;
    final description = internship.description;
    final requirements = internship.highlightItems('qualification');
    final benefits = internship.highlightItems('benefit');

    final application = detail.application;

    final sections = <Widget>[
      // Header, key facts and the applied state in one card (DC-31).
      JobHeroCard(internship: internship, application: application),
      if (match != null)
        SkillMatchCard(
          match: match,
          // Skills are edited on Profile (Edit skills sheet).
          onAddSkills: () => context.go(AppRoutes.profile),
        ),
      if (description != null)
        DetailSectionCard(
          icon: Symbols.work_rounded,
          title: 'About the role',
          spacing: AppSpacing.s8,
          children: [DetailExpandableText(description)],
        ),
      // Google Jobs has no "nice to have" split, so the Qualifications
      // highlight is one list (DC-24).
      if (requirements.isNotEmpty)
        DetailSectionCard(
          icon: Symbols.checklist_rounded,
          title: 'Requirements',
          children: [for (final item in requirements) DetailBulletItem(item)],
        ),
      if (benefits.isNotEmpty)
        DetailSectionCard(
          icon: Symbols.redeem_rounded,
          title: 'What you will get',
          children: [DetailBenefitList(benefits)],
        ),
      _CompanySection(internship: internship),
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.s16),
      itemCount: sections.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.section),
      itemBuilder: (context, index) => sections[index],
    );
  }
}

/// "About the company" without size, description, map or address: Google
/// Jobs does not provide them (DC-10).
class _CompanySection extends StatelessWidget {
  const _CompanySection({required this.internship});

  final Internship internship;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final location = internship.location;
    return DetailSectionCard(
      icon: Symbols.apartment_rounded,
      title: 'About the company',
      children: [
        Row(
          children: [
            CompanyLogo(
              companyName: internship.companyName,
              url: internship.logoUrl,
              size: AppSizes.companyLogo,
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(internship.companyName, style: textTheme.titleMedium),
                  if (location != null)
                    Text(
                      location,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
