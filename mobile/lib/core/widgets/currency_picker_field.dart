import 'package:flutter/material.dart';
import '../extensions/l10n_extension.dart';
import '../money/currency.dart';

/// Currency selector, rendered from [Currency.supported].
///
/// Today that list holds only USD, so the field shows a single locked option —
/// deliberately: it makes the currency of a price *visible* rather than an
/// unstated assumption, and the day a second currency is added the picker
/// starts working with no changes here or at any call site.
class CurrencyPickerField extends StatelessWidget {
  const CurrencyPickerField({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final Currency value;
  final ValueChanged<Currency> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final options = Currency.supported;
    final soleOption = options.length < 2;

    return DropdownButtonFormField<Currency>(
      initialValue: value,
      // The field sits in a narrow column next to the rate; let the dropdown
      // take the width it is given instead of its intrinsic width.
      isExpanded: true,
      // A one-item dropdown has nothing to choose, so don't pretend otherwise.
      onChanged: (!enabled || soleOption)
          ? null
          : (c) {
              if (c != null) onChanged(c);
            },
      decoration: InputDecoration(labelText: l10n.currency),
      items: [
        for (final c in options)
          DropdownMenuItem(
            value: c,
            child: Text(c.label, overflow: TextOverflow.ellipsis),
          ),
      ],
    );
  }
}
