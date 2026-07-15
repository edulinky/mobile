import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/bottom_nav.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/extensions/l10n_extension.dart';
import '../../auth/widgets/sign_out_action.dart';
import '../../premium/widgets/upgrade_card.dart';
import '../../profile/data/profile_repository.dart';

class TeacherSettingsScreen extends ConsumerStatefulWidget {
  const TeacherSettingsScreen({super.key});

  @override
  ConsumerState<TeacherSettingsScreen> createState() => _TeacherSettingsScreenState();
}

class _TeacherSettingsScreenState extends ConsumerState<TeacherSettingsScreen> {
  // Both of these were hard-coded while payments were a prototype (`_isPremium =
  // true`, "Demo: teacher is premium"). They are server state now: `sub_status`
  // and `featured` on the user doc, written only by the RevenueCat webhook.
  bool get _isPremium => ref.watch(isPremiumProvider);
  bool get _featured =>
      ref.watch(myProfileProvider).valueOrNull?.featured ?? false;

  @override
  Widget build(BuildContext context) {
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
              child: Text(l10n.teacherSettingsTitle,
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
                    const SizedBox(height: 20),
                    _buildFeaturedCard(context, l10n),
                    const SizedBox(height: 24),
                    if (!_isPremium) const UpgradeCard(isTeacher: true),
                    // Only the store can cancel a subscription — an app is not
                    // allowed to. Say where it lives, or the user charges back.
                    if (_isPremium) const PremiumStatusCard(),
                    const SizedBox(height: 24),
                    _buildAccountSection(context, l10n),
                  ],
                ),
              ),
            ),
            const BottomNav(currentIndex: 3, role: NavRole.teacher),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard(BuildContext context, dynamic l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isPremium
              ? [const Color(0xFF7C3AED), const Color(0xFF4F46E5)]
              : [AppColors.skyDark, AppColors.skyDeeper],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (_isPremium ? const Color(0xFF7C3AED) : AppColors.skyDark).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(children: [
        Icon(_isPremium ? Icons.workspace_premium_rounded : Icons.card_membership_rounded,
            color: Colors.white, size: 36),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l10n.currentPlan,
                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
            Text(_isPremium ? l10n.premiumPlan : l10n.freePlan,
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(_isPremium ? l10n.unlimitedSwipes : l10n.swipesPerDay(20),
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ]),
        ),
      ]),
    );
  }

  /// The Featured badge.
  ///
  /// FR-3.3 makes it a **paid perk** ("Premium Teacher: Unlimited swipes +
  /// Featured badge"), so it is granted by the RevenueCat webhook and revoked
  /// when the subscription lapses. It is deliberately **not a switch any more**:
  /// the old one was a local bool that pretended the teacher could turn the perk
  /// on and off, when in truth only the server can grant it — and a control that
  /// does nothing is worse than no control.
  Widget _buildFeaturedCard(BuildContext context, dynamic l10n) {
    final active = _isPremium && _featured;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: active
            ? Border.all(color: const Color(0xFFF59E0B), width: 1.5)
            : null,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: active
                ? const Color(0xFFFEF3C7)
                : AppColors.skyLight.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            Icons.star_rounded,
            color: active ? const Color(0xFFF59E0B) : AppColors.text3,
            size: 26,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l10n.featuredProfile,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.text)),
            const SizedBox(height: 3),
            Text(
              active ? l10n.featuredProfileDesc : l10n.premiumRequired,
              style: TextStyle(
                  fontSize: 12,
                  color: active ? AppColors.text2 : AppColors.text3),
            ),
          ]),
        ),
        const SizedBox(width: 12),
        active
            ? const Icon(Icons.check_circle_rounded,
                color: Color(0xFFF59E0B), size: 22)
            : const Icon(Icons.lock_rounded, color: AppColors.text3, size: 20),
      ]),
    );
  }

  Widget _buildAccountSection(BuildContext context, dynamic l10n) {
    final items = [
      (Icons.block_rounded, l10n.blockedUsers, AppColors.text2, false,
          () => context.push('/blocked')),
      (Icons.help_outline_rounded,   l10n.helpAndSupport, AppColors.text2, false, null),
      (Icons.privacy_tip_outlined,   l10n.privacyPolicy,  AppColors.text2, false, null),
      (Icons.gavel_rounded,          l10n.termsOfService, AppColors.text2, false, null),
      (Icons.logout_rounded,         l10n.signOut,        AppColors.text2, false, () => confirmSignOut(context, ref)),
      (Icons.delete_outline_rounded, l10n.deleteAccount,  AppColors.error, true, null),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.accountSection,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: AppColors.text)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
          ),
          child: Column(
            children: items.asMap().entries.map((e) {
              final i = e.key;
              final (icon, label, color, isDanger, action) = e.value;
              return Column(children: [
                InkWell(
                  onTap: action,
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    child: Row(children: [
                      Icon(icon, color: color, size: 20),
                      const SizedBox(width: 14),
                      Expanded(child: Text(label,
                          style: TextStyle(
                              fontSize: 15, color: color,
                              fontWeight: isDanger ? FontWeight.w600 : FontWeight.w400))),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.text3, size: 20),
                    ]),
                  ),
                ),
                if (i < items.length - 1)
                  const Divider(height: 0.5, indent: 52, color: AppColors.skyLight),
              ]);
            }).toList(),
          ),
        ),
      ],
    );
  }
}
