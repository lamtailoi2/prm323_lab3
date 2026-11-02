import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../theme/app_colors.dart';

/// Search Field component (Figma page 05 "Search Field / 2 specimens").
///
/// Leading search icon, optional trailing filter action, and a clear action
/// that appears once text is entered; clear and filter keep 48 × 48 dp
/// targets.
///
/// The field stays on one line and the default placeholder fits at 360 dp,
/// instead of the Figma placeholder wrapping to two lines (DC-25).
class AppSearchField extends StatefulWidget {
  const AppSearchField({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText = 'Search role, company, skill',
    this.wrapHint = false,
    this.autofocus = false,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    this.onCleared,
    this.onFilterPressed,
    this.filterCount,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String hintText;

  /// Lets a long placeholder wrap to two lines and the input grow, as the
  /// Figma Search Field spec does; used where the hint is longer than one
  /// line (Profile › Edit skills, DC-16).
  final bool wrapHint;
  final bool autofocus;

  /// Use with [onTap] when the field is only an entry point (e.g. on Home).
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onCleared;

  /// Shows the trailing filter action when non-null.
  final VoidCallback? onFilterPressed;
  final int? filterCount;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  TextEditingController? _ownedController;

  TextEditingController get _controller =>
      widget.controller ?? (_ownedController ??= TextEditingController());

  @override
  void dispose() {
    _ownedController?.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
    widget.onCleared?.call();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _controller,
      builder: (context, value, _) {
        final showClear = value.text.isNotEmpty && !widget.readOnly;
        final actions = <Widget>[
          if (showClear)
            IconButton(
              icon: const Icon(Symbols.close_rounded),
              tooltip: 'Clear search',
              color: AppColors.textSecondary,
              onPressed: _clear,
            ),
          if (widget.onFilterPressed != null)
            IconButton(
              icon: (widget.filterCount != null && widget.filterCount! > 0)
                  ? Badge.count(
                      count: widget.filterCount!,
                      backgroundColor: AppColors.primary,
                      textColor: AppColors.onPrimary,
                      child: const Icon(Symbols.tune_rounded),
                    )
                  : const Icon(Symbols.tune_rounded),
              tooltip: 'Filters',
              color: AppColors.textSecondary,
              onPressed: widget.onFilterPressed,
            ),
        ];

        return TextField(
          controller: _controller,
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          readOnly: widget.readOnly,
          onTap: widget.onTap,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.search,
          minLines: 1,
          maxLines: widget.wrapHint ? null : 1,
          decoration: InputDecoration(
            hintText: widget.hintText,
            // One line ends with an ellipsis if a larger font scale still
            // makes the hint too long.
            hintMaxLines: widget.wrapHint ? 2 : 1,
            prefixIcon: const Icon(
              Symbols.search_rounded,
              color: AppColors.textSecondary,
            ),
            suffixIcon: actions.isEmpty
                ? null
                : Row(mainAxisSize: MainAxisSize.min, children: actions),
          ),
        );
      },
    );
  }
}
