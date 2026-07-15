import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/extensions/l10n_extension.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/primary_button.dart';

class PendingVerificationScreen extends StatelessWidget {
  const PendingVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.skyBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(Icons.hourglass_top_rounded, size: 48, color: Color(0xFFD97706)),
              ),
              const SizedBox(height: 28),
              Text(
                l10n.pendingVerificationTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800, color: AppColors.text),
              ),
              const SizedBox(height: 14),
              Text(
                l10n.pendingVerificationBody,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.text2, height: 1.6),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.skyLight.withValues(alpha:0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time_rounded, size: 18, color: AppColors.skyDark),
                    const SizedBox(width: 8),
                    Text(l10n.estimatedTime,
                        style: const TextStyle(fontSize: 13, color: AppColors.skyDark, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const Spacer(flex: 2),
              PrimaryButton(
                label: l10n.goToDiscover,
                onPressed: () => context.go('/'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
