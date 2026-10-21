import 'package:flutter/foundation.dart';

import '../errors/app_exception.dart';

/// Explicit state model for every data-loading screen (Lab 3 §5: "a sealed
/// class or enum for loading, empty, error, data owned by its ViewModel").
///
/// ViewModels expose `ViewState<T>`; Views switch over it exhaustively:
///
/// ```dart
/// switch (state) {
///   ViewLoading() => const InternshipCardSkeleton(),
///   ViewEmpty() => StateView.empty(...),
///   ViewError(:final error) => StateView.error(message: error.message, ...),
///   ViewData(:final data) => ResultsList(data),
/// }
/// ```
@immutable
sealed class ViewState<T> {
  const ViewState();

  /// Builds [ViewData], or [ViewEmpty] when [isEmpty] says there is nothing
  /// to show (e.g. `ViewState.fromData(jobs, isEmpty: jobs.isEmpty)`).
  factory ViewState.fromData(T data, {required bool isEmpty}) =>
      isEmpty ? ViewEmpty<T>() : ViewData<T>(data);

  bool get isLoading => this is ViewLoading<T>;
}

final class ViewLoading<T> extends ViewState<T> {
  const ViewLoading();

  @override
  bool operator ==(Object other) => other is ViewLoading<T>;

  @override
  int get hashCode => (ViewLoading<T>).hashCode;
}

final class ViewEmpty<T> extends ViewState<T> {
  const ViewEmpty();

  @override
  bool operator ==(Object other) => other is ViewEmpty<T>;

  @override
  int get hashCode => (ViewEmpty<T>).hashCode;
}

final class ViewError<T> extends ViewState<T> {
  const ViewError(this.error);

  /// Carries a user-safe message; show it with `StateView.error` + Retry.
  final AppException error;

  @override
  bool operator ==(Object other) =>
      other is ViewError<T> && identical(other.error, error);

  @override
  int get hashCode => error.hashCode;
}

final class ViewData<T> extends ViewState<T> {
  const ViewData(this.data);

  final T data;

  @override
  bool operator ==(Object other) =>
      other is ViewData<T> && identical(other.data, data);

  @override
  int get hashCode => identityHashCode(data);
}
