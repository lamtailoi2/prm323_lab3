import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/state_view.dart';

/// Placeholder for the Saved tab. The feature owner replaces it following
/// docs/lab2-handoff/design/screen-spec.md (Saved Internships).
class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: AppTopBar.main(title: 'Saved'),
      body: StateView.empty(
        icon: Symbols.construction_rounded,
        title: 'Saved Internships is not built yet',
        message: 'See screen-spec.md › Saved Internships.',
      ),
    );
  }
}
