import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers.dart';
import '../../core/theme/laarish_colors.dart';
import '../../core/theme/laarish_spacing.dart';
import '../../core/theme/laarish_text.dart';
import '../../core/widgets/hud_bar.dart';
import '../../core/widgets/laarish_button.dart';
import '../../core/widgets/mascot_view.dart';
import '../../core/widgets/shader_view.dart';
import '../../data/local/entities.dart';
import '../../domain/unlock_policy.dart';
import 'ambient_layer.dart';
import 'garden_path_painter.dart';
import 'level_node.dart';
import 'path_geometry.dart';

/// S8 — flagship screen. Winding garden path (DESIGN_SYSTEM.md §6): parallax
/// biome bands, S-curve vine path, spring-pop level nodes, glowing current
/// node, ambient critters. Unlock gating is untouched from the Phase-0
/// placeholder — only the body visuals changed.
class RoadmapScreen extends ConsumerWidget {
  const RoadmapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final save = ref.watch(gameSaveProvider);

    return Scaffold(
      backgroundColor: LaarishColors.skyTop,
      body: save.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (game) => _RoadmapBody(game: game),
      ),
    );
  }
}

class _RoadmapBody extends StatefulWidget {
  const _RoadmapBody({required this.game});
  final GameSave game;

  @override
  State<_RoadmapBody> createState() => _RoadmapBodyState();
}

class _RoadmapBodyState extends State<_RoadmapBody> {
  final _scrollController = ScrollController();
  bool _didAutoScroll = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final totalHeight = PathGeometry.totalHeight();
    final positions = PathGeometry.allNodeOffsets(width);
    final nodes = _buildNodeData(widget.game, positions);
    final currentIndex = nodes.indexWhere((n) => n.isCurrent);
    final doneCount = nodes.where((n) => n.state == NodeState.done).length;
    final complete = UnlockPolicy.professionComplete(widget.game.plants);

