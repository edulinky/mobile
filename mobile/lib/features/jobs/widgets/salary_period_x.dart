import 'package:flutter/widgets.dart';
import '../../../core/extensions/l10n_extension.dart';
import '../models/job_card.dart';

/// Localized labels for a pay period. Never baked into the formatted amount —
/// the figure and the period are separate values, and both must translate.
extension SalaryPeriodX on SalaryPeriod {
  String label(BuildContext context) => switch (this) {
        SalaryPeriod.hour => context.l10n.perHour,
        SalaryPeriod.day => context.l10n.perDay,
        SalaryPeriod.month => context.l10n.perMonth,
      };

  /// Short suffix for a salary chip, e.g. `$1,200/mo`.
  String short(BuildContext context) => switch (this) {
        SalaryPeriod.hour => context.l10n.payPerHourShort,
        SalaryPeriod.day => context.l10n.payPerDayShort,
        SalaryPeriod.month => context.l10n.payPerMonthShort,
      };
}
