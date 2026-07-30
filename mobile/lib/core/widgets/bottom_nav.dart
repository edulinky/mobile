import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/extensions/l10n_extension.dart';
import '../../core/theme/app_theme.dart';
import '../../features/notifications/data/notifications_repository.dart';

enum NavRole { student, teacher, institution }

class BottomNav extends ConsumerWidget {
  const BottomNav({super.key, required this.currentIndex, this.role = NavRole.student});

  final int currentIndex;
  final NavRole role;

  // Every role reaches Activity from a bell (in the Discover header for
  // student/teacher, on the Dashboard for institution), not a tab — five tabs
  // was too many, and Activity is a place you visit, not a place you live.
  List<String> get _routes => switch (role) {
    NavRole.teacher     => ['/teacher/discover', '/teacher/matches', '/teacher/profile', '/teacher/settings'],
    NavRole.institution => ['/institution/dashboard', '/institution/matches', '/institution/profile', '/institution/settings'],
    NavRole.student     => ['/student/discover', '/student/matches', '/student/profile', '/student/settings'],
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final unread = ref.watch(unreadNotificationsProvider);

    final items = switch (role) {
      NavRole.institution => [
        (Icons.dashboard_rounded,      Icons.dashboard_outlined,      l10n.navDashboard,     false),
        (Icons.handshake_rounded,      Icons.handshake_outlined,      l10n.navMatches,       false),
        (Icons.person_rounded,         Icons.person_outline_rounded,  l10n.navProfile,       false),
        (Icons.settings_rounded,       Icons.settings_outlined,       l10n.navSettings,      false),
      ],
      _ => [
        (Icons.explore_rounded,        Icons.explore_outlined,        l10n.navDiscover,      false),
        (Icons.handshake_rounded,      Icons.handshake_outlined,      l10n.navMatches,       false),
        (Icons.person_rounded,         Icons.person_outline_rounded,  l10n.navProfile,       false),
        (Icons.settings_rounded,       Icons.settings_outlined,       l10n.navSettings,      false),
      ],
    };

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        border: const Border(top: BorderSide(color: AppColors.skyLight, width: 0.8)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(items.length, (i) {
              final active = i == currentIndex;
              final (activeIcon, inactiveIcon, label, isAlerts) = items[i];
              return Expanded(
                child: InkWell(
                  onTap: () { if (!active) context.go(_routes[i]); },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _NavIcon(
                        icon: active ? activeIcon : inactiveIcon,
                        active: active,
                        badge: isAlerts ? unread : 0,
                      ),
                      const SizedBox(height: 2),
                      Text(label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                            color: active ? AppColors.skyDark : AppColors.text3,
                          )),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({required this.icon, required this.active, required this.badge});

  final IconData icon;
  final bool active;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(icon,
        color: active ? AppColors.skyDark : AppColors.text3, size: 24);
    if (badge <= 0) return iconWidget;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        iconWidget,
        Positioned(
          right: -6,
          top: -3,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            constraints: const BoxConstraints(minWidth: 16),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Text(
              badge > 9 ? '9+' : '$badge',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }
}
