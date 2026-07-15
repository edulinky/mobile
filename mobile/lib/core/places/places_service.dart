import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../firebase/firebase_refs.dart';

/// One city suggestion from autocomplete.
class CityPrediction {
  const CityPrediction({
    required this.placeId,
    required this.primaryText,
    required this.secondaryText,
    required this.fullText,
  });

  final String placeId;
  final String primaryText; // e.g. "London"
  final String secondaryText; // e.g. "United Kingdom"
  final String fullText; // e.g. "London, United Kingdom"
}

/// A city chosen from autocomplete (city-level only, with coordinates).
class SelectedCity {
  const SelectedCity({
    required this.city,
    required this.placeId,
    required this.lat,
    required this.lng,
  });

  final String city;
  final String placeId;
  final double lat;
  final double lng;
}

/// Talks to Places API (New) via our App-Check-protected Cloud Function proxy —
/// the API key stays server-side (functions/.env), never in the app.
class PlacesService {
  const PlacesService();

  Future<List<CityPrediction>> autocomplete(
    String input, {
    String? sessionToken,
  }) async {
    final res = await Fb.functions.httpsCallable('placesAutocomplete').call({
      'input': input,
      'sessionToken': ?sessionToken,
    });
    final data = res.data as Map;
    final list = (data['suggestions'] as List?) ?? const [];
    return list
        .map((e) {
          final m = e as Map;
          return CityPrediction(
            placeId: (m['placeId'] ?? '') as String,
            primaryText: (m['primaryText'] ?? '') as String,
            secondaryText: (m['secondaryText'] ?? '') as String,
            fullText: (m['fullText'] ?? '') as String,
          );
        })
        .where((p) => p.placeId.isNotEmpty)
        .toList();
  }

  Future<SelectedCity> details(
    CityPrediction prediction, {
    String? sessionToken,
  }) async {
    final res = await Fb.functions.httpsCallable('placeDetails').call({
      'placeId': prediction.placeId,
      'sessionToken': ?sessionToken,
    });
    final m = res.data as Map;
    return SelectedCity(
      city: prediction.fullText,
      placeId: prediction.placeId,
      lat: (m['lat'] as num).toDouble(),
      lng: (m['lng'] as num).toDouble(),
    );
  }
}

final placesServiceProvider = Provider<PlacesService>((ref) {
  return const PlacesService();
});
