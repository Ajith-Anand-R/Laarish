import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/ai/mentor_service.dart';
import '../../core/theme/laarish_colors.dart';
import '../../core/theme/laarish_spacing.dart';
import '../../core/theme/laarish_text.dart';
import '../../core/widgets/laarish_button.dart';
import '../../core/widgets/mascot_view.dart';
import '../../core/widgets/sticker_card.dart';

/// S? — Garden AI Mentor (mock). A child can ask the mascot questions, "upload"
/// a plant photo for a canned diagnosis, and cycle a daily tip. This is a
/// FRONTEND MOCK: no network, no real ML. Canned Q&A lives here; the photo
/// diagnosis and daily tip are wired to [MentorService] (LocalMentorService)
/// so the seam swaps for a real cloud model later without touching this UI.
class MentorScreen extends ConsumerStatefulWidget {
  const MentorScreen({super.key});

  @override
  ConsumerState<MentorScreen> createState() => _MentorScreenState();
}

class _MentorScreenState extends ConsumerState<MentorScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this)
    ..addListener(() => setState(() {}));

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LaarishColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              onBack: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/map');
                }
              },
            ),
            _MentorTabBar(controller: _tabs),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: const [
                  _AskTab(),
                  _PhotoTab(),
                  _DailyTipTab(),
                ],
              ),
            ),
            const _DemoNote(),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────── header + chrome

class _Header extends StatelessWidget {
  const _Header({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LaarishSpacing.md,
        LaarishSpacing.md,
        LaarishSpacing.md,
        LaarishSpacing.sm,
      ),
      child: Row(
        children: [
          _RoundIcon(icon: Icons.arrow_back_rounded, onTap: onBack),
          const SizedBox(width: LaarishSpacing.sm),
          MascotView.plant('methi', size: 48, animate: false),
          const SizedBox(width: LaarishSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Garden AI Mentor', style: LaarishText.display22),
                Text(
                  'Your friendly plant helper',
                  style: LaarishText.body16.copyWith(
                    color: LaarishColors.soil,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const _AiBadge(),
        ],
      ),
    );
  }
}

class _AiBadge extends StatelessWidget {
  const _AiBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: const LinearGradient(
          colors: [LaarishColors.sunflower, LaarishColors.chiliFlame],
        ),
        boxShadow: [
          BoxShadow(
            color: LaarishColors.sunflowerDeep.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('✨', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Text(
            'AI powered',
            style: LaarishText.body16.copyWith(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(duration: 1800.ms, color: Colors.white.withValues(alpha: 0.5));
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: LaarishColors.bubble,
          shape: BoxShape.circle,
          border: Border.all(color: LaarishColors.soil.withValues(alpha: 0.15), width: 2),
        ),
        child: Icon(icon, color: LaarishColors.ink),
      ),
    );
  }
}

class _MentorTabBar extends StatelessWidget {
  const _MentorTabBar({required this.controller});
  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: LaarishSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: LaarishColors.paperDeep,
          borderRadius: BorderRadius.circular(999),
        ),
        child: TabBar(
          controller: controller,
          indicator: BoxDecoration(
            color: LaarishColors.leaf,
            borderRadius: BorderRadius.circular(999),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: LaarishColors.soil,
          labelStyle: LaarishText.body16.copyWith(fontSize: 13, fontWeight: FontWeight.w800),
          unselectedLabelStyle: LaarishText.body16.copyWith(fontSize: 13),
          tabs: const [
            Tab(text: 'Ask'),
            Tab(text: 'My Plant'),
            Tab(text: 'Daily Tip'),
          ],
        ),
      ),
    );
  }
}

