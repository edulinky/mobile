import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../firebase/firebase_refs.dart';

/// The RevenueCat **public** SDK keys. Not secrets in the sense an API key is —
/// they identify the app and can only be used to buy things — but they still come
/// from `--dart-define-from-file=dart_defines.json` rather than the repo, because
/// keys in source get copied into places they should not be.
const _iosKey = String.fromEnvironment('REVENUECAT_IOS_KEY');
const _androidKey = String.fromEnvironment('REVENUECAT_ANDROID_KEY');

/// The entitlement configured in the RevenueCat dashboard. Every paid tier
/// (1/3/6/12 months) unlocks this **one** entitlement — the app asks "are they
/// premium?", never "which package did they buy?", so adding or repricing a tier
/// never touches the app.
const kPremiumEntitlement = 'premium';

/// RevenueCat: purchases, restores, and the current offering.
///
/// **It is not the source of truth about who is premium.** The RevenueCat webhook
/// writes `sub_status` on the user doc server-side, and *that* is what
/// `recordSwipe` enforces. This class exists to (a) show the real, localised
/// prices, (b) run the native payment sheet, and (c) tell the server to catch up
/// afterwards. A client that decided its own subscription state would be a client
/// with free unlimited swipes.
class PurchaseService {
  const PurchaseService();

  static bool get isConfigured =>
      (Platform.isIOS ? _iosKey : _androidKey).isNotEmpty;

  /// Call once at startup, and again whenever the signed-in user changes.
  ///
  /// The `appUserID` **must** be the Firebase uid: it is what arrives in the
  /// webhook as `app_user_id`, and it is the only thing tying a payment made on
  /// Apple's servers to an account on ours. Get this wrong and purchases land on
  /// an anonymous RevenueCat id that belongs to nobody.
  static Future<void> configure(String? uid) async {
    if (!isConfigured) return;
    try {
      await Purchases.setLogLevel(
          kDebugMode ? LogLevel.debug : LogLevel.error);
      await Purchases.configure(
        PurchasesConfiguration(Platform.isIOS ? _iosKey : _androidKey)
          ..appUserID = uid,
      );
    } catch (e) {
      debugPrint('RevenueCat configure failed: $e');
    }
  }

  /// Re-identify after sign-in / sign-out, so purchases follow the account.
  static Future<void> identify(String uid) async {
    if (!isConfigured) return;
    try {
      await Purchases.logIn(uid);
    } catch (e) {
      debugPrint('RevenueCat logIn failed: $e');
    }
  }

  static Future<void> signOut() async {
    if (!isConfigured) return;
    try {
      await Purchases.logOut();
    } catch (_) {
      // Logging out of RevenueCat is not worth failing a sign-out over.
    }
  }

  /// The packages to show on the paywall — prices come from the store, already
  /// localised and current. Hard-coded prices in the UI go stale the first time
  /// you run a promotion, and are simply wrong in every other currency.
  Future<List<Package>> packages() async {
    if (!isConfigured) return const [];
    final offerings = await Purchases.getOfferings();
    return offerings.current?.availablePackages ?? const [];
  }

  /// Runs the native payment sheet. Returns true if the user is now premium.
  ///
  /// A `PurchasesErrorCode.purchaseCancelledError` is not a failure — the user
  /// changed their mind — so it comes back as `false`, not an exception.
  Future<bool> purchase(Package package) async {
    final result = await Purchases.purchase(PurchaseParams.package(package));
    return _afterPurchase(result.customerInfo.entitlements.active);
  }

  /// Apple **requires** this (Guideline 3.1.1): someone who reinstalls, or signs
  /// in on a second device, must be able to get back what they paid for without
  /// paying again.
  Future<bool> restore() async {
    final info = await Purchases.restorePurchases();
    return _afterPurchase(info.entitlements.active);
  }

  Future<bool> _afterPurchase(Map<String, EntitlementInfo> active) async {
    final premium = active.containsKey(kPremiumEntitlement);
    if (!premium) return false;

    // The webhook is what actually grants premium, and it arrives
    // out-of-band — so force a token refresh to pick up the `isPremium` claim
    // (it would otherwise lag by up to an hour, and the user would have paid and
    // seen nothing change).
    try {
      await Fb.auth.currentUser?.getIdToken(true);
    } catch (_) {
      // The Firestore `sub_status` the app actually reads is a live stream, so a
      // failed refresh delays only the rules-gated writes, not the UI.
    }
    return true;
  }
}

final purchaseServiceProvider =
    Provider<PurchaseService>((ref) => const PurchaseService());

/// The live offering. `.family`-free: there is one offering for everyone.
final packagesProvider = FutureProvider<List<Package>>((ref) {
  return ref.watch(purchaseServiceProvider).packages();
});
