import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/extensions/l10n_extension.dart';
import '../../../core/places/places_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/city_picker_screen.dart';
import '../../../core/widgets/photo_crop_screen.dart';
import '../../profile/data/profile_repository.dart';
import '../providers/auth_controller.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/primary_button.dart';
import '../widgets/step_indicator.dart';

class RegisterStep3Screen extends ConsumerStatefulWidget {
  const RegisterStep3Screen({super.key, required this.registrationData});

  final Map<String, String> registrationData;

  @override
  ConsumerState<RegisterStep3Screen> createState() => _RegisterStep3ScreenState();
}

class _RegisterStep3ScreenState extends ConsumerState<RegisterStep3Screen> {
  late final TextEditingController _nameCtrl;
  final _subjectCtrl  = TextEditingController();
  SelectedCity? _city;
  Uint8List? _avatarBytes;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
      text: widget.registrationData['fullName'] ?? '',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _subjectCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final file = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 95);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    // Let the user pan/zoom to frame the photo before we keep it.
    final cropped = await PhotoCropScreen.push(context, bytes);
    if (cropped != null) setState(() => _avatarBytes = cropped);
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _submit() async {
    if (_loading) return;
    final l10n = context.l10n;
    final data = widget.registrationData;
    final role = data['role'] ?? 'student';
    final email = data['email'] ?? '';
    final password = data['password'] ?? '';
    // In the Google flow the account already exists (and the user is signed in),
    // so there is no password and we skip account creation below.
    final isGoogle = (data['provider'] ?? '') == 'google';
    final displayName = _nameCtrl.text.trim();
    if (!isGoogle && (email.isEmpty || password.isEmpty)) {
      _snack(l10n.errRestartRegistration);
      return;
    }
    if (_city == null) {
      _snack(l10n.errSelectCity);
      return;
    }

    setState(() => _loading = true);
    final repo = ref.read(authRepositoryProvider);

    // 1) Create the Firebase Auth account (also signs the user in). Skipped for
    //    Google, where sign-in already created and authenticated the account.
    if (!isGoogle) {
      try {
        await repo.createAccount(email: email, password: password);
      } on FirebaseAuthException catch (e) {
        _snack(e.message ?? 'Could not create your account.');
        if (mounted) setState(() => _loading = false);
        return;
      }
    }

    // 2) Set the role claim + write the user doc. On failure, roll back the
    //    half-created account so the user can retry cleanly.
    try {
      await repo.completeRegistration(
        role: role,
        displayName: displayName,
        city: _city!.city,
        lat: _city!.lat,
        lng: _city!.lng,
        placeId: _city!.placeId,
        primarySubject: _subjectCtrl.text.trim(),
      );
    } catch (e) {
      await repo.deleteCurrentUser();
      _snack(l10n.errFinishSetup);
      if (mounted) setState(() => _loading = false);
      return;
    }

    // 3) Upload the cropped avatar. Deliberately non-fatal: the account is
    //    already usable, so a failed photo upload must not strand the user on
    //    the registration screen — they can set it later from profile edit.
    if (_avatarBytes != null) {
      try {
        await ref.read(profileRepositoryProvider).setAvatar(_avatarBytes!);
      } catch (e) {
        debugPrint('[register] avatar upload failed: $e');
        _snack(l10n.warnAvatarUploadFailed);
      }
    }

    if (!mounted) return;
    if (role == 'teacher') {
      context.go('/cert-upload');
    } else if (role == 'institution') {
      context.go('/institution/paywall');
    } else {
      context.go('/student/discover');
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
            const SizedBox(height: 4),
            Center(child: StepIndicator(current: 3, total: 3)),
            const SizedBox(height: 20),
            Text(
              l10n.setUpProfile,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800, color: AppColors.text),
            ),
            const SizedBox(height: 6),
            Text(l10n.stepOf(3, 3),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.text2)),
            const SizedBox(height: 28),
            Center(
              child: GestureDetector(
                onTap: _pickPhoto,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 54,
                      backgroundColor: AppColors.skyLight,
                      backgroundImage: _avatarBytes != null ? MemoryImage(_avatarBytes!) : null,
                      child: _avatarBytes == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.camera_alt_outlined, size: 28, color: AppColors.skyDark),
                                const SizedBox(height: 4),
                                Text(l10n.addProfilePhoto,
                                    style: const TextStyle(fontSize: 10, color: AppColors.skyDark, fontWeight: FontWeight.w600),
                                    textAlign: TextAlign.center),
                              ],
                            )
                          : null,
                    ),
                    if (_avatarBytes != null)
                      Positioned(
                        bottom: 0, right: 0,
                        child: Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.skyDark,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.displayName,
                hintText: l10n.displayNameHint,
                prefixIcon: const Icon(Icons.badge_rounded),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final picked = await CityPickerScreen.push(context);
                if (picked != null) setState(() => _city = picked);
              },
              borderRadius: BorderRadius.circular(14),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.cityLocation,
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
                ),
                child: Text(
                  _city?.city ?? l10n.cityLocationHint,
                  style: TextStyle(
                    fontSize: 16,
                    color: _city == null ? AppColors.text3 : AppColors.text,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _subjectCtrl,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: l10n.primarySubject,
                hintText: l10n.primarySubjectHint,
                prefixIcon: const Icon(Icons.menu_book_outlined),
              ),
            ),
            const SizedBox(height: 28),
            PrimaryButton(label: l10n.createAccountBtn, onPressed: _submit, loading: _loading),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
