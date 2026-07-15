import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/extensions/l10n_extension.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/primary_button.dart';
import '../widgets/step_indicator.dart';

class RegisterStep1Screen extends StatefulWidget {
  const RegisterStep1Screen({super.key});

  @override
  State<RegisterStep1Screen> createState() => _RegisterStep1ScreenState();
}

class _RegisterStep1ScreenState extends State<RegisterStep1Screen> {
  final _nameCtrl       = TextEditingController();
  final _emailCtrl      = TextEditingController();
  final _passwordCtrl   = TextEditingController();
  final _confirmCtrl    = TextEditingController();
  bool _obscurePass    = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _next() {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _snack(context.l10n.errFillNameEmailPassword);
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      _snack(context.l10n.errInvalidEmail);
      return;
    }
    if (password.length < 6) {
      _snack(context.l10n.errPasswordTooShort);
      return;
    }
    if (password != _confirmCtrl.text) {
      _snack(context.l10n.errPasswordsMismatch);
      return;
    }
    context.push('/register/2', extra: {
      'fullName': name,
      'email':    email,
      'password': password,
    });
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
            const SizedBox(height: 4),
            Center(child: StepIndicator(current: 1, total: 3)),
            const SizedBox(height: 20),
            Text(
              l10n.createAccount,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800, color: AppColors.text),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.stepOf(1, 3),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.text2),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _nameCtrl,
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.fullName,
                hintText: l10n.fullNameHint,
                prefixIcon: const Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 16),
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
              obscureText: _obscurePass,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.password,
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  onPressed: () => setState(() => _obscurePass = !_obscurePass),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmCtrl,
              obscureText: _obscureConfirm,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _next(),
              decoration: InputDecoration(
                labelText: l10n.confirmPassword,
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
            ),
            const SizedBox(height: 28),
            PrimaryButton(label: '${l10n.next} →', onPressed: _next),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(l10n.alreadyHaveAccount,
                    style: TextStyle(color: AppColors.text2, fontSize: 14)),
                TextButton(
                  onPressed: () => context.push('/login'),
                  child: Text(l10n.signIn),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
