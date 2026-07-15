import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Shared singletons for Firebase services, so features import one place instead
/// of reaching for `FirebaseFirestore.instance` etc. directly.
class Fb {
  Fb._();

  static FirebaseAuth get auth => FirebaseAuth.instance;
  static FirebaseFirestore get db => FirebaseFirestore.instance;
  static FirebaseStorage get storage => FirebaseStorage.instance;
  static FirebaseFunctions get functions => FirebaseFunctions.instance;

  // Common collection references (expanded as the schema lands in Phase 3+).
  static CollectionReference<Map<String, dynamic>> get users =>
      db.collection('users');
}
