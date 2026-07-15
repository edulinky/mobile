/// The subject presets offered in profile edit.
///
/// Deliberately **country-agnostic**: these are subjects taught more or less
/// everywhere, not any one national curriculum. (The prototype's list was the
/// Nigerian WAEC/JAMB set, which is wrong for a Vietnam launch — and wrong for
/// anywhere else too.)
///
/// The list is not meant to be exhaustive. Users add anything missing through
/// the free-text "+ Add subject" chip, which is how the long tail (IELTS,
/// Mandarin, Music Theory…) gets covered.
///
/// It exists at all because subjects are **compared as strings** across users:
/// `bucketFor()` decides whether a right-swipe costs from the primary-subject
/// budget or the discovery budget by matching a student's `primary_subject`
/// against a teacher's `subjects`. Without a canonical spelling for the common
/// cases, "Maths" and "Mathematics" become different subjects and matching
/// quietly degrades.
///
/// When a custom subject shows up often enough, promote it here.
const List<String> kSubjectPresets = [
  // Core sciences & maths
  'Mathematics',
  'Physics',
  'Chemistry',
  'Biology',
  'Computer Science',

  // Humanities & social sciences
  'English',
  'Literature',
  'History',
  'Geography',
  'Economics',

  // Languages
  'Spanish',
  'French',
  'German',
  'Mandarin',

  // Arts
  'Music',
  'Art',
];
