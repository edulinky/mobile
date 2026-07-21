import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/extensions/l10n_extension.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/primary_button.dart';
import '../widgets/step_indicator.dart';

enum UserRole { student, teacher, institution }

class RegisterStep2Screen extends StatefulWidget {
  const RegisterStep2Screen({
    super.key,
    required this.email,
    required this.password,
    this.fullName = '',
    this.provider = '',
  });

  final String email;
  final String password;
  final String fullName;

  /// '' for the email/password flow, 'google' when the account was already
  /// created by Google sign-in (so step 3 skips account creation).
  final String provider;

  @override
  State<RegisterStep2Screen> createState() => _RegisterStep2ScreenState();
}

class _RegisterStep2ScreenState extends State<RegisterStep2Screen> {
  UserRole? _selected;

  void _next() {
    final role = _selected ?? UserRole.student;
    context.push('/register/3', extra: {
      'fullName': widget.fullName,
      'email':    widget.email,
      'password': widget.password,
      'role':     role.name,
      'provider': widget.provider,
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
            Center(child: StepIndicator(current: 2, total: 3)),
            const SizedBox(height: 20),
            Text(
              l10n.chooseYourRole,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800, color: AppColors.text),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.chooseYourRoleSubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.text2),
            ),
            const SizedBox(height: 28),
            _RoleCard(
              role: UserRole.student,
              selected: _selected == UserRole.student,
              icon: Icons.school_rounded,
              label: l10n.roleStudent,
              description: l10n.roleStudentDesc,
              onTap: () => setState(() => _selected = UserRole.student),
            ),
            const SizedBox(height: 12),
            _RoleCard(
              role: UserRole.teacher,
              selected: _selected == UserRole.teacher,
              icon: Icons.cast_for_education_rounded,
              label: l10n.roleTeacher,
              description: l10n.roleTeacherDesc,
              onTap: () => setState(() => _selected = UserRole.teacher),
            ),
            const SizedBox(height: 12),
            _RoleCard(
              role: UserRole.institution,
              selected: _selected == UserRole.institution,
              icon: Icons.account_balance_rounded,
              label: l10n.roleInstitution,
              description: l10n.roleInstitutionDesc,
              onTap: () => setState(() => _selected = UserRole.institution),
            ),
            const SizedBox(height: 28),
            PrimaryButton(
              label: '${l10n.next} →',
              onPressed: _next,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.selected,
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  final UserRole role;
  final bool selected;
  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: selected ? AppColors.sky.withValues(alpha:0.12) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected ? AppColors.skyDark : AppColors.skyLight,
          width: selected ? 2 : 1,
        ),
        boxShadow: selected
            ? [BoxShadow(color: AppColors.sky.withValues(alpha:0.2), blurRadius: 12, offset: const Offset(0, 4))]
            : [BoxShadow(color: Colors.black.withValues(alpha:0.04), blurRadius: 8)],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: selected ? AppColors.skyDark : AppColors.skyLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: selected ? Colors.white : AppColors.skyDark, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: selected ? AppColors.skyDark : AppColors.text)),
                    const SizedBox(height: 3),
                    Text(description,
                        style: TextStyle(fontSize: 13, color: AppColors.text2, height: 1.4)),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle_rounded, color: AppColors.skyDark, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
