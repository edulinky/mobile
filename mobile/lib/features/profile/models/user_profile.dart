import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/money/currency.dart';
import '../../discover/models/teacher_card_model.dart' show VerifiedStatus;

/// A city chosen from Places, as stored on the user doc.
class GeoLocation {
  const GeoLocation({
    required this.city,
    required this.lat,
    required this.lng,
    required this.placeId,
  });

  final String city;
  final double lat;
  final double lng;
  final String placeId;

  static GeoLocation? fromMap(Map<String, dynamic>? m) {
    if (m == null) return null;
    final lat = m['lat'], lng = m['lng'];
    if (lat is! num || lng is! num) return null;
    return GeoLocation(
      city: (m['city'] as String?) ?? '',
      lat: lat.toDouble(),
      lng: lng.toDouble(),
      placeId: (m['place_id'] as String?) ?? '',
    );
  }
}

/// One row of a teacher's work history.
class ExperienceEntry {
  const ExperienceEntry({
    required this.title,
    required this.institution,
    required this.from,
    required this.to,
  });

  final String title;
  final String institution;
  final String from;
  final String to;

  Map<String, Object?> toMap() => {
        'title': title,
        'institution': institution,
        'from': from,
        'to': to,
      };

  factory ExperienceEntry.fromMap(Map<String, dynamic> m) => ExperienceEntry(
        title: (m['title'] as String?) ?? '',
        institution: (m['institution'] as String?) ?? '',
        from: (m['from'] as String?) ?? '',
        to: (m['to'] as String?) ?? '',
      );
}

/// The signed-in user's `users/{uid}` document.
///
/// `role`, `subStatus`, `verifiedStatus` and `isBanned` are server-owned — the
/// Firestore rules reject any client write to them, so they are read-only here.
/// So are [gallery] and [videoLinks]: they render to *other* users, so they go
/// through validating callables (see `ProfileRepository`).
class UserProfile {
  const UserProfile({
    required this.uid,
    required this.role,
    required this.email,
    required this.displayName,
    required this.about,
    required this.photoUrl,
    required this.primarySubject,
    required this.subjects,
    required this.hourlyRate,
    required this.currency,
    required this.geoLocation,
    required this.verifiedStatus,
    required this.subStatus,
    required this.avgRating,
    required this.totalReviews,
    required this.gallery,
    required this.qualifications,
    required this.experience,
    required this.availability,
    required this.videoLinks,
    required this.featured,
    required this.website,
    required this.contactEmail,
  });

  final String uid;
  final String role;
  final String email;
  final String displayName;
  final String about;
  final String photoUrl;
  final String primarySubject;
  final List<String> subjects;
  final num? hourlyRate;

  /// The currency [hourlyRate] is denominated in. Always USD today.
  final Currency currency;
  final GeoLocation? geoLocation;
  final String verifiedStatus;
  final String subStatus;
  final num avgRating;
  final int totalReviews;

  /// Storage **paths** (not URLs) under `gallery/{uid}/…`.
  final List<String> gallery;
  final List<String> qualifications;
  final List<ExperienceEntry> experience;

  /// Day code ("Mon".."Sun") → the slots ("Morning"/"Afternoon"/"Evening").
  final Map<String, Set<String>> availability;
  final List<String> videoLinks;

  /// Server-owned: an admin promotes a profile in discovery.
  final bool featured;

  /// Institution-only. Empty for every other role.
  final String website;

  /// Institution-only: a public HR/contact address, separate from the account's
  /// own sign-in `email` (which must not be arbitrarily client-editable).
  final String contactEmail;

  bool get isVerified => verifiedStatus == 'approved';

  /// The stored status as the badge widget's enum.
  VerifiedStatus get verified => switch (verifiedStatus) {
        'approved' => VerifiedStatus.verified,
        'pending' => VerifiedStatus.pending,
        _ => VerifiedStatus.unverified,
      };

  factory UserProfile.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? const <String, dynamic>{};
    return UserProfile(
      uid: doc.id,
      role: (d['role'] as String?) ?? '',
      email: (d['email'] as String?) ?? '',
      displayName: (d['display_name'] as String?) ?? '',
      about: (d['about'] as String?) ?? '',
      photoUrl: (d['photo_url'] as String?) ?? '',
      primarySubject: (d['primary_subject'] as String?) ?? '',
      subjects: ((d['subjects'] as List?) ?? const [])
          .map((e) => '$e')
          .toList(growable: false),
      hourlyRate: d['hourly_rate'] as num?,
      currency: Currency.fromCode(d['currency'] as String?),
      geoLocation: GeoLocation.fromMap(
        (d['geo_location'] as Map?)?.cast<String, dynamic>(),
      ),
      verifiedStatus: (d['verified_status'] as String?) ?? 'not_required',
      subStatus: (d['sub_status'] as String?) ?? 'free',
      avgRating: (d['avg_rating'] as num?) ?? 0,
      totalReviews: (d['total_reviews'] as int?) ?? 0,
      gallery: _stringList(d['gallery']),
      qualifications: _stringList(d['qualifications']),
      experience: ((d['experience'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => ExperienceEntry.fromMap(e.cast<String, dynamic>()))
          .toList(growable: false),
      availability: _availabilityFrom(d['availability']),
      videoLinks: _stringList(d['video_links']),
      featured: (d['featured'] as bool?) ?? false,
      website: (d['website'] as String?) ?? '',
      contactEmail: (d['contact_email'] as String?) ?? '',
    );
  }
}

List<String> _stringList(Object? raw) {
  return ((raw as List?) ?? const []).map((e) => '$e').toList(growable: false);
}

Map<String, Set<String>> _availabilityFrom(Object? raw) {
  if (raw is! Map) return {};
  return {
    for (final entry in raw.entries)
      '${entry.key}': _stringList(entry.value).toSet(),
  };
}
