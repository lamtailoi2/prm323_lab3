import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/state/view_state.dart';
import '../../../models/internship_application.dart';
import '../../../services/application_service.dart';
import '../../../services/auth_service.dart';

/// The applications to show, already filtered and counted.
@immutable
class MyApplicationsFeed {
  const MyApplicationsFeed({
    required this.visible,
    required this.total,
    required this.counts,
  });

  /// Applications matching the selected status, newest first.
  final List<InternshipApplication> visible;

  /// Applications in the whole list, whatever the filter shows.
  final int total;

  /// Applications per status, in [ApplicationStatus.values] order. Only
  /// statuses that occur are present, so no chip filters an empty list.
  final Map<ApplicationStatus, int> counts;
}

@immutable
class MyApplicationsState {
  const MyApplicationsState({
    this.selectedStatus,
    this.applications = const ViewLoading(),
  });

  /// Status chip in use; `null` is the `All` chip.
  final ApplicationStatus? selectedStatus;
  final ViewState<MyApplicationsFeed> applications;
}

final myApplicationsViewModelProvider =
    NotifierProvider.autoDispose<MyApplicationsViewModel, MyApplicationsState>(
      MyApplicationsViewModel.new,
    );

/// Live list of `users/{uid}/applications` with the status filter.
///
/// The filter is applied here, not in `build`, so the screen renders
/// [ViewData] only and holds no business logic (AGENTS.md MVVM rule).
class MyApplicationsViewModel extends Notifier<MyApplicationsState> {
  List<InternshipApplication> _all = const <InternshipApplication>[];
  StreamSubscription<List<InternshipApplication>>? _subscription;

  @override
  MyApplicationsState build() {
    // User-scoped (AGENTS.md rule 11): sign-out or an account switch rebuilds
    // this provider and cancels the previous listener.
    ref.watch(currentUserIdProvider);
    final service = ref.watch(applicationServiceProvider);
    _all = const <InternshipApplication>[];

    ref.onDispose(() => unawaited(_subscription?.cancel()));
    _subscribe(service);

    return const MyApplicationsState();
  }

  /// Selects a status chip; `null` selects `All`.
  void selectStatus(ApplicationStatus? status) {
    if (state.selectedStatus == status) return;
    state = MyApplicationsState(
      selectedStatus: status,
      applications: _feedState(status),
    );
  }

  /// Subscribes again after the error state, keeping the selected chip.
  Future<void> retry() async {
    if (state.applications.isLoading) return;
    final service = ref.read(applicationServiceProvider);

    state = MyApplicationsState(selectedStatus: state.selectedStatus);
    _subscribe(service);
  }

  void _subscribe(ApplicationService service) {
    unawaited(_subscription?.cancel());
    _subscription = service.watchApplications().listen(
      _onData,
      onError: _onError,
    );
  }

  void _onData(List<InternshipApplication> applications) {
    if (!ref.mounted) return;
    _all = _newestFirst(applications);

    var selected = state.selectedStatus;
    // A status that no longer occurs would leave no chip selected and an
    // empty list, so fall back to All.
    if (selected != null &&
        !_all.any((application) => application.status == selected)) {
      selected = null;
    }

    state = MyApplicationsState(
      selectedStatus: selected,
      applications: _feedState(selected),
    );
  }

  void _onError(Object error, StackTrace stack) {
    if (!ref.mounted) return;
    final appError = error is AppException
        ? error
        : AppException(
            AppErrorKind.unknown,
            'We could not load your applications. Try again in a moment.',
            cause: error,
          );

    state = MyApplicationsState(
      selectedStatus: state.selectedStatus,
      applications: ViewError(appError),
    );
  }

  ViewState<MyApplicationsFeed> _feedState(ApplicationStatus? selected) {
    if (_all.isEmpty) return const ViewEmpty();

    final totals = <ApplicationStatus, int>{};
    for (final application in _all) {
      totals.update(
        application.status,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    return ViewData(
      MyApplicationsFeed(
        visible: selected == null
            ? _all
            : List<InternshipApplication>.unmodifiable(
                _all.where((application) => application.status == selected),
              ),
        total: _all.length,
        counts: Map<ApplicationStatus, int>.unmodifiable({
          for (final status in ApplicationStatus.values)
            status: ?totals[status],
        }),
      ),
    );
  }

  static List<InternshipApplication> _newestFirst(
    List<InternshipApplication> applications,
  ) {
    final sorted = [...applications]
      ..sort((a, b) {
        final byDate = b.appliedAt.compareTo(a.appliedAt);
        return byDate != 0 ? byDate : a.title.compareTo(b.title);
      });
    return List<InternshipApplication>.unmodifiable(sorted);
  }
}
