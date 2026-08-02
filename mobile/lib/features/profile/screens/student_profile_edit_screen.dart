import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/widgets/bottom_nav.dart';
import '../../../core/widgets/city_picker_screen.dart';
import '../../../core/widgets/photo_crop_screen.dart';
import '../../../core/constants/subjects.dart';
import '../../../core/widgets/subject_selector.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/extensions/l10n_extension.dart';
import '../../auth/widgets/primary_button.dart';
import '../data/profile_repository.dart';
import '../models/user_profile.dart';

class StudentProfileEditScreen extends ConsumerWidget {
  const StudentProfileEditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(myProfileProvider);
    return Scaffold(
      backgroundColor: AppColors.skyBg,
      body: SafeArea(
        bottom: false,
        child: profile.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(context.l10n.errLoadProfile('$e'),
                  textAlign: TextAlign.center),
            ),
          ),
          // Keyed on uid so the form state resets if the signed-in user changes.
          data: (p) => _StudentProfileForm(key: ValueKey(p.uid), profile: p),
        ),
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 2),
    );
  }
}

class _StudentProfileForm extends ConsumerStatefulWidget {
  const _StudentProfileForm({super.key, required this.profile});

  final UserProfile profile;

  @override
  ConsumerState<_StudentProfileForm> createState() => _StudentProfileFormState();
}

class _StudentProfileFormState extends ConsumerState<_StudentProfileForm> {

  late final TextEditingController _nameCtrl;
  late final TextEditingController _aboutCtrl;
  late final Set<String> _selectedSubjects;

  Uint8List? _newAvatar; // picked this session, not yet saved
  String? _cityLabel; // set when the user picks a new city
  bool _saving = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameCtrl = TextEditingController(text: p.displayName);
    _aboutCtrl = TextEditingController(text: p.about);
    _selectedSubjects = {...p.subjects};
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _aboutCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final l10n = context.l10n;
    final file = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 95);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    final cropped = await PhotoCropScreen.push(context, bytes);
    if (cropped == null) return;

    // Upload immediately — waiting for "Save changes" meant a picked photo was
    // silently lost if the user navigated away first.
    setState(() {
      _newAvatar = cropped;
      _saving = true;
    });
    try {
      await ref.read(profileRepositoryProvider).setAvatar(cropped);
    } catch (e) {
      if (mounted) setState(() => _newAvatar = null);
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
      // Goes straight through — the server recomputes the geohash, and the
      // profile stream reflects it. No "save" needed for this one.
      await ref.read(profileRepositoryProvider).setCity(picked);
      if (mounted) setState(() => _cityLabel = picked.city);
    } catch (e) {
      _snack(l10n.errUpdateCity('$e'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
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
    final repo = ref.read(profileRepositoryProvider);
    try {
      // The avatar is already uploaded on pick.
      await repo.updateProfile(
        displayName: _nameCtrl.text.trim(),
        about: _aboutCtrl.text.trim(),
        subjects: _selectedSubjects.toList(),
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
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _saved = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = widget.profile;
    final city = _cityLabel ?? p.geoLocation?.city ?? '';
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Text(l10n.myProfile,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800, color: AppColors.text)),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: _avatar(p)),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: l10n.displayName,
                    prefixIcon: const Icon(Icons.badge_rounded),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _aboutCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: l10n.aboutMe,
                    hintText: l10n.aboutMeHint,
                    alignLabelWithHint: true,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 60),
                      child: Icon(Icons.notes_rounded),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                InkWell(
                  onTap: _saving ? null : _pickCity,
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
                        color: city.isEmpty ? AppColors.text3 : AppColors.text,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _subjects(context, l10n),
                const SizedBox(height: 28),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _saved
                      ? _SavedBanner(
                          key: const ValueKey('saved'), label: l10n.saved)
                      : PrimaryButton(
                          key: const ValueKey('btn'),
                          label: l10n.saveChanges,
                          onPressed: _save,
                          loading: _saving,
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _avatar(UserProfile p) {
    final ImageProvider? image = _newAvatar != null
        ? MemoryImage(_newAvatar!)
        : (p.photoUrl.isNotEmpty ? NetworkImage(p.photoUrl) : null);
    return GestureDetector(
      onTap: _pickPhoto,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 52,
            backgroundColor: AppColors.skyLight,
            backgroundImage: image,
            child: image == null
                ? const Icon(Icons.camera_alt_outlined,
                    size: 28, color: AppColors.skyDark)
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.skyDark,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.camera_alt_rounded,
                  size: 15, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _subjects(BuildContext context, dynamic l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.subjectsInterested,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700, color: AppColors.text)),
        const SizedBox(height: 12),
        SubjectSelector(
          presets: kSubjectPresets,
          selected: _selectedSubjects,
          onChanged: (next) => setState(() {
            _selectedSubjects
              ..clear()
              ..addAll(next);
          }),
        ),
      ],
    );
  }
}

class _SavedBanner extends StatelessWidget {
  const _SavedBanner({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A)),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF16A34A), fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
