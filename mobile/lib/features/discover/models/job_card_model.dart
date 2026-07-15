import '../../jobs/models/job_card.dart';
import 'student_card_model.dart';

/// The teacher's deck holds two kinds of card: people and jobs. They swipe the
/// same way but mean different things — a student is a mutual match, a job card
/// is a one-directional application.
sealed class TeacherDiscoverItem {
  const TeacherDiscoverItem();
}

class StudentItem extends TeacherDiscoverItem {
  const StudentItem(this.student);
  final StudentCardModel student;
}

class JobItem extends TeacherDiscoverItem {
  const JobItem(this.job);
  final JobCard job;
}
