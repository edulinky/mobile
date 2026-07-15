import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/widgets/bottom_nav.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/extensions/l10n_extension.dart';

class InstitutionProfileScreen extends StatefulWidget {
  const InstitutionProfileScreen({super.key});

  @override
  State<InstitutionProfileScreen> createState() => _InstitutionProfileScreenState();
}

class _InstitutionProfileScreenState extends State<InstitutionProfileScreen> {
  final _nameCtrl    = TextEditingController(text: 'Sunshine Academy');
  final _descCtrl    = TextEditingController(
      text: 'A forward-thinking secondary school committed to academic excellence and character development.');
  final _locationCtrl = TextEditingController(text: 'Ho Chi Minh City, Vietnam');
  final _websiteCtrl  = TextEditingController(text: 'https://sunshineacademy.edu');
  final _emailCtrl    = TextEditingController(text: 'hr@sunshineacademy.edu');
  XFile? _logo;
  bool _saved = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _websiteCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file != null) setState(() => _logo = file);
  }

  void _save() {
    // TODO: call API
    setState(() => _saved = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _saved = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  children: [
                    _buildLogoSection(l10n),
                    const SizedBox(height: 24),
                    _buildFormCard(context, l10n),
                    const SizedBox(height: 24),
                    _buildSaveButton(context, l10n),
                  ],
                ),
              ),
            ),
            const BottomNav(currentIndex: 2, role: NavRole.institution),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoSection(dynamic l10n) {
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
                image: _logo != null
                    ? DecorationImage(image: FileImage(File(_logo!.path)), fit: BoxFit.cover)
                    : null,
              ),
              child: _logo == null
                  ? const Icon(Icons.account_balance_rounded, size: 40, color: AppColors.skyDark)
                  : null,
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

  Widget _buildFormCard(BuildContext context, dynamic l10n) {
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
          TextFormField(
            controller: _locationCtrl,
            decoration: InputDecoration(
              labelText: l10n.cityLocation,
              hintText: l10n.cityLocationHint,
              prefixIcon: const Icon(Icons.location_on_outlined),
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
                onPressed: _save,
                child: Text(l10n.saveProfile),
              ),
            ),
    );
  }
}
