/// The signed-in user as the app sees it: Firebase identity plus the `role`
/// resolved from Custom Claims. `role` is null between account creation and
/// `completeRegistration` finishing.
class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.verifiedStatus,
  });

  final String uid;
  final String? email;
  final String? displayName;
  final String? role; // 'student' | 'teacher' | 'institution' | 'admin' | null
  final String? verifiedStatus;

  bool get hasRole => role != null && role!.isNotEmpty;

  /// The three roles the mobile app is built for. An `admin` (web-panel only) or
  /// any future/unknown role is signed in but has no app experience, so the
  /// router parks them on the unsupported-account screen instead of a broken
  /// role home.
  static const appRoles = {'student', 'teacher', 'institution'};

  bool get isAppRole => role != null && appRoles.contains(role);
}
