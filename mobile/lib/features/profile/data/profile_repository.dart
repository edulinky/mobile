import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/firebase/firebase_refs.dart';
import '../../../core/money/currency.dart';
import '../../../core/places/places_service.dart';
import '../../../core/storage/storage_service.dart';
import '../models/user_profile.dart';

/// One certificate document picked for upload.
class CertificateFile {
  const CertificateFile({
    required this.name,
    required this.bytes,
  });

  final String name;
  final Uint8List bytes;

  bool get isPdf => name.toLowerCase().endsWith('.pdf');

  String get contentType => switch (name.toLowerCase().split('.').last) {
        'pdf' => 'application/pdf',
        'png' => 'image/png',
        _ => 'image/jpeg',
      };
}

/// Reads and writes the signed-in user's own `users/{uid}` document and media.
///
/// Server-owned fields are rejected by the Firestore rules and can only change
/// via a callable: `verified_status`/`cert_path` (see [submitCertification]),
/// `geo_location` (see [setCity]), and `role`/`sub_status`/`is_banned` (admin).
class ProfileRepository {
  const ProfileRepository(this._storage);

  final StorageService _storage;

  String get _uid {
    final uid = Fb.auth.currentUser?.uid;
    if (uid == null) throw StateError('No signed-in user.');
    return uid;
  }

  /// Live view of the signed-in user's profile.
  Stream<UserProfile> watchMyProfile() => watchProfile(_uid);

  /// Live view of *any* user's profile — the rules allow any signed-in user to
  /// read `users/{uid}`, which is what the public profile screen renders.
  Stream<UserProfile> watchProfile(String uid) {
    return Fb.users.doc(uid).snapshots().map((doc) {
      if (!doc.exists) throw StateError('Profile not found.');
      return UserProfile.fromDoc(doc);
    });
  }

  /// Patches the client-editable profile fields. Only pass what changed.
  Future<void> updateProfile({
    String? displayName,
    String? about,
    String? primarySubject,
    List<String>? subjects,
    num? hourlyRate,
    Currency? currency,
    List<String>? qualifications,
    List<ExperienceEntry>? experience,
    Map<String, Set<String>>? availability,
    String? website,
    String? contactEmail,
  }) async {
    final patch = <String, Object?>{
      'display_name': ?displayName,
      'about': ?about,
      'primary_subject': ?primarySubject,
      'subjects': ?subjects,
      'hourly_rate': ?hourlyRate,
      // Always written alongside the amount it denominates.
      'currency': ?currency?.code,
      'qualifications': ?qualifications,
      'experience': ?experience?.map((e) => e.toMap()).toList(),
      'availability': ?availability
          ?.map((day, slots) => MapEntry(day, slots.toList())),
      'website': ?website,
      'contact_email': ?contactEmail,
    };
    if (patch.isEmpty) return;
    await Fb.users.doc(_uid).update(patch);
  }

  /// Uploads a gallery photo, then records it server-side (the callable checks
  /// the path is ours and enforces the 6-photo cap). Returns the Storage path.
  Future<String> addGalleryPhoto(Uint8List bytes) async {
    final path = await _storage.uploadGalleryPhoto(uid: _uid, bytes: bytes);
    await Fb.functions
        .httpsCallable('addGalleryPhoto')
        .call<Object?>({'path': path});
    return path;
  }

  Future<void> removeGalleryPhoto(String path) async {
    await Fb.functions
        .httpsCallable('removeGalleryPhoto')
        .call<Object?>({'path': path});
  }

  /// Resolves a `gallery/…` Storage path to a URL the app can render.
  Future<String> galleryPhotoUrl(String path) =>
      Fb.storage.ref(path).getDownloadURL();

  /// Replaces the video links. Server-validated: https YouTube/Vimeo only, max 4.
  Future<void> setVideoLinks(List<String> links) async {
    await Fb.functions
        .httpsCallable('setVideoLinks')
        .call<Object?>({'links': links});
  }

  /// Uploads the cropped photo and points the profile at it.
  Future<String> setAvatar(Uint8List bytes) async {
    final uid = _uid;
    final url = await _storage.uploadAvatar(uid: uid, bytes: bytes);
    await Fb.users.doc(uid).update({'photo_url': url});
    return url;
  }

  /// Moves the user to a new city. Goes through a callable so the geohash is
  /// derived server-side from the coordinates.
  Future<void> setCity(SelectedCity city) async {
    await Fb.functions.httpsCallable('updateLocation').call<Object?>({
      'city': city.city,
      'lat': city.lat,
      'lng': city.lng,
      'placeId': city.placeId,
    });
  }

  /// Uploads a teacher's certificate documents, then asks the server to queue
  /// them for review. Several files are allowed — a degree, a teaching
  /// qualification and a licence are commonly separate documents.
  ///
  /// `verified_status` is only ever set server-side.
  Future<void> submitCertification(List<CertificateFile> files) async {
    if (files.isEmpty) return;
    final uid = _uid;
    final certPaths = await Future.wait(
      files.map((f) => _storage.uploadCertificate(
            uid: uid,
            bytes: f.bytes,
            fileName: f.name,
            contentType: f.contentType,
          )),
    );
    await Fb.functions
        .httpsCallable('submitCertification')
        .call<Object?>({'certPaths': certPaths});
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(storageServiceProvider));
});

/// The signed-in user's profile, kept in sync with Firestore.
final myProfileProvider = StreamProvider<UserProfile>((ref) {
  return ref.watch(profileRepositoryProvider).watchMyProfile();
});

/// Any user's profile by uid — what the public profile screen renders.
final userProfileProvider =
    StreamProvider.family<UserProfile, String>((ref, uid) {
  return ref.watch(profileRepositoryProvider).watchProfile(uid);
});