class _DemoNote extends StatelessWidget {
  const _DemoNote();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: LaarishSpacing.sm, top: 2),
      child: Text(
        'Demo mode — friendly practice answers, not a real diagnosis 🌱',
        style: LaarishText.body16.copyWith(
          fontSize: 11,
          color: LaarishColors.soil.withValues(alpha: 0.7),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────── 1. Ask a Q

class _AskTab extends ConsumerStatefulWidget {
  const _AskTab();

  @override
  ConsumerState<_AskTab> createState() => _AskTabState();
}

class _AskTabState extends ConsumerState<_AskTab> {
  final _rng = math.Random();
  final _scroll = ScrollController();
  final _input = TextEditingController();
  final List<_Msg> _messages = [
    const _Msg('Hi! I\'m your garden buddy 🌻 Ask me anything about your plants!', true),
  ];
  bool _thinking = false;

  static const _chips = [
    'Why are the leaves yellow?',
    'How much water?',
    'When will it flower?',
    'Is it getting enough sun?',
  ];

  @override
  void dispose() {
    _scroll.dispose();
    _input.dispose();
    super.dispose();
  }

  Future<void> _send(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || _thinking) return;
    _input.clear();
    setState(() {
      _messages.add(_Msg(text, false));
      _thinking = true;
    });
    _scrollToEnd();
    // A small, varied "thinking" beat so the mentor feels alive.
    await Future<void>.delayed(Duration(milliseconds: 900 + _rng.nextInt(700)));
    if (!mounted) return;
    setState(() {
      _messages.add(_Msg(_answerFor(text), true));
      _thinking = false;
    });
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    });
  }

  /// Canned, plant-friendly answers. Keyword-matched with a warm fallback —
  /// no method for this on MentorService, so it lives here per scope.
  String _answerFor(String q) {
    final s = q.toLowerCase();
    if (s.contains('yellow') || s.contains('leaf') || s.contains('leaves')) {
      return 'Yellow leaves usually mean too much water or too little sun. '
          'Let the top soil dry a little, and move your pot somewhere bright. 🌤️';
    }
    if (s.contains('water') || s.contains('thirsty')) {
      return 'Most seedlings love a morning drink — just enough to keep the soil '
          'damp, never soggy. Poke a finger in: dry means water, wet means wait. 💧';
    }
    if (s.contains('flower') || s.contains('fruit') || s.contains('harvest')) {
      return 'Patience, little gardener! Flowers come once your plant is strong '
          'and happy — usually a few weeks in. Keep caring and watch closely. 🌸';
    }
    if (s.contains('sun') || s.contains('light')) {
      return 'Bright, gentle light is best — a sunny windowsill is perfect. '
          '6 hours of light a day keeps your plant smiling. ☀️';
    }
    if (s.contains('bug') || s.contains('pest') || s.contains('spot')) {
      return 'Tiny bugs? Wipe the leaves with a soft damp cloth and check under '
          'them each morning. Catching them early keeps your plant safe. 🐛';
    }
    return 'Great question! Keep the soil damp, give it bright light, and check '
        'on your plant a little every day — that\'s the secret every gardener knows. 🌱';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.all(LaarishSpacing.md),
            itemCount: _messages.length + (_thinking ? 1 : 0),
            itemBuilder: (context, i) {
              if (i == _messages.length) return const _TypingBubble();
              final m = _messages[i];
              return _ChatRow(msg: m)
                  .animate()
                  .fadeIn(duration: 250.ms)
                  .slideY(begin: 0.15, end: 0, curve: Curves.easeOut);
            },
          ),
        ),
        // Suggested-question chips.
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: LaarishSpacing.md),
            itemCount: _chips.length,
            separatorBuilder: (_, _) => const SizedBox(width: LaarishSpacing.sm),
            itemBuilder: (context, i) => _QuestionChip(
              label: _chips[i],
              onTap: _thinking ? null : () => _send(_chips[i]),
            ),
          ),
        ),
        _Composer(controller: _input, onSend: () => _send(_input.text), enabled: !_thinking),
      ],
    );
  }
}

class _Msg {
  const _Msg(this.text, this.fromAi);
  final String text;
  final bool fromAi;
}

class _ChatRow extends StatelessWidget {
  const _ChatRow({required this.msg});
  final _Msg msg;

