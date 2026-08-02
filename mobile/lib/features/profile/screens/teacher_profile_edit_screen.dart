import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/widgets/bottom_nav.dart';
import '../../../core/widgets/city_picker_screen.dart';
import '../../../core/widgets/currency_picker_field.dart';
import '../../../core/money/currency.dart';
import '../../../core/widgets/photo_crop_screen.dart';
import '../../../core/constants/subjects.dart';
import '../../../core/widgets/subject_selector.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/extensions/l10n_extension.dart';
import '../../auth/widgets/primary_button.dart';
import '../data/profile_repository.dart';
import '../models/user_profile.dart';

class TeacherProfileEditScreen extends ConsumerStatefulWidget {
  const TeacherProfileEditScreen({super.key});

  @override
  ConsumerState<TeacherProfileEditScreen> createState() =>
      _TeacherProfileEditScreenState();
}

class _TeacherProfileEditScreenState
    extends ConsumerState<TeacherProfileEditScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final profile = ref.watch(myProfileProvider);
    return Scaffold(
      backgroundColor: AppColors.skyBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(context, l10n),
            _buildTabBar(context, l10n),
            Expanded(
              child: profile.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(context.l10n.errLoadProfile('$e'),
                        textAlign: TextAlign.center),
                  ),
                ),
                // Each tab seeds its form controllers from the profile in
                // initState, so they are keyed on the doc's own fields — a save
                // elsewhere must not silently reset a tab the user is editing.
                data: (p) => TabBarView(
                  controller: _tabs,
                  children: [
                    _BioTab(key: ValueKey('bio-${p.uid}'), profile: p),
                    _GalleryTab(key: ValueKey('gallery-${p.uid}'), profile: p),
                    _QualificationsTab(
                        key: ValueKey('quals-${p.qualifications.length}'),
                        profile: p),
                    _ExperienceTab(
                        key: ValueKey('exp-${p.experience.length}'), profile: p),
                    _ScheduleTab(
                        key: ValueKey('sched-${p.uid}'), l10n: l10n, profile: p),
                    _VideosTab(
                        key: ValueKey('videos-${p.videoLinks.length}'),
                        profile: p),
                  ],
                ),
              ),
            ),
            const BottomNav(currentIndex: 2, role: NavRole.teacher),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Text(l10n.myProfile,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800, color: AppColors.text)),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context, dynamic l10n) {
    final labels = [
      l10n.tabBio,
      l10n.tabGallery,
      l10n.tabQualifications,
      l10n.tabExperience,
      l10n.tabSchedule,
      l10n.tabVideos,
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 0, 0),
      child: SizedBox(
        height: 36,
        // Rebuild on tab change: each Tab paints its own fill, so it needs to
        // know whether it is the selected one.
        child: AnimatedBuilder(
          animation: _tabs,
          builder: (context, _) => TabBar(
            controller: _tabs,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            // No indicator: TabBarIndicatorSize.tab paints across the tab
            // *including* its label padding, so the selected fill came out wider
            // than the unselected one. Each tab paints its own background
            // instead, giving both states identical geometry — same rule the
            // subject chips follow.
            indicator: const BoxDecoration(),
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.text2,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            unselectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            padding: EdgeInsets.zero,
            labelPadding: const EdgeInsets.only(right: 8),
            tabs: [
              for (var i = 0; i < labels.length; i++)
                _tab(labels[i], selected: _tabs.index == i),
            ],
          ),
        ),
      ),
    );
  }

  /// Both states share identical padding and radius — only the fill and the text
  /// colour change, so selecting a tab never resizes it.
  Tab _tab(String label, {required bool selected}) => Tab(
        height: 36,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.skyDark
                : AppColors.skyLight.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label),
        ),
      );
}

// ── Bio Tab ────────────────────────────────────────────────────────────────────

class _BioTab extends ConsumerStatefulWidget {
  const _BioTab({super.key, required this.profile});

  final UserProfile profile;

  @override
  ConsumerState<_BioTab> createState() => _BioTabState();
}

class _BioTabState extends ConsumerState<_BioTab> {

  late final TextEditingController _nameCtrl;
  late final TextEditingController _aboutCtrl;
  late final TextEditingController _rateCtrl;
  late final Set<String> _selectedSubjects;
  late Currency _currency;

