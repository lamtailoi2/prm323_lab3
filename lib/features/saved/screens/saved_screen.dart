import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/internship_card.dart';
import '../../../core/widgets/state_view.dart';
import '../../../models/internship.dart';
import '../../../services/saved_internship_service.dart';
import 'saved_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final savedAsync = ref.watch(savedInternshipsProvider);

    return Scaffold(
      appBar: const AppTopBar.main(title: 'Saved Internships'),
      body: savedAsync.when(
        loading: () =>
            const StateView.loading(message: 'Loading saved internships...'),
        error: (_, _) => StateView.error(
          message: 'We couldn’t load your saved internships. Check your connection and try again.',
          onRetry: () => ref.invalidate(savedInternshipsProvider),
        ),
        data: (internships) {
          if (internships.isEmpty) {
            return StateView.empty(
              icon: Symbols.bookmark_border_rounded,
              title: 'No saved internships yet',
              message: 'Save internships you like to find them here.',
              actionLabel: 'Search internships',
              onAction: () => _openSearch(context),
            );
          }

          final filtered = _filterInternships(internships);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 60,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final filter in _SavedFilter.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
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
              ),
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

  Future<void> _removeSaved(Internship internship) async {
    final service = ref.read(savedInternshipServiceProvider);

    try {
      await service.remove(internship.key);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not remove this internship.'),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => _removeSaved(internship),
          ),
        ),
      );
    }
  }

  void _openSearch(BuildContext context) {
    // Replace with the project's named Search route if it differs.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Search internships is coming soon.')),
    );
  }
}
