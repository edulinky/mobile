import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/firebase/firebase_refs.dart';

/// Thin wrapper over FirebaseAuth + the auth Cloud Functions. Keeps Firebase
/// types out of the UI layer.
class AuthRepository {
  const AuthRepository();

  /// Emits on sign-in/out AND on token refresh — the latter is how a freshly set
  /// role claim reaches the app after [completeRegistration].
  Stream<User?> authStateChanges() => Fb.auth.userChanges();

  User? get currentUser => Fb.auth.currentUser;

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return Fb.auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> createAccount({
    required String email,
    required String password,
  }) {
    return Fb.auth
        .createUserWithEmailAndPassword(email: email, password: password);
  }

  /// Calls the `completeRegistration` Cloud Function, then force-refreshes the
  /// ID token so the new `role` claim is immediately available.
  Future<void> completeRegistration({
    required String role,
    required String displayName,
    required String city,
    required double lat,
    required double lng,
    required String placeId,
    String primarySubject = '',
  }) async {
    final callable = Fb.functions.httpsCallable('completeRegistration');
    await callable.call<Object?>({
      'role': role,
      'displayName': displayName,
      'city': city,
      'lat': lat,
      'lng': lng,
      'placeId': placeId,
      'primarySubject': primarySubject,
    });
    await Fb.auth.currentUser?.getIdToken(true);
  }

  Future<void> signOut() => Fb.auth.signOut();

  Future<void> sendPasswordReset(String email) =>
      Fb.auth.sendPasswordResetEmail(email: email);

  /// Rolls back a half-finished registration (auth account created but
  /// `completeRegistration` failed) so the user can retry cleanly.
  Future<void> deleteCurrentUser() async {
    try {
      await Fb.auth.currentUser?.delete();
    } catch (_) {
      // Best-effort cleanup; ignore (e.g. requires-recent-login).
    }
  }
}
