import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/state/view_state.dart';
import '../../../models/internship.dart';
import '../../../models/internship_application.dart';
import '../../../services/analytics_service.dart';
import '../../../services/application_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/external_link_service.dart';
import '../../../services/internship_service.dart';

/// `DateTime.now`, injectable so the 24-hour undo window is testable.
final nowProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// One application plus the listing it came from, while that listing is
/// still in the shared pool.
@immutable
class ApplicationDetail {
  const ApplicationDetail({required this.application, this.listing});

  final InternshipApplication application;

  /// `null` once the listing expired from `/internships`; the snapshot in
  /// [application] still shows position and company.
  final Internship? listing;
}

@immutable
class ApplicationDetailState {
  const ApplicationDetailState({
    this.detail = const ViewLoading(),
    this.action = const AsyncData(null),
    this.canUndoWithdrawal = false,
    this.undoDeadline,
  });

  final ViewState<ApplicationDetail> detail;

  /// Withdraw / undo write in flight or failed.
  final AsyncValue<void> action;

  /// The withdrawal happened less than 24 hours ago.
  final bool canUndoWithdrawal;

  /// When the undo window closes, for the caption on the button.
  final DateTime? undoDeadline;

  ApplicationDetailState copyWith({
    ViewState<ApplicationDetail>? detail,
    AsyncValue<void>? action,
    bool? canUndoWithdrawal,
    Object? undoDeadline = _keep,
  }) {
    return ApplicationDetailState(
      detail: detail ?? this.detail,
      action: action ?? this.action,
      canUndoWithdrawal: canUndoWithdrawal ?? this.canUndoWithdrawal,
      undoDeadline: identical(undoDeadline, _keep)
          ? this.undoDeadline
          : undoDeadline as DateTime?,
    );
  }

  static const Object _keep = Object();
}

final applicationDetailViewModelProvider = NotifierProvider.autoDispose
    .family<ApplicationDetailViewModel, ApplicationDetailState, String>(
      ApplicationDetailViewModel.new,
    );

/// Application Detail (Flow 3c): one `users/{uid}/applications/{jobKey}`
/// document, its listing while it is still in the pool, and the withdraw /
/// undo writes (Flow 3d).
class ApplicationDetailViewModel extends Notifier<ApplicationDetailState> {
  ApplicationDetailViewModel(this.internshipKey);

  /// How long a withdrawal can be taken back (Application Detail frame).
  static const Duration undoWindow = Duration(hours: 24);

  final String internshipKey;

  StreamSubscription<List<InternshipApplication>>? _applicationsSubscription;
  StreamSubscription<Internship?>? _listingSubscription;

  List<InternshipApplication> _applications = const [];
  Internship? _listing;
  bool _viewLogged = false;

  @override
  ApplicationDetailState build() {
    final service = ref.watch(applicationServiceProvider);
    final listings = ref.watch(internshipServiceProvider);
    // User-scoped (AGENTS.md rule 11).
    ref.watch(currentUserIdProvider);
    _applications = const [];
    _listing = null;
    _viewLogged = false;
    ref.onDispose(() {
      unawaited(_applicationsSubscription?.cancel());
      unawaited(_listingSubscription?.cancel());
    });
    _subscribeApplications(service);
    _subscribeListing(listings);
    return const ApplicationDetailState();
  }

  /// `Retry` after the documents or the listing failed to load.
  void retry() {
    if (state.detail.isLoading) return;
    state = state.copyWith(detail: const ViewLoading());
    _subscribeApplications(ref.read(applicationServiceProvider));
    _subscribeListing(ref.read(internshipServiceProvider));
  }

  /// Withdraws the application. Returns `true` once the write is accepted;
  /// the status then follows from the live document.
  Future<bool> withdraw() async {
    final application = _current;
    if (application == null ||
        state.action.isLoading ||
        !application.status.canWithdraw) {
      return false;
    }
    final service = ref.read(applicationServiceProvider);
    state = state.copyWith(action: const AsyncLoading());
    try {
      await service.withdraw(application.jobKey, previous: application.status);
      if (ref.mounted) state = state.copyWith(action: const AsyncData(null));
      return true;
    } on AppException catch (error, stack) {
      if (ref.mounted) state = state.copyWith(action: AsyncError(error, stack));
      return false;
    }
  }

  /// Takes the withdrawal back, while the 24-hour window lasts.
  Future<bool> undoWithdrawal() async {
    final application = _current;
    if (application == null ||
        state.action.isLoading ||
        !state.canUndoWithdrawal) {
      return false;
    }
    final service = ref.read(applicationServiceProvider);
    state = state.copyWith(action: const AsyncLoading());
    try {
      await service.undoWithdrawal(application.jobKey);
      if (ref.mounted) state = state.copyWith(action: const AsyncData(null));
      return true;
    } on AppException catch (error, stack) {
      if (ref.mounted) state = state.copyWith(action: AsyncError(error, stack));
      return false;
    }
  }

  /// Opens the submitted CV in the device's viewer. Returns the failure so the
  /// View can show it; `null` means the viewer opened.
  Future<AppException?> previewCv() async {
    final url = _current?.cvUrl;
    if (url == null) {
      return const AppException(
        AppErrorKind.unknown,
        'This application has no submitted CV.',
      );
    }
    try {
      await ref.read(externalLinkServiceProvider).open(Uri.parse(url));
      return null;
    } on AppException catch (error) {
      return error;
    }
  }

  InternshipApplication? get _current {
    for (final application in _applications) {
      if (application.jobKey == internshipKey) return application;
    }
    return null;
  }

  void _subscribeApplications(ApplicationService service) {
    unawaited(_applicationsSubscription?.cancel());
    _applicationsSubscription = service.watchApplications().listen(
      (applications) {
        if (!ref.mounted) return;
        _applications = applications;
        _emit();
      },
      onError: (Object error, StackTrace _) {
        if (!ref.mounted) return;
        state = state.copyWith(
          detail: ViewError(
            error is AppException
                ? error
                : AppException(
                    AppErrorKind.unknown,
                    'We could not load this application. Try again in a '
                    'moment.',
                    cause: error,
                  ),
          ),
        );
      },
    );
  }

  void _subscribeListing(InternshipService service) {
    unawaited(_listingSubscription?.cancel());
    _listingSubscription = service.watchByKey(internshipKey).listen(
      (listing) {
        if (!ref.mounted) return;
        _listing = listing;
        if (state.detail is ViewData<ApplicationDetail>) _emit();
      },
      // The snapshot in the document is enough; a missing listing never
      // blocks the screen.
      onError: (Object _, StackTrace _) {},
    );
  }

  void _emit() {
    final application = _current;
    if (application == null) {
      state = state.copyWith(detail: const ViewEmpty());
      return;
    }

    final withdrawnAt = application.withdrawnAt;
    final deadline = withdrawnAt?.add(undoWindow);
    final canUndo =
        application.status == ApplicationStatus.withdrawn &&
        deadline != null &&
        ref.read(nowProvider)().isBefore(deadline);

    state = state.copyWith(
      detail: ViewData(
        ApplicationDetail(application: application, listing: _listing),
      ),
      canUndoWithdrawal: canUndo,
      undoDeadline: deadline,
    );
    _logView(application);
  }

  /// Logs `view_application` once per opened screen
  /// (docs/analytics-plan.md row 11).
  void _logView(InternshipApplication application) {
    if (_viewLogged) return;
    _viewLogged = true;
    unawaited(
      ref.read(analyticsServiceProvider).logEvent('view_application', {
        'internship_id': application.jobKey,
        'status': application.status.storageValue,
      }),
    );
  }
}
