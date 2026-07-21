import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/firebase/firebase_refs.dart';

/// Thin wrapper over FirebaseAuth + the auth Cloud Functions. Keeps Firebase
/// types out of the UI layer.
class AuthRepository {
  const AuthRepository();

  /// We only need the email scope for Firebase auth; the iOS/Android client id
  /// is read from `GoogleService-Info.plist` / `google-services.json`, so it is
  /// not passed here.
  static final GoogleSignIn _google = GoogleSignIn(scopes: const ['email']);

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

  /// Runs the native Google account picker and signs the user into Firebase.
  ///
  /// Returns `null` when the user backs out of the picker — a cancellation, not
  /// an error, so callers stay silent. A brand-new Google user is signed in but
  /// has **no `role` claim**; the caller must route them through role selection
  /// (`/register/2`) so `completeRegistration` can finish the account.
  Future<UserCredential?> signInWithGoogle() async {
    final account = await _google.signIn();
    if (account == null) return null; // user dismissed the picker
    final auth = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: auth.accessToken,
      idToken: auth.idToken,
    );
    return Fb.auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    // Sign out of Google too, so the next person on this phone gets the account
    // picker instead of being silently signed back into the previous account.
    try {
      await _google.signOut();
    } catch (_) {
      // Not worth failing a sign-out over.
    }
    await Fb.auth.signOut();
  }

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
