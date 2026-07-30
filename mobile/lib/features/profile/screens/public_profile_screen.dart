import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/firebase/firebase_refs.dart';
import '../../../core/money/currency.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/badge_chip.dart';
import '../../../core/widgets/star_rating.dart';
import '../../../core/extensions/l10n_extension.dart';
import '../../auth/providers/auth_controller.dart';
import '../../matches/data/matches_repository.dart';
import '../../matches/models/chat_models.dart';
import '../../reviews/widgets/reviews_section.dart';
import '../../safety/widgets/safety_menu.dart';
import '../data/profile_repository.dart';
import '../models/user_profile.dart';
import '../widgets/gallery_section.dart';
import '../widgets/video_links_section.dart';

/// Any user's profile as *others* see it — a teacher viewed by a student, or a
/// student viewed by a teacher. Loads `users/{uid}` live; the rules allow any
/// signed-in user to read it. Sections with no data are hidden, so the same
/// screen serves both roles.
class PublicProfileScreen extends ConsumerWidget {
  const PublicProfileScreen({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final profile = ref.watch(userProfileProvider(uid));

    return Scaffold(
      backgroundColor: AppColors.skyBg,
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _NotFound(message: l10n.profileNotFound),
        data: (p) => _Body(profile: p),
      ),
      bottomNavigationBar: profile.hasValue
          ? _BottomBar(profile: profile.requireValue)
          : null,
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_off_outlined,
                      size: 56, color: AppColors.text3),
                  const SizedBox(height: 12),
                  Text(message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.text2)),
                ],
              ),
            ),
          ),
          Positioned(
            top: 8,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final p = profile;
    return CustomScrollView(
      slivers: [
        _appBar(context, p),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section order follows the question a viewer is actually asking,
                // in the order they ask it: *what do they teach* → *who are they*
                // → *what are they like* (the video is the highest-signal thing
                // on the page — you get to hear someone teach) → *are they any
                // good* (qualifications, experience) → *can they fit my week* →
                // *what do others say* → the photos, which are the nicest to look
                // at and the least load-bearing, so they sit at the end.
                //
                // Availability used to be second-to-last, below the fold, even
                // though a schedule clash is the fastest way to rule a teacher
                // out. Now it comes before the social proof, not after it.
                _header(context, l10n, p),
                if (p.subjects.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _section(context, l10n.subjectsLabel, _subjects(p)),
                ],
                if (p.about.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _section(
                    context,
                    l10n.aboutMe,
                    Text(p.about,
                        style: const TextStyle(
                            color: AppColors.text2, fontSize: 14.5, height: 1.6)),
                  ),
                ],
                if (p.videoLinks.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _section(context, l10n.videosLabel,
                      VideoLinksSection(links: p.videoLinks)),
                ],
                if (p.qualifications.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _section(context, l10n.qualificationsLabel, _qualifications(p)),
                ],
                if (p.experience.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _section(context, l10n.tabExperience, _experience(p)),
                ],
                // Availability and Reviews are teacher-only, per the spec
                // ("Teacher Profiles: Bio, Gallery, Qualifications, Teaching
                // Experience, Schedule Availability, Reviews & Ratings").
                // Students have no schedule to set, so rendering an empty grid
                // advertised a feature that does not exist.
                if (p.role == 'teacher') ...[
                  const SizedBox(height: 20),
                  _section(context, l10n.availabilityLabel, _availability(l10n, p)),
                  const SizedBox(height: 20),
                  _section(
                    context,
                    l10n.reviewsLabel,
                    ReviewsSection(targetId: p.uid, targetName: p.displayName),
                  ),
                ],
                if (p.gallery.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _section(context, l10n.tabGallery, GallerySection(paths: p.gallery)),
                ],
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  SliverAppBar _appBar(BuildContext context, UserProfile p) {
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      // Report/block must be reachable from anywhere another person is shown —
      // App Store Guideline 1.2. Burying it in settings does not count.
      actions: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: CircleAvatar(
            backgroundColor: Colors.black38,
            child: SafetyMenu(
              targetUid: p.uid,
              targetName: p.displayName,
              color: Colors.white,
              onBlocked: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ],
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: CircleAvatar(
          backgroundColor: Colors.black38,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 18),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (p.photoUrl.isNotEmpty)
              Image.network(
                p.photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => _avatarFallback(),
              )
            else
              _avatarFallback(),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.5)],
                  stops: const [0.5, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarFallback() => Container(
        color: AppColors.skyLight,
        child: const Icon(Icons.person_rounded, size: 80, color: AppColors.skyDark),
      );

  Widget _header(BuildContext context, dynamic l10n, UserProfile p) {
    final city = p.geoLocation?.city ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(p.displayName,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800)),
        if (city.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on_rounded, size: 14, color: AppColors.text3),
              const SizedBox(width: 3),
              // City, not distance — distance needs the viewer's location and
              // arrives with discovery in Phase 4.
              Text(city, style: const TextStyle(color: AppColors.text2, fontSize: 13)),
            ],
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            // Teachers only. Reviews run one way — a student rates the person
            // teaching them — so a student's stars would be permanently 0.0 (0),
            // which reads as "nobody rated them" rather than "this does not
            // apply". Same gate as the Reviews section below.
            if (p.role == 'teacher') ...[
              RatingRow(
                  rating: p.avgRating.toDouble(),
                  count: p.totalReviews,
                  size: 14),
              const SizedBox(width: 10),
            ],
            BadgeChip(status: p.verified, isFeatured: p.featured),
          ],
        ),
        if (p.hourlyRate != null) ...[
          const SizedBox(height: 10),
          Text(
            Money.perHour(p.hourlyRate!,
                currency: p.currency,
                locale: Localizations.localeOf(context).toString()),
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.skyDeeper),
          ),
        ],
      ],
    );
  }

  Widget _subjects(UserProfile p) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: p.subjects
          .map((s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.skyLight.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(s,
                    style: const TextStyle(
                        color: AppColors.skyDeeper,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ))
          .toList(),
    );
  }


  Widget _qualifications(UserProfile p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: p.qualifications
          .map((q) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.school_rounded, size: 16, color: AppColors.skyDark),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(q,
                            style: const TextStyle(
                                color: AppColors.text2, fontSize: 14))),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _experience(UserProfile p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: p.experience
          .map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.work_outline_rounded,
                        size: 16, color: AppColors.skyDark),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: AppColors.text)),
                          Text(
                            [
                              e.institution,
                              if (e.from.isNotEmpty || e.to.isNotEmpty)
                                '${e.from} – ${e.to}',
                            ].where((s) => s.isNotEmpty).join(' · '),
                            style: const TextStyle(
                                color: AppColors.text3, fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _availability(dynamic l10n, UserProfile p) {
    final days = [l10n.mon, l10n.tue, l10n.wed, l10n.thu, l10n.fri, l10n.sat, l10n.sun];
    const dayKeys = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Row(
      children: List.generate(7, (i) {
        final hasSlots = (p.availability[dayKeys[i]] ?? const {}).isNotEmpty;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: hasSlots
                  ? AppColors.skyDark
                  : AppColors.skyLight.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              days[i],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: hasSlots ? Colors.white : AppColors.text3,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _section(BuildContext context, String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.text,
                letterSpacing: 0.3)),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

/// Pass / Connect belong to *discovery* — they are the swipe deck's verbs, and
/// they make no sense once the two people have already connected. Offering
/// "Connect" to someone you are mid-conversation with is nonsense, and "Pass" on
/// them is worse: it reads like it will undo the match, which it does not (it
/// only closes the screen).
///
/// So: matched → one button, straight into the chat. Not matched → the deck's
/// verbs, which close the screen and hand you back to the cards.
class _BottomBar extends ConsumerWidget {
  const _BottomBar({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final me = Fb.auth.currentUser?.uid;

    // Looking at my own profile from the activity feed: neither pair of verbs
    // applies to me.
    if (me == profile.uid) return const SizedBox.shrink();

    final matches =
        ref.watch(matchesProvider).valueOrNull ?? const <MatchThread>[];
    for (final m in matches) {
      if (m.otherUid == profile.uid) {
        return _MessageBar(match: m, profile: profile);
      }
    }

    // An institution reaches this screen only from a job's applicant list, so
    // "not matched yet" here means "an applicant I haven't connected with" —
    // Connect goes through connectWithApplicant, not the swipe deck's verbs.
    final myRole = ref.watch(authStateProvider).valueOrNull?.role;
    if (myRole == 'institution') {
      return _InstitutionConnectBar(profile: profile, l10n: l10n);
    }

    return _ConnectBar(l10n: l10n);
  }
}

class _MessageBar extends ConsumerWidget {
  const _MessageBar({required this.match, required this.profile});

  final MatchThread match;
  final UserProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final myRole = ref.watch(authStateProvider).valueOrNull?.role;
    final chatRoute = switch (myRole) {
      'teacher' => '/teacher/chat',
      'institution' => '/institution/chat',
      _ => '/student/chat',
    };

    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        border:
            const Border(top: BorderSide(color: AppColors.skyLight, width: 0.8)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -2))
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            elevation: 0,
          ),
          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
          label: Text(l10n.sendMessage),
          onPressed: () => context.push(chatRoute, extra: {
            'matchId': match.matchId,
            'otherName': profile.displayName,
            'otherAvatarUrl': profile.photoUrl,
            'otherUid': profile.uid,
          }),
        ),
      ),
    );
  }
}

