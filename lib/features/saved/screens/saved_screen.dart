import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/router.dart';
import '../../../core/utils/distinct_listings.dart';
import '../../../core/widgets/internship_card.dart';
import '../../../core/widgets/main_tab_app_bar.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/state_view.dart';
import '../../../models/internship.dart';
import '../../../services/auth_service.dart';
import '../../../theme/app_sizes.dart';
import '../../../theme/app_spacing.dart';
import '../../applications/viewmodels/applied_providers.dart';
import '../viewmodels/saved_providers.dart';
import '../viewmodels/saved_viewmodel.dart';

enum _SavedFilter {
  all('All IT'),
  hybrid('Hybrid'),
  remote('Remote'),
  engineering('Engineering');

  const _SavedFilter(this.label);
  final String label;
}

class SavedScreen extends ConsumerStatefulWidget {
  const SavedScreen({super.key});

  @override
  ConsumerState<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends ConsumerState<SavedScreen> {
  _SavedFilter _filter = _SavedFilter.all;

  /// Enough placeholders to fill the first screen at 360 dp without making
  /// the loading state taller than the content it stands in for.
  static const int _skeletonCount = 3;

  List<Internship> _filterInternships(List<Internship> internships) {
    final filtered = internships.where((internship) {
      switch (_filter) {
        case _SavedFilter.all:
          return true;
        case _SavedFilter.hybrid:
          return internship.workMode == WorkMode.hybrid;
        case _SavedFilter.remote:
          return internship.workMode == WorkMode.remote;
        case _SavedFilter.engineering:
          final role = internship.role?.name.toLowerCase() ?? '';
          final title = internship.title.toLowerCase();
          return role.contains('engineer') ||
              title.contains('engineer') ||
              title.contains('engineering');
      }
    }).toList();

    // Newest saved items first, when the saved timestamp is available.
    // The service currently does not expose savedAt, so use listing recency
    // as a stable fallback until Saved metadata is included in the model.
    filtered.sort((a, b) {
      final aDate = a.postedAt;
      final bDate = b.postedAt;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    });

    return filtered;
  }

  /// The work-mode shortcuts above the list.
  ///
  /// They are static, so they stay visible and tappable while the first
  /// snapshot is still loading; the selection applies to the list that follows.
  Widget _filterChips() {
    return SizedBox(
      height: 60,
      child: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal,
        ),
        scrollDirection: Axis.horizontal,
        children: [
          for (final filter in _SavedFilter.values)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.s8),
              child: ChoiceChip(
                label: Text(filter.label),
                selected: _filter == filter,
                onSelected: (_) {
                  setState(() => _filter = filter);
                },
              ),
            ),
        ],
      ),
    );
  }

  /// First snapshot: card-shaped skeletons (Figma "Loading"), so the list
  /// keeps its shape instead of showing a spinner or a blank screen.
  Widget _loadingBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _filterChips(),
        Expanded(
          child: Semantics(
            container: true,
            liveRegion: true,
            label: 'Loading saved internships',
            child: ExcludeSemantics(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  0,
                  AppSpacing.screenHorizontal,
                  AppSpacing.s24,
                ),
                itemCount: _skeletonCount,
                itemBuilder: (context, index) => const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.s12),
                  child: InternshipCardSkeleton(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final savedAsync = ref.watch(savedInternshipsProvider);
    final appliedJobs =
        ref.watch(appliedJobsProvider).asData?.value ?? const <String>{};

    return Scaffold(
      appBar: MainTabAppBar(
        onNotifications: () => context.push(AppRoutes.notificationCenter),
        title: 'Saved',
        user: ref.watch(authStateChangesProvider).value,
        onProfile: () => context.go(AppRoutes.profile),
      ),
      body: savedAsync.when(
        loading: _loadingBody,
        error: (_, _) => StateView.error(
          message: 'We couldn’t load your saved internships. Check your connection and try again.',
          onRetry: () => ref.invalidate(savedInternshipsProvider),
        ),
        data: (internships) {
          if (internships.isEmpty) {
            return StateView.empty(
              icon: Symbols.bookmark_border_rounded,
              title: 'No saved internships yet',
              message: 'Save opportunities to compare them and apply when you are ready.',
              actionLabel: 'Search internships',
              // Flow 2e.2: an empty list sends the student to Search.
              onAction: () => context.go(AppRoutes.search),
            );
          }

          final filtered = _filterInternships(internships);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _filterChips(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Text(
                      '${filtered.length} saved',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const Spacer(),
                    const Icon(Symbols.schedule_rounded, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      'Recent',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                ),
              ),
              if (filtered.isEmpty)
                const Expanded(
                  child: StateView.empty(
                    icon: Symbols.search_off_rounded,
                    title: 'No matching internships',
                    message:
                        'Try another filter to see your saved internships.',
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final internship = filtered[index];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InternshipCard(
                          title: internship.title,
                          companyName: internship.companyName,
                          location: internship.location,
                          workMode: internship.workMode?.label,
                          logoUrl: internship.logoUrl,
                          tags: internship.skills,
                          allowanceText:
                              internship.salary ??
                              InternshipCard.allowanceNotDisclosed,
                          postedText: internship.postedText,
                          isSaved: true,
                          isApplied: appliedJobs.contains(
                            jobIdentity(
                              internship.title,
                              internship.companyName,
                            ),
                          ),
                          onTap: () => context.go(
                            AppRoutes.internshipDetail(
                              AppRoutes.saved,
                              internship.key,
                            ),
                          ),
                          onSaveToggle: () => _removeSaved(internship),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Removes [internship] and offers Undo until the Snackbar hides (Flow 2e.1).
  ///
  /// The write runs through [savedViewModelProvider] (Views never call a
  /// service), and the card leaves the list through `savedInternshipsProvider`
  /// as soon as Firestore confirms the delete.
  Future<void> _removeSaved(Internship internship) async {
    final viewModel = ref.read(savedViewModelProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);

    final result = await viewModel.remove(internship);
    if (!mounted) return;

    if (result.error case final error?) {
      _showError(
        messenger,
        error.message,
        onRetry: () => _removeSaved(internship),
      );
      return;
    }
    // Another saved write was still running: the tap is ignored, no message.
    if (!result.done) return;

    _showRemoved(messenger, internship);
  }

  /// Puts the internship back after Undo; the stream re-adds the card.
  Future<void> _undoRemove(Internship internship) async {
    final viewModel = ref.read(savedViewModelProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);

    final result = await viewModel.restore(internship);
    if (!mounted) return;

    if (result.error case final error?) {
      _showError(messenger, error.message);
    }
  }

  void _showRemoved(ScaffoldMessengerState messenger, Internship internship) {
    final colors = Theme.of(context).colorScheme;

    // Replacing the current SnackBar keeps one Undo target when the student
    // unsaves several internships in a row.
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          // Flutter keeps a SnackBar with an action on screen until it is
          // used; Undo must only be offered while it is visible, so let it
          // time out like every other SnackBar (Flow 2e.1).
          persist: false,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s16,
            vertical: AppSpacing.s12,
          ),
          content: Row(
            children: [
              ExcludeSemantics(
                child: Icon(
                  Symbols.check_circle_rounded,
                  size: AppSizes.iconSmall,
                  color: colors.onInverseSurface,
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              const Expanded(child: Text('Removed from Saved')),
            ],
          ),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => _undoRemove(internship),
          ),
        ),
      );
  }

  void _showError(
    ScaffoldMessengerState messenger,
    String message, {
    VoidCallback? onRetry,
  }) {
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          action: onRetry == null
              ? null
              : SnackBarAction(label: 'Retry', onPressed: onRetry),
        ),
      );
  }
}
