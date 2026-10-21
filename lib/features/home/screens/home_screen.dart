import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/state_view.dart';

/// Placeholder for the Home tab. The feature owner replaces it following
/// docs/lab2-handoff/design/screen-spec.md (Home).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: AppTopBar.main(title: 'Home'),
      body: StateView.empty(
        icon: Symbols.construction_rounded,
        title: 'Home is not built yet',
        message: 'See screen-spec.md › Home.',
      ),
    );
  }
}
