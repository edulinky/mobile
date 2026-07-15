import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/bottom_nav.dart';
import '../data/notifications_repository.dart';

/// Bell + unread badge, opening the Activity feed.
///
/// Lives in the Discover header rather than the bottom nav: a fifth tab crowded
/// it, and Activity is a place you visit, not a place you live.
class ActivityBell extends ConsumerWidget {
  const ActivityBell({super.key, required this.role});

  final NavRole role;

  String get _route => switch (role) {
        NavRole.teacher => '/teacher/notifications',
        NavRole.institution => '/institution/notifications',
        NavRole.student => '/student/notifications',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationsProvider);

    return GestureDetector(
      onTap: () => context.push(_route),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Icon(
              unread > 0
                  ? Icons.notifications_rounded
                  : Icons.notifications_none_rounded,
              size: 21,
              color: unread > 0 ? AppColors.skyDark : AppColors.text2,
            ),
            if (unread > 0)
              Positioned(
                right: 4,
                top: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  constraints: const BoxConstraints(minWidth: 15),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text(
                    unread > 9 ? '9+' : '$unread',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        height: 1.2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
