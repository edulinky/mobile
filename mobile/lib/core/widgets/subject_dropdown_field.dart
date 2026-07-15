import 'package:flutter/material.dart';
import '../constants/subjects.dart';
import '../extensions/l10n_extension.dart';

/// A single-subject field: pick from the preset list, or type your own.
///
/// The presets exist because a subject is **matched as a string** across users —
/// a teacher only sees job cards in the subjects they teach, so an institution
/// that types "Maths" where the teachers all wrote "Mathematics" reaches nobody
/// and never finds out why. The list makes the common spelling the easy one.
///
/// "Other" is still there, because the list will never be complete (IELTS, Music
/// Theory, a local curriculum subject) and a form that refuses the real answer is
/// worse than one that risks a typo.
///
/// The [controller] stays the single source of truth — the caller reads
/// `controller.text` exactly as it did when this was a bare TextFormField.
class SubjectDropdownField extends StatefulWidget {
  const SubjectDropdownField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;

  @override
  State<SubjectDropdownField> createState() => _SubjectDropdownFieldState();
}

/// Sentinel for the "Other" row. Not a real subject, so it cannot collide with
/// one.
const _kOther = '__other__';

class _SubjectDropdownFieldState extends State<SubjectDropdownField> {
  late String _selected;

  /// The preset whose spelling matches this text, ignoring case — so editing a
  /// card saved as "mathematics" still lands on the Mathematics row rather than
  /// dropping into Other.
  String? _presetFor(String text) {
    final t = text.trim().toLowerCase();
    for (final s in kSubjectPresets) {
      if (s.toLowerCase() == t) return s;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final text = widget.controller.text;
    _selected = text.trim().isEmpty ? '' : (_presetFor(text) ?? _kOther);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _selected.isEmpty ? null : _selected,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: widget.label,
            prefixIcon: const Icon(Icons.menu_book_outlined),
          ),
          items: [
            for (final s in kSubjectPresets)
              DropdownMenuItem(value: s, child: Text(s)),
            DropdownMenuItem(
              value: _kOther,
              child: Text(l10n.subjectOther),
            ),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _selected = value;
              // Picking a preset IS the answer; picking Other clears the field so
              // the leftover preset name is not silently submitted as a custom
              // subject.
              widget.controller.text = value == _kOther ? '' : value;
            });
          },
        ),
        if (_selected == _kOther) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: widget.controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l10n.subjectOtherLabel,
              hintText: widget.hint,
              prefixIcon: const Icon(Icons.edit_outlined),
            ),
          ),
        ],
      ],
    );
  }
}
