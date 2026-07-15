import 'package:flutter/material.dart';
import '../models/teacher_card_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/avatar_image.dart';
import '../../../core/widgets/badge_chip.dart';
import '../../safety/widgets/safety_menu.dart';
import '../../../core/widgets/star_rating.dart';
import '../../../core/extensions/l10n_extension.dart';

class SwipeCard extends StatefulWidget {
  const SwipeCard({
    super.key,
    required this.teacher,
    required this.onSwiped,
    required this.onTap,
    this.onBlocked,
    this.isTop = true,
    this.stackOffset = 0,
  });

  final TeacherCardModel teacher;
  final void Function(bool liked) onSwiped;
  final VoidCallback onTap;

  /// Called after this person is blocked — the card must leave the deck.
  final VoidCallback? onBlocked;
  final bool isTop;
  final int stackOffset;

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late Animation<Offset> _anim;
  Offset _offset = Offset.zero;
  bool _animating = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _anim = AlwaysStoppedAnimation(Offset.zero);
    _ctrl.addListener(() {
      if (_animating) setState(() => _offset = _anim.value);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_animating) return;
    setState(() => _offset += d.delta);
  }

  void _onPanEnd(DragEndDetails d) {
    if (_offset.dx.abs() > 90) {
      _flyOff(_offset.dx > 0);
    } else {
      _springBack();
    }
  }

  void _springBack() {
    _animating = true;
    _anim = Tween<Offset>(begin: _offset, end: Offset.zero).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
    _ctrl.forward(from: 0).then((_) {
      if (mounted) setState(() { _offset = Offset.zero; _animating = false; });
    });
  }

  void _flyOff(bool right) {
    _animating = true;
    final target = Offset(right ? 700 : -700, _offset.dy + 80);
    _anim = Tween<Offset>(begin: _offset, end: target).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeIn),
    );
    _ctrl.forward(from: 0).then((_) {
      if (mounted) widget.onSwiped(right);
    });
  }

  double get _rotation => (_offset.dx / 300).clamp(-0.4, 0.4);
  double get _likeOpacity => (_offset.dx / 100).clamp(0, 1);
  double get _passOpacity => (-_offset.dx / 100).clamp(0, 1);

  @override
  Widget build(BuildContext context) {
    final scale = 1.0 - widget.stackOffset * 0.04;
    final yOffset = widget.stackOffset * -14.0;

    if (!widget.isTop) {
      return Transform.translate(
        offset: Offset(0, yOffset),
        child: Transform.scale(scale: scale, child: _buildCard(context)),
      );
    }

    return Transform.translate(
      offset: _offset + Offset(0, yOffset),
      child: Transform.rotate(
        angle: _rotation,
        child: GestureDetector(
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          onTap: widget.onTap,
          child: Stack(
            children: [
              _buildCard(context),
              _buildStamp(context, true,  _likeOpacity),
              _buildStamp(context, false, _passOpacity),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    final l10n = context.l10n;
    final t = widget.teacher;
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AvatarImage(url: t.avatarUrl),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.75)],
                stops: const [0.45, 1.0],
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: BadgeChip(status: t.verifiedStatus, isFeatured: t.isFeatured),
          ),
          // Report/block reachable straight from the deck — a user should not
          // have to open a profile to get away from someone.
          Positioned(
            top: 12,
            right: 12,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.black26,
              child: SafetyMenu(
                targetUid: t.uid,
                targetName: t.name,
                color: Colors.white,
                onBlocked: widget.onBlocked,
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 28,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(t.name,
                    style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: Colors.white70, size: 14),
                    const SizedBox(width: 3),
                    Text(l10n.kmAway(t.distanceKm),
                        style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(width: 12),
                    RatingRow(rating: t.rating, count: t.reviewCount),
                    const SizedBox(width: 12),
                    Text(l10n.yearsExp(t.experienceYears),
                        style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: t.subjects.map((s) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white30),
                    ),
                    child: Text(s, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  )).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStamp(BuildContext context, bool isLike, double opacity) {
    return Positioned(
      top: 48,
      left: isLike ? null : 24,
      right: isLike ? 24 : null,
      child: Opacity(
        opacity: opacity,
        child: Transform.rotate(
          angle: isLike ? 0.3 : -0.3,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: isLike ? Colors.green : AppColors.error, width: 3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              isLike ? 'LIKE' : 'PASS',
              style: TextStyle(
                color: isLike ? Colors.green : AppColors.error,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
