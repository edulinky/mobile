import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/extensions/l10n_extension.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/firebase/firebase_refs.dart';
import '../../../core/notifications/push_service.dart';
import '../../../core/purchases/purchase_service.dart';
import '../providers/auth_controller.dart';

/// Signs the user out, after confirming.
///
/// Shared by all three settings screens so there is exactly one sign-out path.
/// No navigation here: `authStateProvider` emits null, and the router's redirect
/// guard sends the user back to `/`.
Future<void> confirmSignOut(BuildContext context, WidgetRef ref) async {
  final l10n = context.l10n;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.signOut),
      content: Text(l10n.signOutConfirm),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l10n.signOut,
              style: const TextStyle(
                  color: AppColors.error, fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
  if (confirmed != true) return;

  // Drop this device's push token BEFORE signing out — afterwards we no longer
  // know whose doc to remove it from, and the next person to use the phone would
  // receive the previous user's messages.
  final uid = Fb.auth.currentUser?.uid;
  if (uid != null) await pushService.unregister(uid);

  // Same reasoning for purchases: the next person to sign in on this phone must
  // not inherit the previous user's subscription.
  await PurchaseService.signOut();

  await ref.read(authRepositoryProvider).signOut();
}