  @override
  Widget build(BuildContext context) {
    final ai = msg.fromAi;
    final bubble = Flexible(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(
          horizontal: LaarishSpacing.md,
          vertical: LaarishSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: ai ? LaarishColors.bubble : LaarishColors.sunflower,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(ai ? 4 : 18),
            bottomRight: Radius.circular(ai ? 18 : 4),
          ),
          border: Border.all(color: LaarishColors.soil.withValues(alpha: 0.15), width: 2),
        ),
        child: Text(msg.text, style: LaarishText.body16),
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: ai ? MainAxisAlignment.start : MainAxisAlignment.end,
      children: [
        if (ai) ...[
          MascotView.plant('methi', size: 36, animate: false),
          const SizedBox(width: LaarishSpacing.sm),
        ],
        bubble,
      ],
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        MascotView.plant('methi', size: 36, animate: false),
        const SizedBox(width: LaarishSpacing.sm),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(
            horizontal: LaarishSpacing.md,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: LaarishColors.bubble,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(18),
            ),
            border: Border.all(color: LaarishColors.soil.withValues(alpha: 0.15), width: 2),
          ),
          child: const _TypingDots(),
        ),
      ],
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++) ...[
            _dot(i),
            if (i < 2) const SizedBox(width: 5),
          ],
        ],
      ),
    );
  }

  Widget _dot(int i) {
    final phase = (_c.value + i * 0.18) % 1.0;
    final t = (math.sin(phase * 2 * math.pi) + 1) / 2;
    return Transform.translate(
      offset: Offset(0, -3 * t),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: LaarishColors.leaf.withValues(alpha: 0.35 + 0.55 * t),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _QuestionChip extends StatelessWidget {
  const _QuestionChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final on = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: LaarishSpacing.md),
        decoration: BoxDecoration(
          color: on ? LaarishColors.bubble : LaarishColors.paperDeep,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: LaarishColors.leaf.withValues(alpha: 0.5), width: 2),
        ),
        child: Text(
          label,
          style: LaarishText.body16.copyWith(
            fontSize: 13,
            color: on ? LaarishColors.leafDeep : LaarishColors.soil,
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.onSend, required this.enabled});
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LaarishSpacing.md,
        LaarishSpacing.sm,
        LaarishSpacing.md,
        LaarishSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: LaarishColors.bubble,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: LaarishColors.soil.withValues(alpha: 0.15), width: 2),
              ),
              child: TextField(
                controller: controller,
                enabled: enabled,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                style: LaarishText.body16,
                decoration: InputDecoration(
                  hintText: 'Type your question…',
                  hintStyle: LaarishText.body16.copyWith(
                    color: LaarishColors.soil.withValues(alpha: 0.6),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: LaarishSpacing.md,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: LaarishSpacing.sm),
          GestureDetector(
            onTap: enabled ? onSend : null,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [LaarishColors.leaf, LaarishColors.leafDeep],
                ),
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────── 2. Check plant

class _PhotoTab extends ConsumerStatefulWidget {
  const _PhotoTab();

  @override
  ConsumerState<_PhotoTab> createState() => _PhotoTabState();
}

enum _PhotoState { empty, analyzing, done }

class _PhotoTabState extends ConsumerState<_PhotoTab> {
  // Cycle plants so the wired feedback reads differently each "scan".
  static const _plants = ['tommy', 'okki', 'chilly', 'methi'];
  final _rng = math.Random();

  _PhotoState _state = _PhotoState.empty;
  MentorFeedback? _result;
  int _scanCount = 0;

  Future<void> _analyze() async {
    if (_state == _PhotoState.analyzing) return;
    setState(() {
      _state = _PhotoState.analyzing;
      _result = null;
    });
    // Wired to MentorService (LocalMentorService) — the seam a real vision
    // model drops into later. hasPhoto:true so it praises the "upload".
    final plant = _plants[_scanCount % _plants.length];
    final feedback = await ref.read(mentorServiceProvider).feedbackForProgress(
          plantId: plant,
          level: 1 + _rng.nextInt(5),
          hasPhoto: true,
        );
    // Extra beat so the shimmer reads as "analyzing".
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _result = feedback;
      _state = _PhotoState.done;
      _scanCount++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(LaarishSpacing.md),
      children: [
        Text('Check my plant 📸', style: LaarishText.display22),
        const SizedBox(height: 4),
        Text(
          'Add a photo and I\'ll take a look!',
          style: LaarishText.body16.copyWith(color: LaarishColors.soil),
        ),
        const SizedBox(height: LaarishSpacing.md),
        _DropZone(state: _state, onTap: _analyze),
        const SizedBox(height: LaarishSpacing.md),
        if (_state == _PhotoState.done && _result != null)
          _DiagnosisCard(feedback: _result!)
              .animate()
              .fadeIn(duration: 300.ms)
              .scale(begin: const Offset(0.92, 0.92), curve: Curves.easeOutBack),
        if (_state == _PhotoState.done) ...[
          const SizedBox(height: LaarishSpacing.md),
          Center(
            child: LaarishButton(
              label: 'Scan another',
              icon: Icons.refresh_rounded,
              color: LaarishColors.leaf,
              onTap: _analyze,
            ),
          ),
        ],
      ],
    );
  }
}

class _DropZone extends StatelessWidget {
  const _DropZone({required this.state, required this.onTap});
  final _PhotoState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final analyzing = state == _PhotoState.analyzing;
    return GestureDetector(
      onTap: analyzing ? null : onTap,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: LaarishColors.leaf.withValues(alpha: 0.6),
          radius: LaarishSpacing.cardRadius,
        ),
        child: Container(
          height: 200,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: LaarishColors.leaf.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(LaarishSpacing.cardRadius),
          ),
          child: analyzing ? const _AnalyzingView() : const _EmptyDropContent(),
        ),
      ),
    );
  }
}

