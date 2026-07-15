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
}
