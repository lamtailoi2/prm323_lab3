import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/errors/app_exception.dart';

/// Opens a link outside the app (browser or PDF viewer).
abstract interface class ExternalLinkService {
  /// Throws [AppException] when no app can open [uri].
  Future<void> open(Uri uri);
}

final externalLinkServiceProvider = Provider<ExternalLinkService>(
  (ref) => UrlLauncherLinkService(),
);

class UrlLauncherLinkService implements ExternalLinkService {
  @override
  Future<void> open(Uri uri) async {
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
      throw const AppException(
        AppErrorKind.unknown,
        'No app on this device can open this file.',
      );
    } on PlatformException catch (error) {
      throw AppException(
        AppErrorKind.unknown,
        'We could not open this file. Try again in a moment.',
        cause: error,
      );
    }
  }
}
