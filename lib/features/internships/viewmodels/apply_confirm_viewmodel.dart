import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/state/view_state.dart';
import '../../../services/analytics_service.dart';
import '../../../services/application_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/external_link_service.dart';
import 'apply_form_viewmodel.dart';

/// Where the Confirm Application step is in the external-apply flow
/// (G-25 #6): the student finishes on the employer's website, then records
/// the application here.
enum ApplyConfirmPhase {
  /// Nothing sent yet: the primary action opens the employer website.
  ready,

  /// The external browser is opening; duplicate taps are ignored.
  redirecting,

  /// The employer website opened; waiting for the student to come back.
  awaitingReturn,

  /// `markSubmitted` is running.
  saving,

  /// The application document was written; the screen navigates away.
  saved,

  /// The employer website could not be opened; `Try again` re-opens it.
  redirectFailed,

  /// The Firestore write failed; `Retry` writes again.
  saveFailed,
}

@immutable
class ApplyConfirmState {
  const ApplyConfirmState({
    this.phase = ApplyConfirmPhase.ready,
    this.returned = false,
    this.error,
  });

  final ApplyConfirmPhase phase;

  /// The app resumed after the employer website opened, so the screen asks
  /// the student to confirm instead of telling them to finish first.
  final bool returned;

  /// The failure to show: a link that could not open, or a failed write.
  final AppException? error;

  bool get isSaving => phase == ApplyConfirmPhase.saving;
  bool get isSaved => phase == ApplyConfirmPhase.saved;

  /// Blocks repeated primary taps while a link opens or a write runs.
  bool get isBusy =>
      phase == ApplyConfirmPhase.redirecting ||
      phase == ApplyConfirmPhase.saving ||
      phase == ApplyConfirmPhase.saved;

  static const Object _keep = Object();

  ApplyConfirmState copyWith({
    ApplyConfirmPhase? phase,
    bool? returned,
    Object? error = _keep,
  }) {
    return ApplyConfirmState(
      phase: phase ?? this.phase,
      returned: returned ?? this.returned,
      error: identical(error, _keep) ? this.error : error as AppException?,
    );
  }
}

final applyConfirmViewModelProvider = NotifierProvider.autoDispose
    .family<ApplyConfirmViewModel, ApplyConfirmState, ApplyFormArgs>(
      ApplyConfirmViewModel.new,
    );

/// Confirm Application step: opens the employer's page and records the
/// application after the student confirms they submitted it.
class ApplyConfirmViewModel extends Notifier<ApplyConfirmState> {
  ApplyConfirmViewModel(this.args);

  final ApplyFormArgs args;

  /// The page opened last, so `Try again` and `Open the website again` do
  /// not depend on the widget rebuilding.
  Uri? _employerUri;

  @override
  ApplyConfirmState build() {
    // User-scoped (AGENTS.md rule 11): another account drops this state.
    ref.watch(currentUserIdProvider);
    return const ApplyConfirmState();
  }

  /// Opens the employer's application page in the device browser.
  Future<void> openEmployer(Uri uri) async {
    if (state.isBusy) return;
    final links = ref.read(externalLinkServiceProvider);

    _employerUri = uri;
    state = state.copyWith(phase: ApplyConfirmPhase.redirecting, error: null);
    try {
      await links.open(uri);
      if (!ref.mounted) return;
      state = state.copyWith(
        phase: ApplyConfirmPhase.awaitingReturn,
        returned: false,
      );
    } on AppException catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(
        phase: ApplyConfirmPhase.redirectFailed,
        error: error,
      );
    }
  }

  /// Opens a link that is not an application page (the Google Jobs share
  /// link when the employer shares no page); the flow does not advance.
  Future<void> openListing(Uri uri) async {
    final links = ref.read(externalLinkServiceProvider);
    try {
      await links.open(uri);
    } on AppException catch (error) {
      if (ref.mounted) state = state.copyWith(error: error);
    }
  }

  /// The app resumed: the student is back from the employer website.
  void onReturned() {
    if (state.phase != ApplyConfirmPhase.awaitingReturn || state.returned) {
      return;
    }
    state = state.copyWith(returned: true);
  }

  /// Opens the last employer page again.
  void reopen() {
    final uri = _employerUri;
    if (uri != null) unawaited(openEmployer(uri));
  }

  /// `I've submitted my application` / `Mark as applied`: records the
  /// application with status `submitted`.
  Future<bool> submit() async {
    if (state.isBusy) return false;

    final form = ref.read(applyFormViewModelProvider(args));
    final internship = switch (form.internship) {
      ViewData(:final data) => data,
      _ => null,
    };
    final cv = form.cv;
    if (internship == null || cv == null) return false;

    final service = ref.read(applicationServiceProvider);
    final analytics = ref.read(analyticsServiceProvider);
    final startedAt = form.startedAt;

    state = state.copyWith(phase: ApplyConfirmPhase.saving, error: null);
    try {
      await service.markSubmitted(
        jobKey: internship.key,
        title: internship.title,
        companyName: internship.companyName,
      );
      await analytics.logEvent('application_create', <String, Object>{
        'internship_id': internship.key,
        'cv_source': cv.source.name,
        if (startedAt != null)
          'duration_sec': DateTime.now().difference(startedAt).inSeconds,
      });
      if (!ref.mounted) return true;
      state = state.copyWith(phase: ApplyConfirmPhase.saved);
      return true;
    } on AppException catch (error) {
      if (!ref.mounted) return false;
      state = state.copyWith(phase: ApplyConfirmPhase.saveFailed, error: error);
      return false;
    } on Exception catch (error) {
      if (!ref.mounted) return false;
      state = state.copyWith(
        phase: ApplyConfirmPhase.saveFailed,
        error: AppException(
          AppErrorKind.unknown,
          'We could not save your application. Try again in a moment.',
          cause: error,
        ),
      );
      return false;
    }
  }

  /// `Try again` after a failed redirect, or `Retry` after a failed write.
  void retry() {
    switch (state.phase) {
      case ApplyConfirmPhase.redirectFailed:
        reopen();
      case ApplyConfirmPhase.saveFailed:
        unawaited(submit());
      case ApplyConfirmPhase.ready ||
          ApplyConfirmPhase.redirecting ||
          ApplyConfirmPhase.awaitingReturn ||
          ApplyConfirmPhase.saving ||
          ApplyConfirmPhase.saved:
        break;
    }
  }
}
