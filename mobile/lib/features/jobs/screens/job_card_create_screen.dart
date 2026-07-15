import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/extensions/l10n_extension.dart';
import '../../../core/money/currency.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/subject_dropdown_field.dart';
import '../../auth/widgets/primary_button.dart';
import '../../profile/data/profile_repository.dart';
import '../data/jobs_repository.dart';
import '../models/job_card.dart';
import '../widgets/salary_period_x.dart';

/// Create or edit a Job Card.
///
/// Fields, in order: title, subject, level, contract type, salary range, start
/// date, description, video URL (optional).
///
/// There is deliberately **no location field**: the card inherits the
/// institution's verified city and the geohash is derived from it server-side —
/// otherwise a card could claim to be somewhere it isn't and surface in the
/// wrong teachers' decks.
class JobCardCreateScreen extends ConsumerStatefulWidget {
  const JobCardCreateScreen({super.key, this.job});

  /// Non-null when editing.
  final JobCard? job;

  @override
  ConsumerState<JobCardCreateScreen> createState() =>
      _JobCardCreateScreenState();
}

class _JobCardCreateScreenState extends ConsumerState<JobCardCreateScreen> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _subjectCtrl;
  late final TextEditingController _levelCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _minCtrl;
  late final TextEditingController _maxCtrl;
  late final TextEditingController _videoCtrl;
  late ContractType _contract;
  late SalaryPeriod _period;
  DateTime? _startAt;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final j = widget.job;
    _titleCtrl = TextEditingController(text: j?.title ?? '');
    _subjectCtrl = TextEditingController(text: j?.subject ?? '');
    _levelCtrl = TextEditingController(text: j?.level ?? '');
    _descCtrl = TextEditingController(text: j?.description ?? '');
    _minCtrl = TextEditingController(text: j?.salaryMin?.toString() ?? '');
    _maxCtrl = TextEditingController(text: j?.salaryMax?.toString() ?? '');
    _videoCtrl = TextEditingController(text: j?.videoUrl ?? '');
    _contract = j?.contractType ?? ContractType.fullTime;
    _period = j?.salaryPeriod ?? SalaryPeriod.month;
    _startAt = j?.startAt;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subjectCtrl.dispose();
    _levelCtrl.dispose();
    _descCtrl.dispose();
    _minCtrl.dispose();
    _maxCtrl.dispose();
    _videoCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startAt ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 3),
    );
    if (picked != null) setState(() => _startAt = picked);
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _save({required bool draft}) async {
    final l10n = context.l10n;
    if (_titleCtrl.text.trim().isEmpty) {
      _snack(l10n.errJobTitleSubjectRequired);
      return;
    }
    if (_subjectCtrl.text.trim().isEmpty) {
      _snack(l10n.errJobSubjectsRequired);
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(jobsRepositoryProvider).upsertJobCard(
            jobId: widget.job?.jobId,
            title: _titleCtrl.text.trim(),
            subject: _subjectCtrl.text.trim(),
            level: _levelCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            contractType: _contract,
            salaryMin: num.tryParse(_minCtrl.text.trim()),
            salaryMax: num.tryParse(_maxCtrl.text.trim()),
            salaryPeriod: _period,
            startAt: _startAt,
            videoUrl: _videoCtrl.text.trim(),
            draft: draft,
          );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack('$e');
      return;
    }
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final profile = ref.watch(myProfileProvider).valueOrNull;
    final currency = profile?.currency ?? Currency.fallback;
    final city = profile?.geoLocation?.city ?? '';
    final locale = Localizations.localeOf(context).toString();

    return Scaffold(
      backgroundColor: AppColors.skyBg,
      appBar: AppBar(
        backgroundColor: AppColors.skyBg,
        elevation: 0,
        title: Text(widget.job == null ? l10n.postJob : l10n.editJob,
            style: const TextStyle(
                fontWeight: FontWeight.w800, color: AppColors.text)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l10n.jobTitle,
                  prefixIcon: const Icon(Icons.work_outline_rounded),
                ),
              ),
              const SizedBox(height: 16),
              // A teacher only sees jobs in the subjects they teach, so the
              // spelling here decides who the card reaches. Presets make the
              // common spelling the easy one; "Other" keeps the long tail
              // possible.
              SubjectDropdownField(
                controller: _subjectCtrl,
                label: l10n.jobSubjectsLabel,
                hint: l10n.jobSubjectHint,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _levelCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: l10n.jobLevelLabel,
                  hintText: l10n.jobLevelHint,
                  prefixIcon: const Icon(Icons.school_outlined),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ContractType>(
                initialValue: _contract,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.contractTypeLabel,
                  prefixIcon: const Icon(Icons.schedule_rounded),
                ),
                items: [
                  DropdownMenuItem(
                      value: ContractType.fullTime,
                      child: Text(l10n.contractFullTime)),
                  DropdownMenuItem(
                      value: ContractType.partTime,
                      child: Text(l10n.contractPartTime)),
                  DropdownMenuItem(
                      value: ContractType.contract,
                      child: Text(l10n.contractContract)),
                ],
                onChanged: (v) =>
                    setState(() => _contract = v ?? ContractType.fullTime),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.salaryFrom,
                        prefixText: '${currency.symbol} ',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _maxCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.salaryTo,
                        prefixText: '${currency.symbol} ',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Without this the numbers are ambiguous: 1200 is a good hourly
              // rate and a poor monthly one.
              DropdownButtonFormField<SalaryPeriod>(
                initialValue: _period,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.payPeriodLabel,
                  prefixIcon: const Icon(Icons.event_repeat_rounded),
                ),
                items: [
                  for (final p in SalaryPeriod.values)
                    DropdownMenuItem(value: p, child: Text(p.label(context))),
                ],
                onChanged: (v) =>
                    setState(() => _period = v ?? SalaryPeriod.month),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickStartDate,
                borderRadius: BorderRadius.circular(14),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.startDateLabel,
                    prefixIcon: const Icon(Icons.event_rounded),
                    suffixIcon: _startAt == null
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () => setState(() => _startAt = null),
                          ),
                  ),
                  child: Text(
                    _startAt == null
                        ? l10n.startDateFlexible
                        : DateFormat.yMMMMd(locale).format(_startAt!),
                    style: TextStyle(
                      fontSize: 16,
                      color: _startAt == null ? AppColors.text3 : AppColors.text,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: l10n.jobDescription,
                  alignLabelWithHint: true,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 80),
                    child: Icon(Icons.notes_rounded),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _videoCtrl,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: l10n.jobVideoOptional,
                  hintText: l10n.videoUrlHint,
                  prefixIcon: const Icon(Icons.play_circle_outline_rounded),
                ),
              ),
              const SizedBox(height: 14),
              // No location field, by design — see the class doc.
              if (city.isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 15, color: AppColors.text3),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(l10n.jobLocationNote(city),
                          style: const TextStyle(
                              fontSize: 12.5, color: AppColors.text3)),
                    ),
                  ],
                ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: widget.job == null || widget.job!.isDraft
                    ? l10n.postJob
                    : l10n.saveChanges,
                onPressed: () => _save(draft: false),
                loading: _saving,
              ),
              const SizedBox(height: 10),
              // A draft is saved but not published: teachers never see it.
              // Editing an already-published card offers no draft button — you
              // would be un-publishing something people may already have applied
              // to, which is what "Close" is for.
              if (widget.job == null || widget.job!.isDraft)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => _save(draft: true),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.skyDeeper,
                      side: const BorderSide(color: AppColors.skyLight),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(l10n.saveDraft),
                  ),
                ),
              const SizedBox(height: 8),
              if (widget.job == null || widget.job!.isDraft)
                Center(
                  child: Text(l10n.draftNotVisible,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.text3)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
