import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../models/app_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return const AuthRepository();
});

/// The reactive source of truth for auth state. Emits the current [AppUser]
/// (with the `role` claim resolved) or null when signed out. The router watches
/// this to guard routes.
final authStateProvider = StreamProvider<AppUser?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges().asyncMap((user) async {
    if (user == null) return null;
    final token = await user.getIdTokenResult();
    return AppUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      role: token.claims?['role'] as String?,
      verifiedStatus: null,
    );
  });
});
