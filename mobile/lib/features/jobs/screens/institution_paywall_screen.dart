import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/extensions/l10n_extension.dart';

class InstitutionPaywallScreen extends StatefulWidget {
  const InstitutionPaywallScreen({super.key});

  @override
  State<InstitutionPaywallScreen> createState() => _InstitutionPaywallScreenState();
}

class _InstitutionPaywallScreenState extends State<InstitutionPaywallScreen> {
  int _selectedPlan = 3; // default to yearly
  bool _loading = false;

  static const _plans = [
    (label: 'Monthly',  price: r'$4.99',  period: '/mo',  saving: ''),
    (label: '3 Months', price: r'$12.99',  period: '/3mo', saving: 'Save 13%'),
    (label: '6 Months', price: r'$22.99', period: '/6mo', saving: 'Save 27%'),
    (label: 'Yearly',   price: r'$39.99', period: '/yr',  saving: 'Best Value'),
  ];

  void _subscribe() async {
    setState(() => _loading = true);
    // TODO: call RevenueCat purchasePackage
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _loading = false);
      context.go('/institution/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF052E16), Color(0xFF065F46), Color(0xFF0369A1)],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, l10n),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      _buildFeatureList(context, l10n),
                      const SizedBox(height: 28),
                      _buildPlanPicker(context, l10n),
                      const SizedBox(height: 28),
                      _buildSubscribeButton(l10n),
                      const SizedBox(height: 12),
                      Text(l10n.cancelAnytime,
                          style: const TextStyle(color: Colors.white38, fontSize: 12)),
                      const SizedBox(height: 32),
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

  Widget _buildHeader(BuildContext context, dynamic l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white24, width: 1.5),
          ),
          child: const Icon(Icons.account_balance_rounded, size: 36, color: Colors.white),
        ),
        const SizedBox(height: 18),
        Text(l10n.paywallTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, height: 1.2)),
        const SizedBox(height: 10),
        Text(l10n.paywallSubtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60, fontSize: 15, height: 1.5)),
      ]),
    );
  }

  Widget _buildFeatureList(BuildContext context, dynamic l10n) {
    final features = [
      (Icons.work_rounded,             l10n.paywallFeatureJobs),
      (Icons.verified_user_rounded,    l10n.paywallFeatureBrowse),
      (Icons.chat_bubble_rounded,      l10n.paywallFeatureMessaging),
      (Icons.star_rounded,             l10n.paywallFeatureFeatured),
    ];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: features.map((f) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(f.$1, color: const Color(0xFF6EE7B7), size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(f.$2,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500))),
            const Icon(Icons.check_circle_rounded, color: Color(0xFF6EE7B7), size: 18),
          ]),
        )).toList(),
      ),
    );
  }

  Widget _buildPlanPicker(BuildContext context, dynamic l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.choosePlan,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.5,
          children: List.generate(_plans.length, (i) {
            final plan = _plans[i];
            final selected = _selectedPlan == i;
            return GestureDetector(
              onTap: () => setState(() => _selectedPlan = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.95)
                      : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected ? Colors.white : Colors.white24,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (plan.saving.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: selected ? const Color(0xFF059669) : const Color(0xFF6EE7B7).withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(plan.saving,
                            style: TextStyle(
                                fontSize: 10, fontWeight: FontWeight.w700,
                                color: selected ? Colors.white : const Color(0xFF6EE7B7))),
                      )
                    else
                      const SizedBox.shrink(),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(plan.price,
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w900,
                              color: selected ? const Color(0xFF0C2A4A) : Colors.white)),
                      Text(plan.label + plan.period,
                          style: TextStyle(
                              fontSize: 11,
                              color: selected ? const Color(0xFF0C2A4A).withValues(alpha: 0.6) : Colors.white38)),
                    ]),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSubscribeButton(dynamic l10n) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF065F46),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        onPressed: _loading ? null : _subscribe,
        child: _loading
            ? const SizedBox(width: 22, height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF065F46)))
            : Text(l10n.startSubscription),
      ),
    );
  }
}
