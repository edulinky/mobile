import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/widgets/bottom_nav.dart';
import '../features/notifications/screens/notifications_screen.dart';
import '../features/premium/screens/premium_screen.dart';
import '../features/safety/screens/blocked_users_screen.dart';
import '../features/auth/models/app_user.dart';
import '../features/auth/providers/auth_controller.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_step1_screen.dart';
import '../features/auth/screens/register_step2_screen.dart';
import '../features/auth/screens/register_step3_screen.dart';
import '../features/auth/screens/cert_upload_screen.dart';
import '../features/auth/screens/pending_verification_screen.dart';
import '../features/discover/screens/student_discover_screen.dart';
import '../features/discover/screens/teacher_discover_screen.dart';
import '../features/matches/screens/student_matches_screen.dart';
import '../features/matches/screens/teacher_matches_screen.dart';
import '../features/messages/screens/chat_screen.dart';
import '../features/profile/screens/public_profile_screen.dart';
import '../features/profile/screens/student_profile_edit_screen.dart';
import '../features/profile/screens/teacher_profile_edit_screen.dart';
import '../features/settings/screens/student_settings_screen.dart';
import '../features/settings/screens/teacher_settings_screen.dart';
import '../features/settings/screens/institution_settings_screen.dart';
import '../features/jobs/screens/institution_paywall_screen.dart';
import '../features/jobs/screens/institution_profile_screen.dart';
import '../features/jobs/screens/institution_dashboard_screen.dart';
import '../features/jobs/screens/job_card_create_screen.dart';
import '../features/jobs/screens/job_card_detail_screen.dart';
import '../features/jobs/models/job_card.dart';

/// Home route for a given role, used by the redirect guard.
String roleHome(String? role) {
  switch (role) {
    case 'teacher':
      return '/teacher/discover';
    case 'institution':
      return '/institution/dashboard';
    case 'student':
    default:
      return '/student/discover';
  }
}

/// The registration steps carry their in-progress form data in `state.extra`.
/// It is a `Map<String, String>` when pushed, but go_router hands it back as a
/// `Map<String, dynamic>` after a hot restart restores the route stack — so
/// accept either shape.
Map<String, String> _registrationExtra(Object? extra) {
  if (extra is! Map) return {};
  return {
    for (final entry in extra.entries)
      if (entry.value != null) '${entry.key}': '${entry.value}',
  };
}

/// Routes reachable while signed out or mid-registration.
const _authRoutes = <String>{
  '/',
  '/login',
  '/register/1',
  '/register/2',
  '/register/3',
  '/cert-upload',
  '/pending',
};

