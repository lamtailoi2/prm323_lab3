import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/state_view.dart';

/// Placeholder for the Applications tab. The feature owner replaces it following
/// docs/design/screen-spec.md (My Applications).
class MyApplicationsScreen extends StatelessWidget {
  const MyApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: AppTopBar.main(title: 'Applications'),
      body: StateView.empty(
        icon: Symbols.construction_rounded,
        title: 'My Applications is not built yet',
        message: 'See screen-spec.md › My Applications.',
      ),
    );
  }
}
