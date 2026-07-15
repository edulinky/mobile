import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../features/profile/data/profile_repository.dart';

/// A currency the app can price in.
///
/// Only USD is offered today, but every amount is stored *with* its currency
/// code and formatted through [Money], so adding EUR/GBP/NGN later is a matter
/// of extending this list and letting users pick — not of hunting down bare
/// numbers and `$` signs scattered through the UI.
enum Currency {
  usd('USD', r'$');

  const Currency(this.code, this.symbol);

  /// ISO-4217 code, as stored in Firestore.
  final String code;
  final String symbol;

  static const Currency fallback = Currency.usd;

  /// The currencies a user may choose — this is what the picker renders. Add an
  /// enum value and list it here; the picker and everything downstream follow.
  static const List<Currency> supported = [Currency.usd];

  /// Human label for the picker, e.g. "USD ($)".
  String get label => '$code ($symbol)';

  /// Resolves a stored code; unknown/missing codes fall back rather than throw,
  /// so a doc written by a future version can still be displayed.
  static Currency fromCode(String? code) {
    if (code == null) return fallback;
    for (final c in Currency.values) {
      if (c.code == code.toUpperCase()) return c;
    }
    return fallback;
  }
}

/// Money formatting. Locale-aware, so it stays correct once the app is
/// translated — `1,234.50` in en-US is `1.234,50` in de-DE.
class Money {
  const Money._();

  /// e.g. `$25` / `$25.50`. Trailing `.00` is dropped — rates are usually round.
  static String format(
    num amount, {
    Currency currency = Currency.fallback,
    String? locale,
  }) {
    final hasCents = amount % 1 != 0;
    return NumberFormat.currency(
      locale: locale,
      symbol: currency.symbol,
      decimalDigits: hasCents ? 2 : 0,
    ).format(amount);
  }

  /// e.g. `$25/hr`. [perHour] comes from the ARB so it translates.
  static String perHour(
    num amount, {
    Currency currency = Currency.fallback,
    String? locale,
  }) {
    return '${format(amount, currency: currency, locale: locale)}/hr';
  }
}

/// The currency the signed-in user is priced in — their stored preference,
/// falling back to USD before the profile loads or if the field is absent.
final currencyProvider = Provider<Currency>((ref) {
  return ref.watch(myProfileProvider).maybeWhen(
        data: (p) => p.currency,
        orElse: () => Currency.fallback,
      );
});

extension MoneyContextX on BuildContext {
  String money(num amount, {Currency currency = Currency.fallback}) =>
      Money.format(amount,
          currency: currency, locale: Localizations.localeOf(this).toString());
}
