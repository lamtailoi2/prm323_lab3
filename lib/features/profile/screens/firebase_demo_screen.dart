import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/router.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../services/notification_service.dart';
import '../../../services/remote_config_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../viewmodels/firebase_demo_viewmodel.dart';
import '../widgets/profile_section.dart';

/// Firebase demo area (G-06, Lab 3 §3): the Remote Config values the app is
/// using, the explicit Crashlytics test actions, and links to the two Lab 3
/// screens. It lives under Profile so a demo needs no debug build.
class FirebaseDemoScreen extends ConsumerWidget {
  const FirebaseDemoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(firebaseDemoViewModelProvider);
    final viewModel = ref.read(firebaseDemoViewModelProvider.notifier);

    return Scaffold(
      appBar: const AppTopBar.back(title: 'Firebase demo'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenHorizontal,
          AppSpacing.s16,
          AppSpacing.screenHorizontal,
          AppSpacing.s24,
        ),
        children: [
          _RemoteConfigSection(config: state.config),
          const SizedBox(height: AppSpacing.section),
          _CrashlyticsSection(
            isSendingNonFatal: state.isSendingNonFatal,
            onSendNonFatal: () => _sendNonFatal(context, viewModel),
            onTestCrash: () => _confirmTestCrash(context, viewModel),
          ),
          const SizedBox(height: AppSpacing.section),
          _LinksSection(
            onNotifications: () => context.push(AppRoutes.notificationCenter),
          ),
          const SizedBox(height: AppSpacing.section),
          _ConsoleSection(onCopyToken: () => _copyFcmToken(context, ref)),
        ],
      ),
    );
  }

  static Future<void> _sendNonFatal(
    BuildContext context,
    FirebaseDemoViewModel viewModel,
  ) async {
    final sent = await viewModel.recordNonFatal();
    if (!context.mounted) return;
    _showMessage(
      context,
      sent
          ? 'Non-fatal error sent. It appears in Crashlytics in a few minutes.'
          : 'Could not send the test error. Try again.',
    );
  }

  /// Always behind a confirmation: the app closes immediately.
  static Future<void> _confirmTestCrash(
    BuildContext context,
    FirebaseDemoViewModel viewModel,
  ) async {
    final confirmed = await showAppDialog(
      context,
      title: 'Simulate a crash?',
      message:
          'Internly will close immediately. Reopen it so Crashlytics can '
          'send the report.',
      primaryLabel: 'Crash now',
    );
    if (confirmed != true) return;
    viewModel.crashForTesting();
  }

  /// Copies this device's FCM token, the target of a Firebase Console test
  /// message (docs/guides/firebase-setup.md §9).
  static Future<void> _copyFcmToken(BuildContext context, WidgetRef ref) async {
    final token = await ref.read(notificationServiceProvider).token();
    if (!context.mounted) return;
    if (token == null || token.trim().isEmpty) {
      _showMessage(
        context,
        'No FCM token yet. Use a device with Google Play services and try '
        'again.',
      );
      return;
    }
    try {
      await Clipboard.setData(ClipboardData(text: token));
    } catch (error) {
      debugPrint('Could not copy the FCM token: $error');
      if (context.mounted) {
        _showMessage(context, 'Could not copy the FCM token. Try again.');
      }
      return;
    }
    if (!context.mounted) return;
    _showMessage(context, 'FCM token copied.');
  }

  static void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

/// The values currently in use, with their source, so a screenshot proves the
/// app read Remote Config rather than its in-app defaults.
class _RemoteConfigSection extends StatelessWidget {
  const _RemoteConfigSection({required this.config});

  final Map<String, ({String value, String source})> config;

