import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/extensions/l10n_extension.dart';
import '../../../core/theme/app_theme.dart';
import '../../profile/data/profile_repository.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/primary_button.dart';

class CertUploadScreen extends ConsumerStatefulWidget {
  const CertUploadScreen({super.key});

  @override
  ConsumerState<CertUploadScreen> createState() => _CertUploadScreenState();
}

class _CertUploadScreenState extends ConsumerState<CertUploadScreen> {
  /// Mirrors the server's cap in `submitCertification`.
  static const _maxFiles = 5;

  final List<CertificateFile> _files = [];
  bool _loading = false;

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pick() async {
    final l10n = context.l10n;
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true, // we upload bytes, never a path
    );
    if (result == null) return;

    final room = _maxFiles - _files.length;
    if (room <= 0) {
      _snack(l10n.certMaxFiles(_maxFiles));
      return;
    }

    final picked = <CertificateFile>[];
    for (final f in result.files) {
      final bytes = f.bytes;
      if (bytes == null) continue;
      // Same 10 MB ceiling the Storage rules enforce — fail here rather than
      // after a long upload.
      if (bytes.lengthInBytes > 10 * 1024 * 1024) {
        _snack(l10n.certFileTooLarge(f.name));
        continue;
      }
      if (_files.any((e) => e.name == f.name)) continue;
      picked.add(CertificateFile(name: f.name, bytes: bytes));
    }

    if (picked.length > room) {
      _snack(l10n.certMaxFiles(_maxFiles));
    }
    if (picked.isEmpty) return;
    setState(() => _files.addAll(picked.take(room)));
  }

  Future<void> _submit() async {
    if (_files.isEmpty || _loading) return;
    final l10n = context.l10n;
    setState(() => _loading = true);
    try {
      await ref.read(profileRepositoryProvider).submitCertification(_files);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _snack(l10n.errSubmitCertificate('$e'));
      return;
    }
    if (!mounted) return;
    setState(() => _loading = false);
    context.go('/pending');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasFiles = _files.isNotEmpty;
    return AuthScaffold(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Text(
              l10n.uploadCertification,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800, color: AppColors.text),
            ),
            const SizedBox(height: 6),
            Text(l10n.uploadCertSubtitle,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.text2)),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _loading ? null : _pick,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 150,
                decoration: BoxDecoration(
                  color: hasFiles
                      ? AppColors.sky.withValues(alpha: 0.08)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: hasFiles ? AppColors.skyDark : AppColors.skyLight,
                    width: hasFiles ? 2 : 1.5,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasFiles
                            ? Icons.library_add_outlined
                            : Icons.upload_file_rounded,
                        size: 44,
                        color: hasFiles ? AppColors.skyDark : AppColors.text3,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        hasFiles ? l10n.addAnotherFile : l10n.dragDropOrTap,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: hasFiles ? AppColors.skyDark : AppColors.text2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(l10n.supportedFormats,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.text3)),
                    ],
                  ),
                ),
              ),
            ),
            if (hasFiles) ...[
              const SizedBox(height: 16),
              Text(l10n.certFilesSelected(_files.length, _maxFiles),
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text3)),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: _files.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _FileRow(
                    file: _files[i],
                    onRemove: _loading
                        ? null
                        : () => setState(() => _files.removeAt(i)),
                  ),
                ),
              ),
            ] else
              const Spacer(),
            const SizedBox(height: 12),
            PrimaryButton(
              label: l10n.submitForReview,
              onPressed: hasFiles ? _submit : null,
              loading: _loading,
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: _loading ? null : () => context.go('/pending'),
                child: Text(l10n.skipForNow),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _FileRow extends StatelessWidget {
  const _FileRow({required this.file, this.onRemove});

  final CertificateFile file;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final kb = file.bytes.lengthInBytes / 1024;
    final size = kb >= 1024
        ? '${(kb / 1024).toStringAsFixed(1)} MB'
        : '${kb.toStringAsFixed(0)} KB';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.skyLight),
      ),
      child: Row(
        children: [
          Icon(
            file.isPdf
                ? Icons.picture_as_pdf_rounded
                : Icons.image_outlined,
            size: 20,
            color: AppColors.skyDark,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text),
                ),
                Text(size,
                    style: const TextStyle(fontSize: 11, color: AppColors.text3)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded,
                size: 18, color: AppColors.error),
            onPressed: onRemove,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
