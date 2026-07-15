import 'package:flutter/material.dart';
import '../extensions/l10n_extension.dart';
import '../theme/app_theme.dart';
import 'selectable_chip.dart';

/// Subject picker: the common presets, plus anything the user types in.
///
/// The preset list will never cover every subject (Mandarin, Music Theory, Data
/// Science…), so a free-text "Add" chip sits at the end. A custom subject is
/// shown alongside the presets and behaves identically once added.
class SubjectSelector extends StatelessWidget {
  const SubjectSelector({
    super.key,
    required this.presets,
    required this.selected,
    required this.onChanged,
    this.maxSubjects = 15,
    this.singleSelect = false,
  });

  final List<String> presets;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;
  final int maxSubjects;

  /// Exactly one subject (a Job Card). Tapping a chip *replaces* the choice
  /// rather than adding to it — otherwise the user would have to deselect the
  /// old one first, which reads like a bug.
  final bool singleSelect;

  /// Presets first (stable order), then any custom subjects the user added.
  List<String> get _visible {
    final lowerPresets = presets.map((s) => s.toLowerCase()).toSet();
    final custom = selected
        .where((s) => !lowerPresets.contains(s.toLowerCase()))
        .toList()
      ..sort();
    return [...presets, ...custom];
  }

  bool _isSelected(String subject) => selected
      .any((s) => s.toLowerCase() == subject.toLowerCase());

  void _toggle(String subject) {
    if (singleSelect) {
      // Tapping the selected chip clears it; tapping another replaces it.
      onChanged(_isSelected(subject) ? {} : {subject});
      return;
    }
    final next = {...selected};
    if (_isSelected(subject)) {
      next.removeWhere((s) => s.toLowerCase() == subject.toLowerCase());
    } else {
      if (next.length >= maxSubjects) return;
      next.add(subject);
    }
    onChanged(next);
  }

  Future<void> _addCustom(BuildContext context) async {
    final l10n = context.l10n;
    if (!singleSelect && selected.length >= maxSubjects) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.subjectsMax(maxSubjects))),
      );
      return;
    }

    // The dialog owns its controller: disposing it here, as soon as showDialog
    // returns, kills it while the dialog is still animating out and rebuilding
    // its TextField.
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _AddSubjectDialog(),
    );

    final subject = (name ?? '').trim();
    if (subject.isEmpty) return;
    // Adding a subject already in the list just selects it, rather than
    // creating a near-duplicate that differs only by case.
    if (_isSelected(subject)) return;
    onChanged(singleSelect ? {subject} : {...selected, subject});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final subject in _visible)
          SelectableChip(
            label: subject,
            selected: _isSelected(subject),
            onTap: () => _toggle(subject),
          ),
        _AddChip(label: l10n.addSubject, onTap: () => _addCustom(context)),
      ],
    );
  }
}

class _AddChip extends StatelessWidget {
  const _AddChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.skyDark.withValues(alpha: 0.45),
            width: 1.4,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, size: 16, color: AppColors.skyDeeper),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.skyDeeper,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/// Prompts for a custom subject name. Owns its [TextEditingController] so the
/// controller lives exactly as long as the dialog does.
class _AddSubjectDialog extends StatefulWidget {
  const _AddSubjectDialog();

  @override
  State<_AddSubjectDialog> createState() => _AddSubjectDialogState();
}

class _AddSubjectDialogState extends State<_AddSubjectDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.addSubject),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        maxLength: 40,
        decoration: InputDecoration(hintText: l10n.addSubjectHint),
        onSubmitted: (v) => Navigator.of(context).pop(v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(l10n.add),
        ),
      ],
    );
  }
}
