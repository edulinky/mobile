import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/widgets/avatar_image.dart';
import '../../../core/widgets/bottom_nav.dart';
import '../../../core/widgets/city_picker_screen.dart';
import '../../../core/widgets/photo_crop_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/extensions/l10n_extension.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/models/user_profile.dart';

/// An institution's own public info: org name, description, city, website,
/// contact email, logo. Shown to teachers via job cards (`institution_name` /
/// `institution_logo_url`, copied from these fields at post time) and — once
/// they've applied and been connected with — in chat.
class InstitutionProfileScreen extends ConsumerWidget {
  const InstitutionProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final profile = ref.watch(myProfileProvider);
    return Scaffold(
      backgroundColor: AppColors.skyBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Text(l10n.institutionProfileTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800, color: AppColors.text)),
                ],
              ),
            ),
            Expanded(
              child: profile.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(l10n.errLoadProfile('$e'),
                        textAlign: TextAlign.center),
                  ),
                ),
                // Keyed on the doc's own field, so a save elsewhere does not
                // silently reset the form the institution is mid-editing.
                data: (p) => _Form(key: ValueKey(p.uid), profile: p),
              ),
            ),
            const BottomNav(currentIndex: 2, role: NavRole.institution),
          ],
        ),
      ),
    );
  }
}

class _Form extends ConsumerStatefulWidget {
  const _Form({super.key, required this.profile});

  final UserProfile profile;

  @override
  ConsumerState<_Form> createState() => _FormState();
}

class _FormState extends ConsumerState<_Form> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _websiteCtrl;
  late final TextEditingController _emailCtrl;

  Uint8List? _newLogo;
  String? _cityLabel;
  bool _saving = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameCtrl = TextEditingController(text: p.displayName);
    _descCtrl = TextEditingController(text: p.about);
    _websiteCtrl = TextEditingController(text: p.website);
    _emailCtrl = TextEditingController(text: p.contactEmail);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _websiteCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pickLogo() async {
    final l10n = context.l10n;
    final file =
        await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 95);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    final cropped = await PhotoCropScreen.push(context, bytes);
    if (cropped == null) return;

    // Upload immediately, same as everywhere else a profile photo is set —
    // holding it until "Save Profile" would silently drop it if the user left
    // the screen first.
    setState(() {
      _newLogo = cropped;
      _saving = true;
    });
    try {
      await ref.read(profileRepositoryProvider).setAvatar(cropped);
    } catch (e) {
      if (mounted) setState(() => _newLogo = null);
      _snack(l10n.errSaveProfile('$e'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickCity() async {
    final l10n = context.l10n;
    final picked = await CityPickerScreen.push(context);
    if (picked == null) return;
    setState(() => _saving = true);
    try {
      // Server-derived geohash — this is also what makes the institution's job
      // cards findable, so it goes through the same callable as everyone else's
      // location, never a raw client write.
      await ref.read(profileRepositoryProvider).setCity(picked);
      if (mounted) setState(() => _cityLabel = picked.city);
    } catch (e) {
      _snack(l10n.errUpdateCity('$e'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    // Tapping Save while a field is still focused otherwise leaves the
    // keyboard covering the screen after the request completes.
    FocusScope.of(context).unfocus();
    final l10n = context.l10n;
    setState(() {
      _saving = true;
      _saved = false;
    });
    try {
      await ref.read(profileRepositoryProvider).updateProfile(
            displayName: _nameCtrl.text.trim(),
            about: _descCtrl.text.trim(),
            website: _websiteCtrl.text.trim(),
            contactEmail: _emailCtrl.text.trim(),
          );
    } catch (e) {
      if (mounted) setState(() => _saving = false);
      _snack(l10n.errSaveProfile('$e'));
      return;
    }
    if (!mounted) return;
    setState(() {
      _saving = false;
      _saved = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _saved = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final city = _cityLabel ?? widget.profile.geoLocation?.city ?? '';
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        children: [
          _buildLogoSection(),
          const SizedBox(height: 24),
          _buildFormCard(context, l10n, city),
          const SizedBox(height: 24),
          _buildSaveButton(context, l10n),
        ],
      ),
    );
  }

  Widget _buildLogoSection() {
    return Center(
      child: GestureDetector(
        onTap: _pickLogo,
        child: Stack(
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.skyLight,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.sky, width: 2),
              ),
              clipBehavior: Clip.hardEdge,
              child: _newLogo != null
                  ? Image.memory(_newLogo!, fit: BoxFit.cover)
                  : (widget.profile.photoUrl.isNotEmpty
                      ? AvatarImage(url: widget.profile.photoUrl)
                      : const Icon(Icons.account_balance_rounded,
                          size: 40, color: AppColors.skyDark)),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.skyDark,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard(BuildContext context, dynamic l10n, String city) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
      ),
      child: Column(
        children: [
          TextFormField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l10n.institutionName,
              hintText: l10n.institutionNameHint,
              prefixIcon: const Icon(Icons.account_balance_outlined),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: l10n.institutionDescription,
              hintText: l10n.institutionDescriptionHint,
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 44),
                child: Icon(Icons.notes_rounded),
              ),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _pickCity,
            borderRadius: BorderRadius.circular(14),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: l10n.cityLocation,
                prefixIcon: const Icon(Icons.location_on_outlined),
                suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
              ),
              child: Text(
                city.isEmpty ? l10n.cityLocationHint : city,
                style: TextStyle(
                    fontSize: 16,
                    color: city.isEmpty ? AppColors.text3 : AppColors.text),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _websiteCtrl,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              labelText: l10n.institutionWebsite,
              hintText: l10n.institutionWebsiteHint,
              prefixIcon: const Icon(Icons.language_outlined),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: l10n.contactEmail,
              prefixIcon: const Icon(Icons.mail_outline_rounded),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context, dynamic l10n) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: _saved
          ? Container(
              key: const ValueKey('saved'),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF065F46),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(context.l10n.savedExclamation,
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                ],
              ),
            )
          : SizedBox(
              key: const ValueKey('save'),
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  elevation: 0,
                ),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(l10n.saveProfile),
              ),
            ),
    );
  }
}
