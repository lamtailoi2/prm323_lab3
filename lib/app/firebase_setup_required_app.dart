import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../core/widgets/state_view.dart';
import '../theme/app_theme.dart';

/// Shown instead of the app when Firebase is not configured for this build,
/// so a missing configuration is obvious and never silently faked.
class FirebaseSetupRequiredApp extends StatelessWidget {
  const FirebaseSetupRequiredApp({super.key, this.details});

  final String? details;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Internly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: Scaffold(
        body: SafeArea(
          child: StateView.empty(
            icon: Symbols.settings_alert_rounded,
            title: 'Firebase is not configured',
            message:
                'Run `flutterfire configure` and rebuild. '
                'Setup steps are in docs/guides/firebase-setup.md.'
                '${details == null ? '' : '\n\n$details'}',
          ),
        ),
      ),
    );
  }
}