    if (!_didAutoScroll && currentIndex >= 0) {
      _didAutoScroll = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) return;
        final viewport = _scrollController.position.viewportDimension;
        final target = (positions[currentIndex].dy - viewport / 2)
            .clamp(0.0, _scrollController.position.maxScrollExtent);
        _scrollController.animateTo(target,
            duration: const Duration(milliseconds: 700), curve: Curves.easeOutCubic);
      });
    }

    final biome = currentIndex >= 0
        ? nodes[currentIndex].biomeColor
        : (nodes.isNotEmpty ? nodes.first.biomeColor : LaarishColors.tomato);

    return Stack(
      children: [
        // Living GPU background — a flowing, domain-warped biome sky with
        // god-rays and drifting bokeh (roadmap_bg.frag), tinted to the current
        // biome. Fails soft to a rich gradient if the shader can't compile.
        Positioned.fill(
          child: RepaintBoundary(
            child: ShaderView(
              asset: 'shaders/roadmap_bg.frag',
              extraFloats: [biome.r, biome.g, biome.b],
              fallback: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.lerp(biome, Colors.white, 0.45)!,
                      biome,
                      Color.lerp(biome, Colors.black, 0.28)!,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        CustomScrollView(
          controller: _scrollController,
          physics: const _CandyScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(
                height: totalHeight,
                width: width,
                child: Stack(
                  children: [
                    RepaintBoundary(
                      child: CustomPaint(
                        size: Size(width, totalHeight),
                        painter: GardenPathPainter(
                          points: positions,
                          plantOrder: UnlockPolicy.plantOrder,
                          completedThrough: doneCount,
                        ),
                      ),
                    ),
                    for (final node in nodes) ...[
                      if (node.isCurrent)
                        Positioned(
                          left: node.position.dx - 56,
                          top: node.position.dy - 56,
                          child: RepaintBoundary(child: CurrentNodeGlow(color: node.biomeColor)),
                        ),
                      if (node.isCurrent)
                        Positioned(
                          left: node.position.dx - 48,
                          top: node.position.dy - 108,
                          child: RepaintBoundary(
                            child: IgnorePointer(
                              child: MascotView.plant(
                                node.plantId,
                                size: 96,
                                energy: mascotEnergy(node.plantId),
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        left: node.position.dx - LaarishSpacing.minTapTarget / 2,
                        top: node.position.dy - LaarishSpacing.minTapTarget / 2,
                        child: _RevealNode(
                          controller: _scrollController,
                          nodeY: node.position.dy,
                          index: node.index,
                          child: LevelNode(
                            data: node,
                            onTap: () => _openMission(node),
                          ),
                        ),
                      ),
                    ],
                    if (complete)
                      Positioned(
                        left: 0,
                        right: 0,
                        top: positions.last.dy + 110,
                        child: Center(
                          child: LaarishButton(
                            label: 'Claim My Certificate!',
                            color: LaarishColors.sunflowerDeep,
                            onTap: () => context.go('/certificate'),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const RepaintBoundary(child: CritterLayer()),
        // Floating glass HUD.
        SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(LaarishSpacing.md),
              child: _GlassPanel(
                child: HudBar(
                  sunPoints: widget.game.wallet.sunPoints,
                  seedCoins: widget.game.wallet.seedCoins,
                  streak: widget.game.streak.current,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _openMission(LevelNodeData node) {
    if (node.state == NodeState.locked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: LaarishColors.soil,
          content: const Text('Finish the level before this one to unlock it! 🔒'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _MissionSheet(node: node),
    );
  }

  List<LevelNodeData> _buildNodeData(GameSave game, List<Offset> positions) {
    final nodes = <LevelNodeData>[];
    var index = 0;
    var foundCurrent = false;
    for (final plantId in UnlockPolicy.plantOrder) {
      final progress = game.plants[plantId];
      final doneLevels = progress?.levelsDone ?? 0;
      final biomeColor = LaarishColors.biome[plantId] ?? LaarishColors.leafDeep;
      for (var level = 1; level <= 5; level++) {
        final unlocked = UnlockPolicy.levelUnlocked(
          plantId,
          level,
          game.plants,
          professionStarted: game.kitActivated,
        );
        final done = level <= doneLevels;
        final state = done
            ? NodeState.done
            : unlocked
                ? NodeState.unlocked
                : NodeState.locked;
        final isCurrent = !foundCurrent && unlocked && !done;
        if (isCurrent) foundCurrent = true;
        nodes.add(LevelNodeData(
          plantId: plantId,
          level: level,
          index: index,
          state: state,
          stars: (progress?.stars.length ?? 0) >= level ? progress!.stars[level - 1] : 0,
          isCurrent: isCurrent,
          position: positions[index],
          biomeColor: biomeColor,
        ));
        index++;
      }
    }
    return nodes;
  }
}

/// Premium inertial physics for the garden path. Extends [BouncingScrollPhysics]
/// (so momentum + overscroll rubber-band still work cross-platform) but swaps in
/// a softer, slightly heavier spring so a fling settles with a smooth, weighty
/// glide instead of a snappy stop — the Candy-Crush "buttery" feel.
///
/// ponytail: only the bounce-back spring is tuned; the fling glide friction is
/// left at BouncingScrollPhysics' default. Reimplement createBallisticSimulation
/// with a custom FrictionSimulation if a longer/lighter glide is ever needed.
class _CandyScrollPhysics extends BouncingScrollPhysics {
  const _CandyScrollPhysics({super.parent});

  @override
  _CandyScrollPhysics applyTo(ScrollPhysics? ancestor) =>
      _CandyScrollPhysics(parent: buildParent(ancestor));

  @override
  SpringDescription get spring => const SpringDescription(
        mass: 0.65,
        stiffness: 110,
        damping: 19,
      );
}

/// Frosted-glass container for floating UI over the living background.
class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Floating AI-mentor orb — a glowing gradient bubble that pulses to invite a
/// tap, routing to the mock Garden AI (/mentor).
/// Premium mission preview that slides up when a level node is tapped — the new
/// "way in" to a level: shows the goal, reward, stars, then a big Start button.
class _MissionSheet extends StatelessWidget {
  const _MissionSheet({required this.node});
  final LevelNodeData node;

  @override
  Widget build(BuildContext context) {
    final biome = node.biomeColor;
    final name = node.plantId.isEmpty
        ? node.plantId
        : node.plantId[0].toUpperCase() + node.plantId.substring(1);
    final done = node.state == NodeState.done;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(
            LaarishSpacing.lg, LaarishSpacing.md, LaarishSpacing.lg, LaarishSpacing.xl),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [LaarishColors.paper, Color.lerp(LaarishColors.paper, biome, 0.12)!],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(color: LaarishColors.soil.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, -6)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: LaarishColors.soil.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: LaarishSpacing.md),
            Row(
              children: [
                _LevelGem(level: node.level, color: biome),
                const SizedBox(width: LaarishSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$name · Level ${node.level}',
                          style: LaarishText.display22.copyWith(color: LaarishColors.ink)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          for (var i = 0; i < 3; i++)
                            Icon(i < node.stars ? Icons.star_rounded : Icons.star_border_rounded,
                                size: 20, color: LaarishColors.sunflowerDeep),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: LaarishSpacing.md),
            Text(
              done
                  ? 'Replay the lesson video and earn stars again!'
                  : 'Watch the lesson video and help your $name grow to the next stage.',
              style: LaarishText.body16.copyWith(color: LaarishColors.soil),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: LaarishSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _RewardChip(icon: '☀️', label: '+20'),
                const SizedBox(width: LaarishSpacing.sm),
                _RewardChip(icon: '🌿', label: '+5'),
              ],
            ),
            const SizedBox(height: LaarishSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: LaarishButton(
                label: done ? 'Replay Lesson' : 'Start Mission',
                color: biome,
                onTap: () {
                  final router = GoRouter.of(context);
                  Navigator.of(context).pop();
                  router.go('/level/${node.plantId}/${node.level}');
                },
              ),
            ),
          ],
        ),
      ),
    ).animate().slideY(begin: 1, end: 0, duration: 380.ms, curve: Curves.easeOutCubic).fadeIn(duration: 280.ms);
  }
}

/// A glossy 3D gem showing the level number, tinted to the biome.
class _LevelGem extends StatelessWidget {
  const _LevelGem({required this.level, required this.color});
  final int level;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.4),
          colors: [Color.lerp(color, Colors.white, 0.45)!, color],
        ),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 14, offset: const Offset(0, 5)),
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 2.5),
      ),
      child: Center(
        child: Text('$level',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 24,
              shadows: [Shadow(color: Colors.black26, blurRadius: 3)],
            )),
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  const _RewardChip({required this.icon, required this.label});
  final String icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: LaarishColors.paperDeep),
        boxShadow: [BoxShadow(color: LaarishColors.soil.withValues(alpha: 0.12), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(label, style: LaarishText.body16.copyWith(fontWeight: FontWeight.w800, color: LaarishColors.ink)),
        ],
      ),
    );
  }
}

/// Scroll-driven reveal — as a node rises into view it animates in with a
/// style that varies by its journey index, so the path never feels static:
/// fall-in, swing from the left, swing from the right, zoom from depth, and
/// spin-pop, cycling every five nodes. Once a node is fully settled it drops
/// the entrance matrix + [Opacity] entirely and pays only a cheap depth
/// [Transform.scale] (nodes nearer the viewport centre sit fractionally
/// "closer"), so steady-state scrolling never triggers a per-node saveLayer.
/// Each node is its own [RepaintBoundary] so a node repaint never dirties the
/// path painter or its siblings behind it.
class _RevealNode extends StatelessWidget {
  const _RevealNode({
    required this.controller,
    required this.nodeY,
    required this.index,
    required this.child,
  });

  final ScrollController controller;
  final double nodeY;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.sizeOf(context).height;
    final boundaried = RepaintBoundary(child: child);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        // `hasClients` is not enough: on a fresh mount (e.g. reward → /map) the
        // position is attached but not yet laid out, so `pixels`/
        // `viewportDimension` are still null and reading them throws
        // (null-check) — which cascades into the red-screen element-tree
        // asserts. Require the dimensions to actually exist before reading.
        final ready = controller.hasClients &&
            controller.position.hasPixels &&
            controller.position.hasViewportDimension;
        final offset = ready ? controller.offset : 0.0;
        final vh = ready ? controller.position.viewportDimension : screenH;
        final screenY = nodeY - offset;
        final raw = ((vh - screenY) / (vh * 0.5)).clamp(0.0, 1.0);
        final p = Curves.easeOutCubic.transform(raw);

        // Dynamic depth: nodes crossing the viewport centre read slightly
        // "closer" (subtle, cheap, no saveLayer). ~0.94 at the edges, ~1.03
        // dead-centre.
        final centreDist = ((screenY - vh / 2) / (vh / 2)).abs().clamp(0.0, 1.0);
        final depth = 1.03 - 0.09 * Curves.easeOut.transform(centreDist);

        // Fully settled + on/above screen: skip the entrance matrix and the
        // Opacity wrapper — just the depth scale. This is the steady state for
        // most visible nodes, so it must stay a single lightweight Transform.
        if (p >= 0.999) {
          return Transform.scale(scale: depth, child: child);
        }

        final inv = 1 - p;
        final m = Matrix4.identity()..setEntry(3, 2, 0.0016);
        switch (index % 5) {
          case 0: // fall in from above with a forward tilt
            m
              ..translateByDouble(0, -90 * inv, 0, 1)
              ..rotateX(0.5 * inv);
          case 1: // swing in from the left
            m
              ..translateByDouble(-150 * inv, 0, 0, 1)
              ..rotateY(0.7 * inv);
          case 2: // swing in from the right
            m
              ..translateByDouble(150 * inv, 0, 0, 1)
              ..rotateY(-0.7 * inv);
          case 3: // zoom up from depth
            final s = (0.4 + 0.6 * p) * depth;
            m.scaleByDouble(s, s, 1, 1);
          default: // spin-pop
            final s = (0.3 + 0.7 * p) * depth;
            m
              ..rotateZ(0.8 * inv)
              ..scaleByDouble(s, s, 1, 1);
        }
        // Cases 0/1/2 fold the depth scale in on top of their translate/rotate.
        if (index % 5 < 3) m.scaleByDouble(depth, depth, 1, 1);

        return Opacity(
          opacity: p,
          child: Transform(alignment: Alignment.center, transform: m, child: child),
        );
      },
      child: boundaried,
    );
  }
}
