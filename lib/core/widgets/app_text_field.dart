import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_sizes.dart';
import '../../theme/app_spacing.dart';

/// Text Field component (Figma page 05 "Text Field / 5 specimens").
///
/// The label sits above the field and persists in every state. Validation
/// belongs to the ViewModel: pass the message in [errorText] and the field
/// shows the error border, an error icon and the message below.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.focusNode,
    this.hintText,
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.inputFormatters,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.onChanged,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController? controller;
  final FocusNode? focusNode;

  /// Placeholder shown as an example, never as a replacement for [label].
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasError = errorText != null;

    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: textTheme.labelLarge?.copyWith(
              color: enabled ? AppColors.textPrimary : AppColors.disabled,
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: enabled,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            autofillHints: autofillHints,
            inputFormatters: inputFormatters,
            maxLines: maxLines,
            minLines: minLines,
            maxLength: maxLength,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            style: textTheme.bodyLarge?.copyWith(
              color: enabled ? AppColors.textPrimary : AppColors.disabled,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              helperText: helperText,
              helperStyle: enabled
                  ? null
                  : textTheme.bodyMedium?.copyWith(color: AppColors.disabled),
              errorText: errorText,
              suffixIcon: hasError
                  ? const Icon(
                      Symbols.error_rounded,
                      color: AppColors.error,
                      size: AppSizes.iconSmall,
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
