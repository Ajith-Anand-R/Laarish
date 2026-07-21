import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/audio/audio_service.dart';
import '../../core/fx/fx.dart';
import '../../core/theme/laarish_colors.dart';

/// Persistent hub navigation — the "Growing Vine Dock".
///
/// Five destinations on a curved leaf dock: Map · Garden · Mentor(AI, center
/// hero) · Badges · Profile. Selecting a tab sprouts a vine + blooms a flower
/// above the icon and springs the icon up; the center Mentor orb pulses and
/// shimmers so the AI is always the eye-catch. Wired only around the hub
/// routes via a ShellRoute (see router.dart) — never shown during splash,
/// onboarding or level play.
class VineShell extends StatelessWidget {
  const VineShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  /// Tab index order — must match the ShellRoute child order.
  static const routes = ['/map', '/garden', '/mentor', '/progress', '/settings'];

  int get _index {
    final i = routes.indexWhere((r) => location.startsWith(r));
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      // extendBody:false — the inner screen sits above the dock; the raised
      // Mentor orb overflows upward over the content edge (Clip.none).
      body: child,
      bottomNavigationBar: VineNavBar(
        currentIndex: _index,
        onTap: (i) {
          if (i != _index) context.go(routes[i]);
        },
      ),
    );
  }
}

class VineNavBar extends StatelessWidget {
  const VineNavBar({super.key, required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _tabs = [
    (icon: Icons.map_rounded, label: 'Map'),
    (icon: Icons.local_florist_rounded, label: 'Garden'),
    (icon: Icons.auto_awesome_rounded, label: 'Mentor'), // center — drawn as orb
    (icon: Icons.insights_rounded, label: 'Progress'),
    (icon: Icons.person_rounded, label: 'Me'),
  ];

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewPadding.bottom;
    const dockH = 76.0;

    return SizedBox(
      height: dockH + inset + 26, // +26 headroom for the raised orb
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // The dock.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              child: ShimmerSweep(
                strength: 0.16,
                period: const Duration(seconds: 7),
                child: Container(
              height: dockH + inset,
              padding: EdgeInsets.only(bottom: inset),
              decoration: BoxDecoration(
                // Three stops so the dock reads as a curved lit surface, not
                // a flat green slab.
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.lerp(LaarishColors.leaf, Colors.white, 0.22)!,
                    LaarishColors.leaf,
                    LaarishColors.leafDeep,
                  ],
                  stops: const [0.0, 0.35, 1.0],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.42), width: 1.8),
                ),
                boxShadow: [
                  BoxShadow(
                    color: LaarishColors.leafDeep.withValues(alpha: 0.55),
                    blurRadius: 24,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < _tabs.length; i++)
                    if (i == 2)
                      const Expanded(child: SizedBox()) // center slot: orb sits in overlay
                    else
                      _TabItem(
                        icon: _tabs[i].icon,
                        label: _tabs[i].label,
                        selected: currentIndex == i,
                        onTap: () => onTap(i),
                      ),
                ],
              ),
                ),
              ),
            ),
          ),
          // Raised center Mentor orb (overlays the middle column).
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: _MentorOrb(
                selected: currentIndex == 2,
                onTap: () => onTap(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One side tab: an icon that springs up on select while a vine sprouts and a
/// flower blooms above it. Bloom/stem grow upward from an end-aligned column so
/// every tab's label stays on the same baseline.
class _TabItem extends StatefulWidget {
  const _TabItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_TabItem> createState() => _TabItemState();
}

class _TabItemState extends State<_TabItem> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
    value: widget.selected ? 1 : 0,
  );

  @override
  void didUpdateWidget(_TabItem old) {
    super.didUpdateWidget(old);
    if (widget.selected != old.selected) {
      widget.selected ? _c.forward() : _c.reverse();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: MagneticTap(
        onTap: () {
          AudioService.instance.play(Sfx.pop);
          widget.onTap();
        },
        spark: true,
        sparkColor: LaarishColors.sunflower,
        sfx: null, // the tab plays its own pop above
        magnetStrength: 4,
        rippleColor: Colors.white.withValues(alpha: 0.4),
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final v = _c.value; // 0..1 linear
            final spring = Curves.easeOutBack.transform(v.clamp(0.0, 1.0));
            final iconColor = Color.lerp(Colors.white.withValues(alpha: 0.72), Colors.white, v)!;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Bloom — reserves a fixed slot so unselected tabs stay aligned.
                SizedBox(
                  height: 16,
                  child: Center(
                    child: CustomPaint(
                      size: const Size.square(16),
                      painter: _BloomPainter(v),
                    ),
                  ),
                ),
                // Vine stem grows from icon up to the bloom.
                Container(width: 2.5, height: 6 * v, color: LaarishColors.paper),
                const SizedBox(height: 2),
                Transform.translate(
                  offset: Offset(0, -3 * spring),
                  child: Transform.scale(
                    scale: 1 + 0.16 * spring,
                    child: Icon(widget.icon, size: 23, color: iconColor),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  widget.label,
                  style: GoogleFonts.baloo2(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: iconColor,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// A five-petal flower that scales (and gently spins) open with [t] 0→1.
class _BloomPainter extends CustomPainter {
  _BloomPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0.01) return;
    final c = size.center(Offset.zero);
    final r = size.width / 2 * t;
    final petal = Paint()..color = LaarishColors.sunflower;
    for (var i = 0; i < 5; i++) {
      final a = i * (2 * pi / 5) - pi / 2 + t * 0.6;
      final o = Offset(c.dx + cos(a) * r * 0.55, c.dy + sin(a) * r * 0.55);
      canvas.drawCircle(o, r * 0.42, petal);
    }
    canvas.drawCircle(c, r * 0.34, Paint()..color = LaarishColors.tomato);
  }

  @override
  bool shouldRepaint(_BloomPainter old) => old.t != t;
}

/// Center AI hero — a glowing orb that pulses and shimmers so the Mentor is
/// always alive. Glow intensifies while it is the active tab.
class _MentorOrb extends StatelessWidget {
  const _MentorOrb({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final orb = MagneticTap(
      onTap: onTap,
      spark: true,
      sparkColor: LaarishColors.sunflower,
      sfx: Sfx.sparkle,
      magnetStrength: 5,
      borderRadius: BorderRadius.circular(999),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [LaarishColors.sunflower, LaarishColors.sunflowerDeep, LaarishColors.leafDeep],
                stops: [0.0, 0.6, 1.0],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 3),
              boxShadow: [
                BoxShadow(
                  color: LaarishColors.sunflower.withValues(alpha: selected ? 0.9 : 0.55),
                  blurRadius: selected ? 22 : 14,
                  spreadRadius: selected ? 2 : 0,
                ),
              ],
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 2),
          Text(
            'Mentor',
            style: GoogleFonts.baloo2(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: LaarishColors.leafDeep,
            ),
          ),
        ],
      ),
    );

    return orb
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.06, 1.06),
          duration: 1500.ms,
          curve: Curves.easeInOut,
        )
        .shimmer(duration: 2200.ms, color: Colors.white.withValues(alpha: 0.5));
  }
}