  Uint8List? _newAvatar;
  String? _cityLabel;
  bool _saving = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameCtrl = TextEditingController(text: p.displayName);
    _aboutCtrl = TextEditingController(text: p.about);
    _rateCtrl = TextEditingController(text: p.hourlyRate?.toString() ?? '');
    _selectedSubjects = {...p.subjects};
    _currency = p.currency;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _aboutCtrl.dispose();
    _rateCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
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

    // Upload immediately, exactly like a gallery photo. Holding the bytes until
    // "Save changes" silently threw the picture away if the user switched tabs.
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
    final repo = ref.read(profileRepositoryProvider);
    try {
      // The avatar is already uploaded on pick — nothing to do for it here.
      await repo.updateProfile(
        displayName: _nameCtrl.text.trim(),
        about: _aboutCtrl.text.trim(),
        subjects: _selectedSubjects.toList(),
        hourlyRate: num.tryParse(_rateCtrl.text.trim()),
        currency: _currency,
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
    final ImageProvider? avatar = _newAvatar != null
        ? MemoryImage(_newAvatar!)
        : (p.photoUrl.isNotEmpty ? NetworkImage(p.photoUrl) : null);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(
          child: GestureDetector(
            onTap: _pickPhoto,
            child: Stack(children: [
              CircleAvatar(
                radius: 52,
                backgroundColor: AppColors.skyLight,
                backgroundImage: avatar,
                child: avatar == null
                    ? const Icon(Icons.camera_alt_outlined,
                        size: 28, color: AppColors.skyDark)
                    : null,
              ),
              Positioned(
                bottom: 0, right: 0,
                child: Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.skyDark, shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, size: 15, color: Colors.white),
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _nameCtrl,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: l10n.displayName,
            prefixIcon: const Icon(Icons.badge_rounded),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _aboutCtrl,
          maxLines: 5,
          decoration: InputDecoration(
            labelText: l10n.aboutMe,
            hintText: l10n.aboutMeTeacherHint,
            alignLabelWithHint: true,
            prefixIcon: const Padding(
              padding: EdgeInsets.only(bottom: 80),
              child: Icon(Icons.notes_rounded),
            ),
          ),
        ),
        const SizedBox(height: 16),
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
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: _rateCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: l10n.hourlyRate,
                  hintText: l10n.hourlyRateHint,
                  // The symbol tracks the selected currency, never a literal
                  // '$' — that is the seam for adding currencies later.
                  prefixText: '${_currency.symbol} ',
                  prefixIcon: const Icon(Icons.payments_outlined),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: CurrencyPickerField(
                value: _currency,
                enabled: !_saving,
                onChanged: (c) => setState(() => _currency = c),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(l10n.subjectsITeach,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
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
        const SizedBox(height: 28),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _saved
              ? _SavedBanner(key: const ValueKey('saved'), label: l10n.saved)
              : PrimaryButton(key: const ValueKey('btn'), label: l10n.saveChanges,
                  onPressed: _save, loading: _saving),
        ),
      ]),
    );
  }
}

// ── Gallery Tab ────────────────────────────────────────────────────────────────

class _GalleryTab extends ConsumerStatefulWidget {
  const _GalleryTab({super.key, required this.profile});

  final UserProfile profile;

  @override
  ConsumerState<_GalleryTab> createState() => _GalleryTabState();
}

class _GalleryTabState extends ConsumerState<_GalleryTab> {
  static const _maxPhotos = 6;
  bool _busy = false;

  List<String> get _paths => widget.profile.gallery;

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _addPhoto() async {
    if (_busy || _paths.length >= _maxPhotos) return;
    final l10n = context.l10n;
    final file = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    // Square frame, not the avatar's circle — gallery tiles are rendered as
    // rounded squares, so that is the shape the user must get to frame.
    final cropped = await PhotoCropScreen.push(context, bytes, circle: false);
    if (cropped == null) return;

    setState(() => _busy = true);
    try {
      await ref.read(profileRepositoryProvider).addGalleryPhoto(cropped);
    } catch (e) {
      _snack(l10n.errAddPhoto('$e'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(String path) async {
    if (_busy) return;
    final l10n = context.l10n;
    setState(() => _busy = true);
    try {
      await ref.read(profileRepositoryProvider).removeGalleryPhoto(path);
    } catch (e) {
      _snack(l10n.errRemovePhoto('$e'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // The grid rebuilds straight from the profile stream — the callable writes
    // the doc, so there is no local copy to keep in sync.
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l10n.galleryHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.text2)),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _maxPhotos,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10),
          itemBuilder: (_, i) {
            if (i < _paths.length) {
              final path = _paths[i];
              return Stack(children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: _GalleryThumb(path: path),
                  ),
                ),
                Positioned(
                  top: 6, right: 6,
                  child: GestureDetector(
                    onTap: () => _remove(path),
                    child: Container(
                      width: 24, height: 24,
                      decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ]);
            }
            final isNextSlot = i == _paths.length;
            return GestureDetector(
              onTap: isNextSlot ? _addPhoto : null,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.skyLight.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.skyLight, style: BorderStyle.solid),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  if (_busy && isNextSlot)
                    const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else ...[
                    const Icon(Icons.add_photo_alternate_outlined, color: AppColors.text3, size: 28),
                    const SizedBox(height: 6),
                    Text(l10n.addPhoto, style: const TextStyle(fontSize: 11, color: AppColors.text3)),
                  ],
                ]),
              ),
            );
          },
        ),
      ]),
    );
  }
}

