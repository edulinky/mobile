import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/extensions/l10n_extension.dart';
import '../../../core/purchases/purchase_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_controller.dart';

/// The paywall, for students and teachers.
///
/// Prices are **not** hard-coded: they come from the store through RevenueCat,
/// already localised and current. A `$4.99` typed into the app is wrong in every
/// other currency, and stale the first time you run a promotion.
///
/// Apple requires a paywall to state what is being sold, for how long, at what
/// price, and to offer **Restore Purchases** plus links to Terms and Privacy
/// (Guideline 3.1.1 / 3.1.2). Missing any of those is a rejection.
class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  Package? _selected;
  bool _busy = false;

  Future<void> _buy() async {
    final package = _selected;
    if (package == null || _busy) return;
    setState(() => _busy = true);
    try {
      final ok = await ref.read(purchaseServiceProvider).purchase(package);
      if (!mounted) return;
      if (ok) _done(context.l10n.premiumThanks);
    } on PlatformException catch (e) {
      // Cancelling is not an error — the user changed their mind.
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) return;
      _fail('${e.message}');
    } catch (e) {
      _fail('$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final ok = await ref.read(purchaseServiceProvider).restore();
      if (!mounted) return;
      ok ? _done(context.l10n.premiumRestored) : _fail(context.l10n.premiumNothingToRestore);
    } catch (e) {
      _fail('$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _done(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
    Navigator.of(context).pop();
  }

  void _fail(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isTeacher = ref.watch(authStateProvider).valueOrNull?.role == 'teacher';
    final packages = ref.watch(packagesProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E3A8A), Color(0xFF0369A1), Color(0xFF0EA5E9)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.workspace_premium_rounded,
                          size: 56, color: Colors.white),
                      const SizedBox(height: 12),
                      Text(l10n.upgradeToPremium,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900)),
                      const SizedBox(height: 20),
                      _benefit(Icons.all_inclusive_rounded, l10n.benefitUnlimitedSwipes),
                      if (isTeacher)
                        _benefit(Icons.star_rounded, l10n.benefitFeaturedBadge),
                      _benefit(Icons.bolt_rounded, l10n.benefitPriorityDiscovery),
                      const SizedBox(height: 24),
                      packages.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                              child: CircularProgressIndicator(
                                  color: Colors.white)),
                        ),
                        error: (e, _) => _Unavailable(message: l10n.premiumUnavailable),
                        data: (list) {
                          if (list.isEmpty) {
                            return _Unavailable(message: l10n.premiumUnavailable);
                          }
                          _selected ??= list.first;
                          return Column(
                            children: [
                              for (final p in list)
                                _PlanTile(
                                  package: p,
                                  selected: identical(p, _selected) ||
                                      p.identifier == _selected?.identifier,
                                  onTap: () => setState(() => _selected = p),
                                ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _busy ? null : _buy,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.skyDeeper,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                ),
                                child: _busy
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2))
                                    : Text(l10n.subscribeBtn,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w800)),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _busy ? null : _restore,
                        style: TextButton.styleFrom(
                            foregroundColor: Colors.white70),
                        child: Text(l10n.restorePurchases),
                      ),
                      const SizedBox(height: 4),
                      // Required by both stores: the subscription terms, in
                      // words, before the money is taken.
                      Text(l10n.subscriptionTerms,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 11, height: 1.5)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _link(l10n.termsOfService, kTermsUrl),
                          const Text('  ·  ',
                              style: TextStyle(color: Colors.white38)),
                          _link(l10n.privacyPolicy, kPrivacyUrl),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _benefit(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: const TextStyle(color: Colors.white, fontSize: 15)),
          ),
        ],
      ),
    );
  }

  Widget _link(String label, String url) {
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse(url),
          mode: LaunchMode.externalApplication),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              decoration: TextDecoration.underline)),
    );
  }
}

/// Public, and required by the stores before a subscription can ship.
const kTermsUrl = 'https://edulinky.com/terms';
const kPrivacyUrl = 'https://edulinky.com/privacy';

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.package,
    required this.selected,
    required this.onTap,
  });

  final Package package;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final product = package.storeProduct;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: selected ? 0.22 : 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? Colors.white : Colors.white24,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // The store's own title and price — localised, current, and
                    // not our problem to keep in sync.
                    Text(product.title.replaceAll(RegExp(r'\s*\(.*\)$'), ''),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                    if (product.description.isNotEmpty)
                      Text(product.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 12)),
                  ],
                ),
              ),
              Text(product.priceString,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 13)),
    );
  }
}