class _ConnectBar extends StatelessWidget {
  const _ConnectBar({required this.l10n});

  final dynamic l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        border: const Border(top: BorderSide(color: AppColors.skyLight, width: 0.8)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -2))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.text2,
                side: const BorderSide(color: AppColors.skyLight),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              icon: const Icon(Icons.close_rounded, size: 18),
              label: Text(l10n.passBtn),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                elevation: 0,
              ),
              icon: const Icon(Icons.handshake_rounded, size: 18),
              // Wired to recordSwipe in Phase 4 — for now it just closes.
              label: Text(l10n.connectBtn),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}

/// An institution's Pass/Connect on a job applicant's profile. Connect calls
/// `connectWithApplicant` (server-verified: the teacher must actually have
/// applied to one of this institution's jobs) and, on success, drops straight
/// into the new chat — "start talking with the teacher" is the whole point of
/// connecting, so there is nothing else useful to show first.
class _InstitutionConnectBar extends ConsumerStatefulWidget {
  const _InstitutionConnectBar({required this.profile, required this.l10n});

  final UserProfile profile;
  final dynamic l10n;

  @override
  ConsumerState<_InstitutionConnectBar> createState() =>
      _InstitutionConnectBarState();
}

class _InstitutionConnectBarState
    extends ConsumerState<_InstitutionConnectBar> {
  bool _loading = false;

  Future<void> _connect() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final matchId = await ref
          .read(matchesRepositoryProvider)
          .connectWithApplicant(widget.profile.uid);
      if (!mounted) return;
      context.push('/institution/chat', extra: {
        'matchId': matchId,
        'otherName': widget.profile.displayName,
        'otherAvatarUrl': widget.profile.photoUrl,
        'otherUid': widget.profile.uid,
      });
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? widget.l10n.errorGeneric)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(widget.l10n.errorGeneric)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        border:
            const Border(top: BorderSide(color: AppColors.skyLight, width: 0.8)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -2))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.text2,
                side: const BorderSide(color: AppColors.skyLight),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              icon: const Icon(Icons.close_rounded, size: 18),
              label: Text(l10n.passBtn),
              onPressed: _loading ? null : () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                elevation: 0,
              ),
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.handshake_rounded, size: 18),
              label: Text(l10n.connectBtn),
              onPressed: _loading ? null : _connect,
            ),
          ),
        ],
      ),
    );
  }
}
