import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/money/currency.dart';

/// A pay figure is meaningless without its period: 1200 is a good hourly rate
/// and a poor monthly one.
enum SalaryPeriod {
  hour('hour'),
  day('day'),
  month('month');

  const SalaryPeriod(this.code);
  final String code;

  static SalaryPeriod fromCode(String? c) => switch (c) {
        'hour' => SalaryPeriod.hour,
        'day' => SalaryPeriod.day,
        _ => SalaryPeriod.month,
      };
}

enum ContractType {
  fullTime('full_time'),
  partTime('part_time'),
  contract('contract');

  const ContractType(this.code);
  final String code;

  static ContractType fromCode(String? c) => switch (c) {
        'part_time' => ContractType.partTime,
        'contract' => ContractType.contract,
        _ => ContractType.fullTime,
      };
}

/// A job posted by an institution. Teachers swipe these; a right-swipe is an
/// application (one-directional — no mutual swipe, no match).
class JobCard {
  const JobCard({
    required this.jobId,
    required this.instId,
    required this.institutionName,
    required this.institutionLogoUrl,
    required this.title,
    required this.subject,
    required this.level,
    required this.description,
    required this.contractType,
    required this.salaryMin,
    required this.salaryMax,
    required this.salaryPeriod,
    required this.currency,
    required this.startAt,
    required this.videoUrl,
    required this.city,
    required this.distanceKm,
    required this.status,
    required this.applicantCount,
  });

  final String jobId;
  final String instId;
  final String institutionName;
  final String institutionLogoUrl;
  final String title;
  /// One subject per card — a school hiring for two posts two cards.
  final String subject;

  /// e.g. "KS3", "A-Level", "Secondary". Free text: level naming differs by
  /// country, so a fixed list would be wrong somewhere.
  final String level;
  final String description;
  final ContractType contractType;
  final num? salaryMin;
  final num? salaryMax;
  final SalaryPeriod salaryPeriod;
  final Currency currency;

  /// Null = start date flexible.
  final DateTime? startAt;
  final String videoUrl;
  final String city;
  final double distanceKm;
  final String status;
  final int applicantCount;

  bool get isActive => status == 'active';

  /// Saved but not published — never appears in a teacher's deck.
  bool get isDraft => status == 'draft';

  /// e.g. "$1,200 – $1,800" — always carries its currency. The period is NOT
  /// baked in: it is localized at the call site (see `salaryPeriodLabel`).
  String salaryRange({String? locale}) {
    if (salaryMin == null && salaryMax == null) return '';
    String fmt(num v) => Money.format(v, currency: currency, locale: locale);
    if (salaryMin != null && salaryMax != null) {
      return '${fmt(salaryMin!)} – ${fmt(salaryMax!)}';
    }
    return fmt((salaryMin ?? salaryMax)!);
  }

  /// From the `getJobCards` callable.
  factory JobCard.fromMap(Map m) => JobCard(
        jobId: (m['jobId'] ?? '') as String,
        instId: (m['instId'] ?? '') as String,
        institutionName: (m['institutionName'] ?? '') as String,
        institutionLogoUrl: (m['institutionLogoUrl'] ?? '') as String,
        title: (m['title'] ?? '') as String,
        subject: (m['subject'] ?? '') as String,
        level: (m['level'] ?? '') as String,
        description: (m['description'] ?? '') as String,
        contractType: ContractType.fromCode(m['contractType'] as String?),
        salaryMin: m['salaryMin'] as num?,
        salaryMax: m['salaryMax'] as num?,
        salaryPeriod: SalaryPeriod.fromCode(m['salaryPeriod'] as String?),
        currency: Currency.fromCode(m['currency'] as String?),
        startAt: (m['startAtMs'] as num?) == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(
                (m['startAtMs'] as num).toInt()),
        videoUrl: (m['videoUrl'] ?? '') as String,
        city: (m['city'] ?? '') as String,
        distanceKm: ((m['distanceKm'] as num?) ?? 0).toDouble(),
        status: 'active',
        applicantCount: 0,
      );

  /// From Firestore (an institution reading its own cards).
  factory JobCard.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return JobCard(
      jobId: doc.id,
      instId: (d['inst_id'] as String?) ?? '',
      institutionName: (d['institution_name'] as String?) ?? '',
      institutionLogoUrl: (d['institution_logo_url'] as String?) ?? '',
      title: (d['title'] as String?) ?? '',
      subject: (d['subject'] as String?) ?? '',
      level: (d['level'] as String?) ?? '',
      description: (d['description'] as String?) ?? '',
      contractType: ContractType.fromCode(d['contract_type'] as String?),
      salaryMin: d['salary_min'] as num?,
      salaryMax: d['salary_max'] as num?,
      salaryPeriod: SalaryPeriod.fromCode(d['salary_period'] as String?),
      currency: Currency.fromCode(d['currency'] as String?),
      startAt: (d['start_at'] as Timestamp?)?.toDate(),
      videoUrl: (d['video_url'] as String?) ?? '',
      city: ((d['geo_location'] as Map?)?['city'] as String?) ?? '',
      distanceKm: 0,
      status: (d['status'] as String?) ?? 'active',
      applicantCount: ((d['applicant_count'] as num?) ?? 0).toInt(),
    );
  }
}

/// A teacher's application to a job card.
class JobApplication {
  const JobApplication({
    required this.applicationId,
    required this.jobId,
    required this.teacherId,
    required this.teacherName,
    required this.teacherPhotoUrl,
    required this.jobTitle,
    required this.createdAt,
  });

  final String applicationId;
  final String jobId;
  final String teacherId;
  final String teacherName;
  final String teacherPhotoUrl;
  final String jobTitle;
  final DateTime? createdAt;

  static JobApplication fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return JobApplication(
      applicationId: doc.id,
      jobId: (d['job_id'] as String?) ?? '',
      teacherId: (d['teacher_id'] as String?) ?? '',
      teacherName: (d['teacher_name'] as String?) ?? '',
      teacherPhotoUrl: (d['teacher_photo_url'] as String?) ?? '',
      jobTitle: (d['job_title'] as String?) ?? '',
      createdAt: (d['created_at'] as Timestamp?)?.toDate(),
    );
  }
}
