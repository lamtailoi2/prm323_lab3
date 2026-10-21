import 'package:flutter/material.dart';

import '../../../core/widgets/state_view.dart';

/// Shown while the first auth state is being restored.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: StateView.loading(message: 'Loading Internly'));
  }
}
