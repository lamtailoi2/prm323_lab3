import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/state_view.dart';

/// Placeholder for the Search tab. The feature owner replaces it following
/// docs/lab2-handoff/design/screen-spec.md (Search).
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: AppTopBar.main(title: 'Search'),
      body: StateView.empty(
        icon: Symbols.construction_rounded,
        title: 'Search is not built yet',
        message: 'See screen-spec.md › Search.',
      ),
    );
  }
}
