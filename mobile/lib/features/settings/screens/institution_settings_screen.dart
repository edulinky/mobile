import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/bottom_nav.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/extensions/l10n_extension.dart';
import '../../auth/widgets/sign_out_action.dart';

class InstitutionSettingsScreen extends ConsumerWidget {
  const InstitutionSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.skyBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(l10n.settingsTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800, color: AppColors.text)),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSubscriptionCard(context, l10n),
                    const SizedBox(height: 24),
                    _buildBillingSection(context, l10n),
                    const SizedBox(height: 24),
                    _buildAccountSection(context, ref, l10n),
                  ],
                ),
              ),
            ),
            const BottomNav(currentIndex: 3, role: NavRole.institution),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard(BuildContext context, dynamic l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF052E16), Color(0xFF065F46)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF065F46).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.account_balance_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.currentPlan,
                    style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                Text(context.l10n.subscriptionProName,
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(context.l10n.subscriptionRenews('21 May 2026'),
                    style: TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingSection(BuildContext context, dynamic l10n) {
    final items = [
      (Icons.autorenew_rounded,   l10n.changePlan,           AppColors.text2, false, null),
      (Icons.cancel_outlined,     l10n.cancelSubscription,   AppColors.error,  true, null),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.billingSection,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800, color: AppColors.text)),
        const SizedBox(height: 12),
        _menuCard(items),
      ],
    );
  }

  Widget _buildAccountSection(BuildContext context, WidgetRef ref, dynamic l10n) {
    final items = [
      (Icons.block_rounded, l10n.blockedUsers, AppColors.text2, false,
          () => context.push('/blocked')),
      (Icons.help_outline_rounded,    l10n.helpAndSupport,  AppColors.text2, false, null),
      (Icons.privacy_tip_outlined,    l10n.privacyPolicy,   AppColors.text2, false, null),
      (Icons.gavel_rounded,           l10n.termsOfService,  AppColors.text2, false, null),
      (Icons.logout_rounded,          l10n.signOut,         AppColors.text2, false, () => confirmSignOut(context, ref)),
      (Icons.delete_outline_rounded,  l10n.deleteAccount,   AppColors.error,  true, null),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.accountSection,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800, color: AppColors.text)),
        const SizedBox(height: 12),
        _menuCard(items),
      ],
    );
  }

  Widget _menuCard(List<(IconData, dynamic, Color, bool, VoidCallback?)> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final i = e.key;
          final (icon, label, color, isDanger, action) = e.value;
          return Column(
            children: [
              InkWell(
                onTap: action,
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: Row(
                    children: [
                      Icon(icon, color: color, size: 20),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(label,
                            style: TextStyle(
                                fontSize: 15,
                                color: color,
                                fontWeight: isDanger ? FontWeight.w600 : FontWeight.w400)),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.text3, size: 20),
                    ],
                  ),
                ),
              ),
              if (i < items.length - 1)
                const Divider(height: 0.5, indent: 52, color: AppColors.skyLight),
            ],
          );
        }).toList(),
      ),
    );
  }
}
