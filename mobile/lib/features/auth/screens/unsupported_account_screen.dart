import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/extensions/l10n_extension.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_controller.dart';
import '../widgets/primary_button.dart';

/// Shown when a signed-in account has a role the mobile app has no experience
/// for — today that means an `admin` account, which belongs to the web panel.
/// Without this, the router would fall back to the student deck and the user
/// would hit "this role has no discovery feed".
class UnsupportedAccountScreen extends ConsumerWidget {
  const UnsupportedAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.skyBg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.desktop_windows_rounded,
                    size: 64, color: AppColors.text3),
                const SizedBox(height: 20),
                Text(
                  l10n.unsupportedAccountTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800, color: AppColors.text),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.unsupportedAccountBody,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.text2, height: 1.5),
                ),
                const SizedBox(height: 28),
                PrimaryButton(
                  label: l10n.signOut,
                  onPressed: () => ref.read(authRepositoryProvider).signOut(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
