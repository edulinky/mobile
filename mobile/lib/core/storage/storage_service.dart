import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../firebase/firebase_refs.dart';

/// Uploads user media to Firebase Storage. Paths mirror `storage.rules`:
/// `avatars/{uid}/…` and `gallery/{uid}/…` are readable by signed-in users;
/// `certs/{uid}/…` is write-only from the client (admins read it server-side).
class StorageService {
  const StorageService();

  /// Uploads the cropped profile photo and returns its public download URL.
  Future<String> uploadAvatar({
    required String uid,
    required Uint8List bytes,
  }) async {
    final ref = Fb.storage.ref('avatars/$uid/profile.jpg');
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  /// Uploads a gallery photo and returns its **storage path**. The path (not a
  /// URL) is what gets stored on the user doc, so the server can verify the
  /// photo really is ours — see the `addGalleryPhoto` callable.
  Future<String> uploadGalleryPhoto({
    required String uid,
    required Uint8List bytes,
  }) async {
    final path = 'gallery/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg';
    await Fb.storage
        .ref(path)
        .putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return path;
  }

  /// Uploads one certificate document and returns its **storage path** — not a
  /// download URL, because the file is deliberately unreadable from clients.
  ///
  /// [fileName] is kept in the path so an admin reviewing the submission can see
  /// what each document claims to be ("PGCE.pdf" beats "1736…").
  Future<String> uploadCertificate({
    required String uid,
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final safeName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final path = 'certs/$uid/${stamp}_$safeName';
    await Fb.storage
        .ref(path)
        .putData(bytes, SettableMetadata(contentType: contentType));
    return path;
  }
}

final storageServiceProvider = Provider<StorageService>((ref) {
  return const StorageService();
});
