import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/extensions/l10n_extension.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_controller.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/primary_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _submit() async {
    if (_loading) return;
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      _snack(context.l10n.errEnterEmailPassword);
      return;
    }
    setState(() => _loading = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .signIn(email: email, password: password);
      // The router's redirect guard moves us to the role home on success.
    } on FirebaseAuthException catch (e) {
      _snack(e.message ?? 'Sign in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _google() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final cred = await ref.read(authRepositoryProvider).signInWithGoogle();
      if (cred == null) return; // user dismissed the picker — no error
      // A returning user already has a role claim; the router's redirect guard
      // takes them home. A brand-new Google user has no role yet, so send them
      // into role selection with their Google name/email pre-filled — step 3
      // skips account creation since Google already made the account.
      final token = await cred.user?.getIdTokenResult();
      final hasRole = token?.claims?['role'] != null;
      if (!mounted || hasRole) return;
      context.push('/register/2', extra: {
        'provider': 'google',
        'fullName': cred.user?.displayName ?? '',
        'email': cred.user?.email ?? '',
        'password': '',
      });
    } on FirebaseAuthException catch (e) {
      _snack(e.message ?? context.l10n.errGoogleSignInFailed);
    } catch (_) {
      _snack(context.l10n.errGoogleSignInFailed);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final l10n = context.l10n;
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _snack(l10n.errForgotPasswordNoEmail);
      return;
    }
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(email);
      _snack(l10n.msgResetEmailSent(email));
    } on FirebaseAuthException catch (e) {
      _snack(e.message ?? 'Could not send reset email.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AuthScaffold(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Text(
              l10n.welcomeBack,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800, color: AppColors.text),
            ),
            const SizedBox(height: 6),
            Text(l10n.signInToContinue,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.text2)),
            const SizedBox(height: 32),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.emailAddress,
                prefixIcon: const Icon(Icons.mail_outline_rounded),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: l10n.password,
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _forgotPassword,
                child: Text(l10n.forgotPassword),
              ),
            ),
            const SizedBox(height: 8),
            PrimaryButton(label: l10n.signIn, onPressed: _submit, loading: _loading),
            const SizedBox(height: 16),
            Row(children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('or', style: TextStyle(color: AppColors.text3, fontSize: 13)),
              ),
              const Expanded(child: Divider()),
            ]),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.text,
                side: BorderSide(color: AppColors.skyLight),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              icon: const Icon(Icons.g_mobiledata_rounded, size: 24),
              label: Text(l10n.continueWithGoogle),
              onPressed: _loading ? null : _google,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(l10n.noAccount,
                    style: TextStyle(color: AppColors.text2, fontSize: 14)),
                TextButton(
                  onPressed: () => context.push('/register/1'),
                  child: Text(l10n.signUp),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
