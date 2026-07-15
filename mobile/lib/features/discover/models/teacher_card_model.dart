import '../../../core/money/currency.dart';

enum VerifiedStatus { verified, pending, unverified }

/// One card in the swipe deck, as returned by the `getCandidates` callable.
class TeacherCardModel {
  const TeacherCardModel({
    required this.uid,
    required this.name,
    required this.avatarUrl,
    required this.subjects,
    required this.distanceKm,
    required this.rating,
    required this.reviewCount,
    required this.experienceYears,
    required this.bio,
    this.verifiedStatus = VerifiedStatus.unverified,
    this.isFeatured = false,
    this.galleryUrls = const [],
    this.qualifications = const [],
    this.availability = const {},
    this.hourlyRate,
    this.currency = Currency.fallback,
  });

  final String uid;
  final String name;
  final String avatarUrl;
  final List<String> subjects;
  final double distanceKm;
  final double rating;
  final int reviewCount;
  final int experienceYears;
  final String bio;
  final VerifiedStatus verifiedStatus;
  final bool isFeatured;
  final List<String> galleryUrls;
  final List<String> qualifications;
  final Map<String, List<String>> availability;

  /// Always paired with [currency] — an amount never travels without its unit.
  final num? hourlyRate;
  final Currency currency;
}