final goRouterProvider = Provider<GoRouter>((ref) {
  // Bridge Riverpod auth state -> a Listenable go_router can refresh on.
  final authListenable =
      ValueNotifier<AsyncValue<AppUser?>>(const AsyncValue.loading());
  ref.onDispose(authListenable.dispose);
  ref.listen<AsyncValue<AppUser?>>(
    authStateProvider,
    (_, next) => authListenable.value = next,
    fireImmediately: true,
  );

  return GoRouter(
    initialLocation: '/',
    refreshListenable: authListenable,
    redirect: (context, state) {
      final auth = authListenable.value;
      // Don't redirect while the first auth check is still resolving.
      if (auth.isLoading) return null;

      final user = auth.valueOrNull;
      final loc = state.matchedLocation;
      final onAuthRoute = _authRoutes.contains(loc);

      // Signed out, or signed in but registration not finished (no role yet):
      // only the auth/registration routes are reachable.
      if (user == null || !user.hasRole) {
        return onAuthRoute ? null : '/';
      }

      // Signed in with a role: bounce off the entry screens to the role's home.
      if (loc == '/' || loc == '/login' || loc == '/register/1') {
        return roleHome(user.role);
      }
      return null;
    },
    routes: [
      // ── Auth ────────────────────────────────────────────────────────────────
      GoRoute(path: '/',            builder: (ctx, s) => const SplashScreen()),
      GoRoute(path: '/login',       builder: (ctx, s) => const LoginScreen()),
      GoRoute(path: '/register/1',  builder: (ctx, s) => const RegisterStep1Screen()),
      GoRoute(path: '/register/2',  builder: (ctx, state) {
        final data = _registrationExtra(state.extra);
        return RegisterStep2Screen(
          email:    data['email'] ?? '',
          password: data['password'] ?? '',
          fullName: data['fullName'] ?? '',
        );
      }),
      GoRoute(path: '/register/3',  builder: (ctx, state) {
        return RegisterStep3Screen(registrationData: _registrationExtra(state.extra));
      }),
      GoRoute(path: '/cert-upload', builder: (ctx, s) => const CertUploadScreen()),
      GoRoute(path: '/blocked',     builder: (ctx, s) => const BlockedUsersScreen()),
      GoRoute(path: '/premium',     builder: (ctx, s) => const PremiumScreen()),
      GoRoute(path: '/pending',     builder: (ctx, s) => const PendingVerificationScreen()),

      // ── Student ─────────────────────────────────────────────────────────────
      GoRoute(path: '/student/discover',        builder: (ctx, s) => const StudentDiscoverScreen()),
      GoRoute(path: '/student/matches',         builder: (ctx, s) => const StudentMatchesScreen()),
      GoRoute(path: '/student/notifications',   builder: (ctx, s) => const NotificationsScreen(role: NavRole.student)),
      GoRoute(path: '/student/profile',         builder: (ctx, s) => const StudentProfileEditScreen()),
      GoRoute(path: '/student/settings',        builder: (ctx, s) => const StudentSettingsScreen()),
      GoRoute(path: '/student/chat',            builder: (ctx, state) {
        final data = state.extra as Map<String, String>? ?? {};
        return ChatScreen(
          matchId:        data['matchId'] ?? '',
          otherName:      data['otherName'] ?? '',
          otherAvatarUrl: data['otherAvatarUrl'] ?? '',
          otherUid:       data['otherUid'] ?? '',
        );
      }),
      // Keyed by uid rather than a passed-in object, so the profile is loaded
      // fresh from Firestore and the route is deep-linkable. Role-neutral: a
      // student opens a teacher here, a teacher opens a student.
      GoRoute(path: '/profile/:uid', builder: (ctx, state) {
        return PublicProfileScreen(uid: state.pathParameters['uid'] ?? '');
      }),

      // ── Teacher ─────────────────────────────────────────────────────────────
      GoRoute(path: '/teacher/discover', builder: (ctx, s) => const TeacherDiscoverScreen()),
      GoRoute(path: '/teacher/matches',  builder: (ctx, s) => const TeacherMatchesScreen()),
      GoRoute(path: '/teacher/notifications', builder: (ctx, s) => const NotificationsScreen(role: NavRole.teacher)),
      GoRoute(path: '/teacher/profile',  builder: (ctx, s) => const TeacherProfileEditScreen()),
      GoRoute(path: '/teacher/settings', builder: (ctx, s) => const TeacherSettingsScreen()),
      GoRoute(path: '/teacher/chat',     builder: (ctx, state) {
        final data = state.extra as Map<String, String>? ?? {};
        return ChatScreen(
          matchId:        data['matchId'] ?? '',
          otherName:      data['otherName'] ?? '',
          otherAvatarUrl: data['otherAvatarUrl'] ?? '',
          otherUid:       data['otherUid'] ?? '',
        );
      }),

      // ── Institution ─────────────────────────────────────────────────────────
      GoRoute(path: '/institution/paywall',       builder: (ctx, s) => const InstitutionPaywallScreen()),
      GoRoute(path: '/institution/dashboard',     builder: (ctx, s) => const InstitutionDashboardScreen()),
      GoRoute(path: '/institution/job/new',       builder: (ctx, s) => const JobCardCreateScreen()),
      GoRoute(path: '/institution/job/:jobId/edit', builder: (ctx, state) =>
          JobCardCreateScreen(job: state.extra as JobCard?)),
      GoRoute(path: '/institution/job/:jobId',    builder: (ctx, state) =>
          JobCardDetailScreen(jobId: state.pathParameters['jobId'] ?? '')),
      GoRoute(path: '/institution/notifications', builder: (ctx, s) => const NotificationsScreen(role: NavRole.institution)),
      GoRoute(path: '/institution/profile',       builder: (ctx, s) => const InstitutionProfileScreen()),
      GoRoute(path: '/institution/settings',      builder: (ctx, s) => const InstitutionSettingsScreen()),
    ],
  );
});