/// Resolves a `gallery/…` Storage path to a download URL and renders it.
class _GalleryThumb extends ConsumerWidget {
  const _GalleryThumb({required this.path});

  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<String>(
      future: ref.read(profileRepositoryProvider).galleryPhotoUrl(path),
      builder: (context, snap) {
        final url = snap.data;
        if (url == null) {
          return Container(color: AppColors.skyLight.withValues(alpha: 0.3));
        }
        return Image.network(url, fit: BoxFit.cover);
      },
    );
  }
}

// ── Qualifications Tab ─────────────────────────────────────────────────────────

class _QualificationsTab extends ConsumerStatefulWidget {
  const _QualificationsTab({super.key, required this.profile});

  final UserProfile profile;

  @override
  ConsumerState<_QualificationsTab> createState() => _QualificationsTabState();
}

class _QualificationsTabState extends ConsumerState<_QualificationsTab> {
  late final List<TextEditingController> _ctrls;
  bool _saving = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _ctrls = widget.profile.qualifications
        .map((q) => TextEditingController(text: q))
        .toList();
    if (_ctrls.isEmpty) _ctrls.add(TextEditingController());
  }

  @override
  void dispose() {
    for (final c in _ctrls) { c.dispose(); }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    setState(() { _saving = true; _saved = false; });
    final values = _ctrls
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    try {
      await ref
          .read(profileRepositoryProvider)
          .updateProfile(qualifications: values);
    } catch (e) {
      if (mounted) setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errSaveQualifications('$e'))),
        );
      }
      return;
    }
    if (!mounted) return;
    setState(() { _saving = false; _saved = true; });
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _saved = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ..._ctrls.asMap().entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(children: [
            Expanded(
              child: TextFormField(
                controller: e.value,
                decoration: InputDecoration(
                  labelText: '${l10n.qualificationsLabel} ${e.key + 1}',
                  hintText: l10n.qualificationHint,
                  prefixIcon: const Icon(Icons.school_rounded),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
              onPressed: () => setState(() { e.value.dispose(); _ctrls.removeAt(e.key); }),
            ),
          ]),
        )),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.add_rounded),
          label: Text(l10n.addQualification),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.skyDark,
            side: const BorderSide(color: AppColors.skyLight),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => setState(() => _ctrls.add(TextEditingController())),
        ),
        const SizedBox(height: 24),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _saved
              ? _SavedBanner(key: const ValueKey('saved'), label: l10n.saved)
              : PrimaryButton(key: const ValueKey('btn'), label: l10n.saveChanges,
                  onPressed: _save, loading: _saving),
        ),
      ]),
    );
  }
}

// ── Experience Tab ─────────────────────────────────────────────────────────────

class _ExperienceFields {
  _ExperienceFields([ExperienceEntry? e])
      : titleCtrl = TextEditingController(text: e?.title ?? ''),
        institutionCtrl = TextEditingController(text: e?.institution ?? ''),
        fromCtrl = TextEditingController(text: e?.from ?? ''),
        toCtrl = TextEditingController(text: e?.to ?? '');

  final TextEditingController titleCtrl;
  final TextEditingController institutionCtrl;
  final TextEditingController fromCtrl;
  final TextEditingController toCtrl;

  ExperienceEntry toEntry() => ExperienceEntry(
        title: titleCtrl.text.trim(),
        institution: institutionCtrl.text.trim(),
        from: fromCtrl.text.trim(),
        to: toCtrl.text.trim(),
      );

