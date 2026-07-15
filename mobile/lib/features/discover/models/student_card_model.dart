class StudentCardModel {
  const StudentCardModel({
    required this.uid,
    required this.name,
    required this.avatarUrl,
    required this.subjects,
    required this.distanceKm,
    required this.bio,
    this.gradeLevel = '',
  });

  final String uid;
  final String name;
  final String avatarUrl;
  final List<String> subjects;
  final double distanceKm;
  final String bio;
  final String gradeLevel;
}
