import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../extensions/l10n_extension.dart';
import '../places/places_service.dart';
import '../theme/app_theme.dart';

/// Full-screen city search backed by Places API (New) via our App-Check-protected
/// Cloud Function proxy, restricted to cities (no street addresses). Returns a
/// [SelectedCity] (with lat/lng) via Navigator.pop, or null if cancelled.
class CityPickerScreen extends ConsumerStatefulWidget {
  const CityPickerScreen({super.key});

  static Future<SelectedCity?> push(BuildContext context) {
    return Navigator.of(context).push<SelectedCity>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const CityPickerScreen(),
      ),
    );
  }

  @override
  ConsumerState<CityPickerScreen> createState() => _CityPickerScreenState();
}

class _CityPickerScreenState extends ConsumerState<CityPickerScreen> {
  final _searchCtrl = TextEditingController();
  // One Places session token per pick (autocomplete calls + details) so Google
  // bills it as a single session.
  final String _sessionToken =
      '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(0x7fffffff)}';
  Timer? _debounce;
  List<CityPrediction> _results = [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.length < 2) {
      setState(() {
        _results = [];
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(query));
  }

  Future<void> _search(String query) async {
    try {
      final results = await ref
          .read(placesServiceProvider)
          .autocomplete(query, sessionToken: _sessionToken);
      if (!mounted) return;
      setState(() {
        _results = results;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load suggestions. Check your connection.';
      });
    }
  }

  Future<void> _select(CityPrediction p) async {
    setState(() => _loading = true);
    try {
      final city = await ref
          .read(placesServiceProvider)
          .details(p, sessionToken: _sessionToken);
      if (!mounted) return;
      Navigator.of(context).pop(city);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.errCityNotSelectable)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.skyBg,
      appBar: AppBar(
        title: Text(context.l10n.selectYourCity),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.text,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              onChanged: _onChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: context.l10n.searchForACity,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchCtrl.clear();
                          _onChanged('');
                          setState(() {});
                        },
                      ),
              ),
            ),
          ),
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(_error!,
                  style: const TextStyle(color: Colors.redAccent)),
            ),
          Expanded(
            child: ListView.separated(
              itemCount: _results.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final p = _results[i];
                return ListTile(
                  leading: const Icon(Icons.location_city_rounded,
                      color: AppColors.skyDark),
                  title: Text(p.primaryText),
                  subtitle:
                      p.secondaryText.isEmpty ? null : Text(p.secondaryText),
                  onTap: _loading ? null : () => _select(p),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