  bool get isEmpty =>
      titleCtrl.text.trim().isEmpty && institutionCtrl.text.trim().isEmpty;

  void dispose() {
    titleCtrl.dispose();
    institutionCtrl.dispose();
    fromCtrl.dispose();
    toCtrl.dispose();
  }
}

class _ExperienceTab extends ConsumerStatefulWidget {
  const _ExperienceTab({super.key, required this.profile});

  final UserProfile profile;

  @override
  ConsumerState<_ExperienceTab> createState() => _ExperienceTabState();
}

class _ExperienceTabState extends ConsumerState<_ExperienceTab> {
  late final List<_ExperienceFields> _entries;
  bool _saving = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _entries =
        widget.profile.experience.map((e) => _ExperienceFields(e)).toList();
    if (_entries.isEmpty) _entries.add(_ExperienceFields());
  }

  @override
  void dispose() {
    for (final e in _entries) { e.dispose(); }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    setState(() { _saving = true; _saved = false; });
    final values = _entries
        .where((e) => !e.isEmpty)
        .map((e) => e.toEntry())
        .toList();
    try {
      await ref
          .read(profileRepositoryProvider)
          .updateProfile(experience: values);
    } catch (e) {
      if (mounted) setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errSaveExperience('$e'))),
        );
      }
      return;
    }
    if (!mounted) return;
    setState(() { _saving = false; _saved = true; });
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _saved = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        ..._entries.asMap().entries.map((e) => _ExperienceCard(
          entry: e.value,
          l10n: l10n,
          onRemove: () => setState(() { e.value.dispose(); _entries.removeAt(e.key); }),
        )),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.add_rounded),
          label: Text(l10n.addExperience),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.skyDark,
            side: const BorderSide(color: AppColors.skyLight),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => setState(() => _entries.add(_ExperienceFields())),
        ),
        const SizedBox(height: 24),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _saved
              ? _SavedBanner(key: const ValueKey('saved'), label: l10n.saved)
              : PrimaryButton(key: const ValueKey('btn'), label: l10n.saveChanges,
                  onPressed: _save, loading: _saving),
        ),
      ]),
    );
  }
}

class _ExperienceCard extends StatelessWidget {
  const _ExperienceCard({required this.entry, required this.l10n, required this.onRemove});
  final _ExperienceFields entry;
  final dynamic l10n;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(l10n.experienceLabel,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.text)),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
            onPressed: onRemove, padding: EdgeInsets.zero, constraints: const BoxConstraints(),
          ),
        ]),
        const SizedBox(height: 12),
        TextFormField(controller: entry.titleCtrl,
            decoration: InputDecoration(labelText: l10n.jobTitle, prefixIcon: const Icon(Icons.work_outline_rounded))),
        const SizedBox(height: 12),
        TextFormField(controller: entry.institutionCtrl,
            decoration: InputDecoration(labelText: l10n.institution, prefixIcon: const Icon(Icons.account_balance_rounded))),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: TextFormField(controller: entry.fromCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.yearFrom))),
          const SizedBox(width: 12),
          Expanded(child: TextFormField(controller: entry.toCtrl,
              decoration: InputDecoration(labelText: l10n.yearTo))),
        ]),
      ]),
    );
  }
}

// ── Schedule Tab ───────────────────────────────────────────────────────────────

class _ScheduleTab extends ConsumerStatefulWidget {
  const _ScheduleTab({super.key, required this.l10n, required this.profile});

  final dynamic l10n;
  final UserProfile profile;

  @override
  ConsumerState<_ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends ConsumerState<_ScheduleTab> {
  late final Map<String, Set<String>> _availability;
  bool _saving = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _availability = {
      for (final e in widget.profile.availability.entries) e.key: {...e.value},
    };
  }