  static const Map<String, String> _labels = <String, String>{
    RemoteConfigKeys.homeRecommendedLimit: 'Home · Recommended cards',
    RemoteConfigKeys.homeRecentLimit: 'Home · Recently posted cards',
    RemoteConfigKeys.cvMatchEnabled: 'CV Match Check',
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final keys = config.keys.toList()..sort();

    return ProfileSection(
      icon: Symbols.tune_rounded,
      title: 'Remote Config',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < keys.length; index++) ...[
            if (index > 0) const Divider(height: AppSpacing.s24),
            _ConfigValue(
              label: _labels[keys[index]] ?? keys[index],
              keyName: keys[index],
              value: config[keys[index]]!,
            ),
          ],
          const SizedBox(height: AppSpacing.s16),
          Text(
            'Change a value in the Firebase Console. The app applies it '
            'without a rebuild.',
            style: textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ConfigValue extends StatelessWidget {
  const _ConfigValue({
    required this.label,
    required this.keyName,
    required this.value,
  });

  final String label;
  final String keyName;
  final ({String value, String source}) value;

  static String _sourceLabel(String source) => switch (source) {
    'remote' => 'From Firebase',
    'static' => 'Static value',
    _ => 'In-app default',
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textTheme.titleSmall),
        const SizedBox(height: AppSpacing.s4),
        Text(keyName, style: textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.s4),
        Text(
          '${value.value} · ${_sourceLabel(value.source)}',
          style: textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _CrashlyticsSection extends StatelessWidget {
  const _CrashlyticsSection({
    required this.isSendingNonFatal,
    required this.onSendNonFatal,
    required this.onTestCrash,
  });

  final bool isSendingNonFatal;
  final VoidCallback onSendNonFatal;
  final VoidCallback onTestCrash;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ProfileSection(
      icon: Symbols.bug_report_rounded,
      title: 'Crashlytics',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'A non-fatal error is reported while the app keeps running. The '
            'test crash closes the app; reopen it to send the report.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.s16),
          AppButton(
            label: 'Send a non-fatal error',
            icon: Symbols.error_rounded,
            variant: AppButtonVariant.secondary,
            expand: true,
            isLoading: isSendingNonFatal,
            onPressed: onSendNonFatal,
          ),
          const SizedBox(height: AppSpacing.s12),
          AppButton(
            label: 'Simulate app crash',
            icon: Symbols.bug_report_rounded,
            variant: AppButtonVariant.secondary,
            expand: true,
            onPressed: onTestCrash,
          ),
        ],
      ),
    );
  }
}

/// The two Lab 3 screens. The report export has no route yet (G-05), so its
/// row is disabled instead of faking a destination.
class _LinksSection extends StatelessWidget {
  const _LinksSection({required this.onNotifications});

  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    const chevron = Icon(
      Symbols.chevron_right_rounded,
      color: AppColors.textSecondary,
    );
    return ProfileSection(
      icon: Symbols.open_in_new_rounded,
      title: 'Open',
      padded: false,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Symbols.notifications_rounded),
            title: const Text('Notification Center'),
            subtitle: const Text('Messages received on this device.'),
            trailing: chevron,
            onTap: onNotifications,
          ),
          const Divider(),
          const ListTile(
            enabled: false,
            leading: Icon(Symbols.download_rounded),
            title: Text('Report export'),
            subtitle: Text('Coming soon.'),
          ),
        ],
      ),
    );
  }
}

class _ConsoleSection extends StatelessWidget {
  const _ConsoleSection({required this.onCopyToken});

  final VoidCallback onCopyToken;

  @override
  Widget build(BuildContext context) {
    return ProfileSection(
      icon: Symbols.cloud_rounded,
      title: 'Firebase Console',
      padded: false,
      child: ListTile(
        leading: const Icon(Symbols.key_rounded),
        title: const Text('Copy FCM token'),
        subtitle: const Text('For Firebase Console → Send test message.'),
        trailing: const Icon(
          Symbols.chevron_right_rounded,
          color: AppColors.textSecondary,
        ),
        onTap: onCopyToken,
      ),
    );
  }
}