class _EmptyDropContent extends StatelessWidget {
  const _EmptyDropContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.add_a_photo_rounded, size: 48, color: LaarishColors.leaf)
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(begin: const Offset(1, 1), end: const Offset(1.12, 1.12), duration: 1200.ms),
        const SizedBox(height: LaarishSpacing.sm),
        Text('Tap to add a photo', style: LaarishText.body18),
        Text(
          'of your plant',
          style: LaarishText.body16.copyWith(color: LaarishColors.soil),
        ),
      ],
    );
  }
}

class _AnalyzingView extends StatelessWidget {
  const _AnalyzingView();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 120,
          height: 96,
          decoration: BoxDecoration(
            color: LaarishColors.paperDeep,
            borderRadius: BorderRadius.circular(16),
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .shimmer(
              duration: 1100.ms,
              color: Colors.white.withValues(alpha: 0.7),
            ),
        const SizedBox(height: LaarishSpacing.md),
        Text('Analyzing your plant…', style: LaarishText.body18),
      ],
    );
  }
}

class _DiagnosisCard extends StatelessWidget {
  const _DiagnosisCard({required this.feedback});
  final MentorFeedback feedback;

  @override
  Widget build(BuildContext context) {
    return StickerCard(
      color: LaarishColors.leaf.withValues(alpha: 0.1),
      padding: const EdgeInsets.all(LaarishSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: LaarishColors.leafDeep),
              const SizedBox(width: LaarishSpacing.sm),
              Expanded(child: Text(feedback.headline, style: LaarishText.display22.copyWith(fontSize: 20))),
            ],
          ),
          const SizedBox(height: LaarishSpacing.sm),
          Text(feedback.body, style: LaarishText.body16),
          const SizedBox(height: LaarishSpacing.sm),
          Container(
            padding: const EdgeInsets.all(LaarishSpacing.sm),
            decoration: BoxDecoration(
              color: LaarishColors.bubble,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Text('💡 ', style: TextStyle(fontSize: 16)),
                Expanded(
                  child: Text(
                    feedback.tip,
                    style: LaarishText.body16.copyWith(color: LaarishColors.leafDeep),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────── 3. Daily tip

class _DailyTipTab extends ConsumerStatefulWidget {
  const _DailyTipTab();

  @override
  ConsumerState<_DailyTipTab> createState() => _DailyTipTabState();
}

class _DailyTipTabState extends ConsumerState<_DailyTipTab> {
  late String _tip = ref.read(mentorServiceProvider).dailyTip(null);
  int _spin = 0;

  void _refresh() {
    setState(() {
      _tip = ref.read(mentorServiceProvider).dailyTip(null);
      _spin++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(LaarishSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('Tip of the day', style: LaarishText.display22),
              const SizedBox(width: LaarishSpacing.sm),
              const _AiBadge(),
            ],
          ),
          const SizedBox(height: LaarishSpacing.md),
          StickerCard(
            color: LaarishColors.sunflower.withValues(alpha: 0.15),
            padding: const EdgeInsets.all(LaarishSpacing.lg),
            child: Column(
              children: [
                MascotView.plant('tommy', size: 96, glow: true),
                const SizedBox(height: LaarishSpacing.md),
                // Re-keyed so the tip springs in on every refresh.
                Text(
                  _tip,
                  key: ValueKey(_spin),
                  style: LaarishText.body18,
                  textAlign: TextAlign.center,
                )
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),
              ],
            ),
          ),
          const SizedBox(height: LaarishSpacing.lg),
          Center(
            child: LaarishButton(
              label: 'New tip',
              icon: Icons.refresh_rounded,
              color: LaarishColors.sunflowerDeep,
              onTap: _refresh,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────── painter

/// Dashed rounded-rect stroke for the photo drop-zone. No dash support in the
/// framework's Border, so we walk the rounded path and paint alternating dashes.
class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius});
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rect);
    const dash = 9.0;
    const gap = 7.0;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}