  void _toggle(String day, String slot) {
    setState(() {
      _availability.putIfAbsent(day, () => {});
      if (_availability[day]!.contains(slot)) {
        _availability[day]!.remove(slot);
        if (_availability[day]!.isEmpty) _availability.remove(day);
      } else {
        _availability[day]!.add(slot);
      }
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    setState(() { _saving = true; _saved = false; });
    try {
      await ref
          .read(profileRepositoryProvider)
          .updateProfile(availability: _availability);
    } catch (e) {
      if (mounted) setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errSaveSchedule('$e'))),
        );
      }
      return;
    }
    if (!mounted) return;
    setState(() { _saving = false; _saved = true; });
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _saved = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final days = [
      ('Mon', l10n.mon), ('Tue', l10n.tue), ('Wed', l10n.wed),
      ('Thu', l10n.thu), ('Fri', l10n.fri), ('Sat', l10n.sat), ('Sun', l10n.sun),
    ];
    final slots = [
      ('Morning',   l10n.morning,   Icons.wb_sunny_outlined),
      ('Afternoon', l10n.afternoon, Icons.wb_twilight_outlined),
      ('Evening',   l10n.evening,   Icons.nightlight_outlined),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l10n.scheduleHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.text2)),
        const SizedBox(height: 20),
        Table(
          columnWidths: const {0: IntrinsicColumnWidth()},
          children: [
            TableRow(children: [
              const SizedBox.shrink(),
              ...days.map((d) => Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(d.$2, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text2)),
                ),
              )),
            ]),
            ...slots.map((slot) => TableRow(children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(slot.$3, size: 14, color: AppColors.text3),
                  const SizedBox(width: 4),
                  Text(slot.$2, style: const TextStyle(fontSize: 11, color: AppColors.text3)),
                ]),
              ),
              ...days.map((day) {
                final active = _availability[day.$1]?.contains(slot.$1) ?? false;
                return GestureDetector(
                  onTap: () => _toggle(day.$1, slot.$1),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                          color: active ? AppColors.skyDark : AppColors.skyLight.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: active ? const Icon(Icons.check_rounded, size: 16, color: Colors.white) : null,
                      ),
                    ),
                  ),
                );
              }),
            ])),
          ],
        ),
        const SizedBox(height: 28),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _saved
              ? _SavedBanner(key: const ValueKey('saved'), label: l10n.saved)
              : PrimaryButton(key: const ValueKey('btn'), label: l10n.saveChanges,
                  onPressed: _save, loading: _saving),
        ),
      ]),
    );
  }
}

// ── Videos Tab ─────────────────────────────────────────────────────────────────

class _VideosTab extends ConsumerStatefulWidget {
  const _VideosTab({super.key, required this.profile});

  final UserProfile profile;

  @override
  ConsumerState<_VideosTab> createState() => _VideosTabState();
}

class _VideosTabState extends ConsumerState<_VideosTab> {
  late final List<TextEditingController> _ctrls;
  bool _saving = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _ctrls = widget.profile.videoLinks
        .map((l) => TextEditingController(text: l))
        .toList();
    if (_ctrls.isEmpty) _ctrls.add(TextEditingController());
  }

  @override
  void dispose() {
    for (final c in _ctrls) { c.dispose(); }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    setState(() { _saving = true; _saved = false; });
    final links = _ctrls
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    try {
      // Server-validated: https YouTube/Vimeo only. A rejected link comes back
      // as invalid-argument and is surfaced verbatim, so the teacher knows why.
      await ref.read(profileRepositoryProvider).setVideoLinks(links);
    } catch (e) {
      if (mounted) setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errSaveVideos('$e'))),
        );
      }
      return;
    }
    if (!mounted) return;
    setState(() { _saving = false; _saved = true; });
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _saved = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(context.l10n.videosAllowedHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.text2)),
        const SizedBox(height: 16),
        ..._ctrls.asMap().entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(children: [
            Expanded(
              child: TextFormField(
                controller: e.value,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: l10n.videoUrlLabel(e.key + 1),
                  hintText: l10n.videoUrlHint,
                  prefixIcon: const Icon(Icons.play_circle_outline_rounded),
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (_ctrls.length > 1)
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                onPressed: () => setState(() { e.value.dispose(); _ctrls.removeAt(e.key); }),
              ),
          ]),
        )),
        if (_ctrls.length < 4) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.addVideoUrl),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.skyDark,
              side: const BorderSide(color: AppColors.skyLight),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => setState(() => _ctrls.add(TextEditingController())),
          ),
        ],
        const SizedBox(height: 24),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _saved
              ? _SavedBanner(key: const ValueKey('saved'), label: l10n.saved)
              : PrimaryButton(key: const ValueKey('btn'), label: l10n.saveChanges,
                  onPressed: _save, loading: _saving),
        ),
      ]),
    );
  }
}

// ── Shared saved banner ────────────────────────────────────────────────────────

class _SavedBanner extends StatelessWidget {
  const _SavedBanner({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(14)),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.w700)),
      ]),
    );
  }
}
