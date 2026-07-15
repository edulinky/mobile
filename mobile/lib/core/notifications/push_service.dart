import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../firebase/firebase_refs.dart';

/// Registers this device for push and keeps its FCM token on the user doc.
///
/// `onNewMessage` reads `users/{uid}.fcm_tokens` to notify the recipient of a
/// chat message. Tokens are stored as an array because one account can be signed
/// in on several devices; the server prunes dead ones when a send fails.
class PushService {
  const PushService();

  Future<void> registerForUser(String uid) async {
    try {
      final messaging = FirebaseMessaging.instance;

      // iOS requires explicit permission; a decline is not an error, it just
      // means no pushes.
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      // iOS needs an APNs token before FCM will mint one. A simulator never
      // gets one (APNs requires real hardware), so this is null in the sim and
      // getToken() would throw `apns-token-not-set`. That is expected, not an
      // error: push simply cannot be tested on a simulator.
      if (Platform.isIOS) {
        final apns = await messaging.getAPNSToken();
        if (apns == null) {
          debugPrint('[push] no APNs token (simulator?) — skipping FCM token');
          return;
        }
      }

      final token = await messaging.getToken();
      if (token != null) await _save(uid, token);

      // The token can rotate at any time (reinstall, restore, FCM's own
      // schedule). If we only saved it once, pushes would silently stop.
      messaging.onTokenRefresh.listen((t) => _save(uid, t));
    } catch (e) {
      // Push is a nice-to-have; never let it break sign-in.
      debugPrint('[push] registration failed: $e');
    }
  }

  Future<void> _save(String uid, String token) async {
    await Fb.users.doc(uid).update({
      'fcm_tokens': FieldValue.arrayUnion([token]),
    });
  }

  /// Drops this device's token on sign-out, so the next person to use the phone
  /// does not receive the previous user's messages.
  Future<void> unregister(String uid) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await Fb.users.doc(uid).update({
        'fcm_tokens': FieldValue.arrayRemove([token]),
      });
    } catch (e) {
      debugPrint('[push] unregister failed: $e');
    }
  }
}

const pushService = PushService();
