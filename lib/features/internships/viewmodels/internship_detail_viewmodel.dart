import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/state/view_state.dart';
import '../../../core/utils/skill_match.dart';
import '../../../models/internship.dart';
import '../../../models/internship_application.dart';
import '../../../models/user_profile.dart';
import '../../../services/analytics_service.dart';
import '../../../services/application_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/internship_service.dart';
import '../../../services/remote_config_service.dart';
import '../../../services/user_profile_service.dart';
import '../../saved/viewmodels/saved_providers.dart';

/// Which listing to show and the tab it was opened from (`home`, `search`
/// or `saved`), sent with `view_internship` (docs/analytics-plan.md row 6).
typedef InternshipDetailArgs = ({String internshipKey, String source});

/// What Internship Detail shows once the listing is known.
@immutable
class InternshipDetail {
  const InternshipDetail({
    required this.internship,
    this.skillMatch,
    this.application,
  });

  final Internship internship;

  /// `null` hides the Skill match card: Remote Config `cv_match_enabled` is
  /// off, the listing mentions no known skill, or the profile is not loaded.
  final SkillMatch? skillMatch;

  /// The student's tracked application for this listing (Flow 2c "already
  /// applied"); `null` when there is none or it could not be loaded.
  final InternshipApplication? application;
}

final internshipDetailViewModelProvider = NotifierProvider.autoDispose
    .family<
      InternshipDetailViewModel,
      ViewState<InternshipDetail>,
      InternshipDetailArgs
    >(InternshipDetailViewModel.new);

class InternshipDetailViewModel extends Notifier<ViewState<InternshipDetail>> {
  InternshipDetailViewModel(this.args);

  final InternshipDetailArgs args;

  StreamSubscription<Internship?>? _subscription;

  /// `false` until the first snapshot of the listing arrives.
  bool _resolved = false;
  Internship? _listing;

  /// Saved copies outlive the shared pool, so a saved listing that expired
  /// still opens (G-25 #5).
  Map<String, Internship> _savedCopies = const <String, Internship>{};

  /// `null` until the profile loads (or when it fails): the card waits
  /// instead of showing "0 of N" for a student who does have skills.
  List<String>? _profileSkills;
  InternshipApplication? _application;
  bool _viewLogged = false;

  @override
  ViewState<InternshipDetail> build() {
    final service = ref.watch(internshipServiceProvider);
    final remoteConfig = ref.watch(remoteConfigServiceProvider);
    // User-scoped (AGENTS.md rule 11): another account recomputes the match.
    final uid = ref.watch(currentUserIdProvider);
    final profiles = ref.watch(userProfileServiceProvider);
    // Also user-scoped: the service is rebuilt for each uid.
    final applications = ref.watch(applicationServiceProvider);
    _resolved = false;
    _listing = null;
    _profileSkills = null;
    _application = null;
    _viewLogged = false;

    ref.listen(savedInternshipsProvider, (previous, next) {
      _savedCopies = {
        for (final internship in next.asData?.value ?? const <Internship>[])
          internship.key: internship,
      };
      if (!_resolved || _listing != null) return;
      // Unsaving an expired listing removes its only copy; keep showing it
      // rather than "no longer available" (CR-03).
      final unsavedWhileShown =
          state is ViewData<InternshipDetail> &&
          !_savedCopies.containsKey(args.internshipKey);
      if (!unsavedWhileShown) _emit();
    }, fireImmediately: true);

    final updates = remoteConfig.onUpdated.listen((_) {
      if (state is ViewData<InternshipDetail>) _emit();
    });
    final profile = uid == null
        ? null
        : profiles
              .watchProfile(uid)
              .listen(
                _onProfile,
                // The listing still shows without the profile; only the
                // Skill match card stays hidden.
                onError: (Object _, StackTrace _) {},
              );
    final applied = applications.watchApplications().listen(
      _onApplications,
      // Without the applications the listing still opens as not applied;
      // My Applications shows its own load error.
      onError: (Object _, StackTrace _) {},
    );
    ref.onDispose(() {
      unawaited(updates.cancel());
      unawaited(profile?.cancel());
      unawaited(applied.cancel());
      unawaited(_subscription?.cancel());
    });

    _subscribe(service);
    return const ViewLoading();
  }

  /// Listens to the listing again after a load error.
  void retry() {
    if (state.isLoading) return;
    final service = ref.read(internshipServiceProvider);
    _resolved = false;
    state = const ViewLoading();
    _subscribe(service);
  }

  void _subscribe(InternshipService service) {
    unawaited(_subscription?.cancel());
    _subscription = service
        .watchByKey(args.internshipKey)
        .listen(_onListing, onError: _onError);
  }

  void _onListing(Internship? listing) {
    if (!ref.mounted) return;
    _resolved = true;
    _listing = listing;
    _emit();
  }

  void _onProfile(UserProfile? profile) {
    if (!ref.mounted) return;
    final skills = profile?.skills ?? const <String>[];
    if (listEquals(skills, _profileSkills)) return;
    _profileSkills = skills;
    if (state is ViewData<InternshipDetail>) _emit();
  }

  void _onApplications(List<InternshipApplication> applications) {
    if (!ref.mounted) return;
    final mine = applications
        .where((application) => application.jobKey == args.internshipKey)
        .firstOrNull;
    if (identical(mine, _application)) return;
    _application = mine;
    if (state is ViewData<InternshipDetail>) _emit();
  }

  void _onError(Object error, StackTrace stack) {
    if (!ref.mounted) return;
    state = ViewError(
      error is AppException
          ? error
          : AppException(
              AppErrorKind.unknown,
              'We could not load this internship. Try again in a moment.',
              cause: error,
            ),
    );
  }

  void _emit() {
    final internship = _listing ?? _savedCopies[args.internshipKey];
    if (internship == null) {
      state = const ViewEmpty();
      return;
    }

    final remoteConfig = ref.read(remoteConfigServiceProvider);
    final skills = _profileSkills;
    final match =
        remoteConfig.getBool(RemoteConfigKeys.cvMatchEnabled) && skills != null
        ? skillMatchFor(listingSkills: internship.skills, profileSkills: skills)
        : null;
    state = ViewData(
      InternshipDetail(
        internship: internship,
        skillMatch: match,
        application: _application,
      ),
    );
    _logView(internship);
  }

  /// Logs `view_internship` once per opened detail, not on every snapshot.
  void _logView(Internship internship) {
    if (_viewLogged) return;
    _viewLogged = true;
    final analytics = ref.read(analyticsServiceProvider);
    unawaited(
      analytics.logEvent('view_internship', {
        'internship_id': internship.key,
        // Analytics truncates parameter values above 100 characters.
        'internship_title': _cap(internship.title),
        'company_name': _cap(internship.companyName),
        'source': args.source,
      }),
    );
  }

  static String _cap(String value) =>
      value.length <= 100 ? value : value.substring(0, 100);
}
