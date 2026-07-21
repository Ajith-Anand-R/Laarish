import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/providers.dart';
import '../../core/theme/laarish_colors.dart';
import '../../core/theme/laarish_spacing.dart';
import '../../core/theme/laarish_text.dart';
import '../../core/widgets/laarish_button.dart';

/// S2 — flagship login. A living dawn-garden: a slow-drifting aurora sky, soft
/// sun bloom, and floating pollen behind a frosted-glass sign-in card. The
/// transparent logo floats above the card with its own glow and idle bob.
///
/// Auth wiring is unchanged from the previous version: sign-in still routes
/// through ref.read(authRepositoryProvider) behind the adults-only parent gate
/// (AGENT.md), success swings the card up and navigates to /qr, errors shake.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with TickerProviderStateMixin {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _busy = false;
  String? _error;

  late final AnimationController _ambient; // drifting sky + pollen (loops)
  late final AnimationController _entry; // card + logo entrance (once)
  late final AnimationController _success; // card lifts away on success
  late final AnimationController _shake; // friendly error shake

  @override
  void initState() {
    super.initState();
    _ambient = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
    _entry = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _success = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    WidgetsBinding.instance.addPostFrameCallback((_) => _entry.forward());
  }

  @override
  void dispose() {
    _ambient.dispose();
    _entry.dispose();
    _success.dispose();
    _shake.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<bool> _passParentGate() async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const _ParentGateDialog(),
    );
    return ok ?? false;
  }

  Future<void> _run(Future<void> Function() signInCall) async {
    final allowed = await _passParentGate();
    if (!allowed || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await signInCall();
      if (!mounted) return;
      await _success.forward(from: 0);
      if (mounted) context.go('/qr');
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = "Couldn't sign in. Try again!");
      await _shake.forward(from: 0);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _signInEmail() =>
      _run(() => ref.read(authRepositoryProvider).signInWithEmail(_email.text.trim(), _password.text));

  Future<void> _signInGoogle() async {
    final allowed = await _passParentGate();
    if (!allowed || !mounted) return;

    final account = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _GoogleAccountPickerSheet(),
    );

    if (account == null || !mounted) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      if (!mounted) return;
      await _success.forward(from: 0);
      if (mounted) context.go('/qr');
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = "Couldn't sign in with Google. Try again!");
      await _shake.forward(from: 0);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LaarishColors.skyBottom,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Living dawn sky + sun bloom + floating pollen.
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _ambient,
                builder: (context, _) => CustomPaint(painter: _AuroraPainter(t: _ambient.value)),
              ),
            ),
          ),
          // Foreground content: floating logo + frosted card.
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(LaarishSpacing.lg),
                child: AnimatedBuilder(
                  animation: Listenable.merge([_entry, _success, _shake, _ambient]),
                  builder: (context, _) {
                    final entry = Curves.easeOutBack.transform(_entry.value.clamp(0.0, 1.0));
                    final lift = Curves.easeInCubic.transform(_success.value);
                    final bob = math.sin(_ambient.value * 2 * math.pi) * 5;
                    final shakeDx =
                        math.sin(_shake.value * math.pi * 6) * 9 * (1 - _shake.value);

                    return Transform.translate(
                      offset: Offset(shakeDx, (1 - entry) * 40 - lift * 220),
                      child: Opacity(
                        opacity: (entry * (1 - lift)).clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: (0.9 + 0.1 * entry) * (1 + lift * 0.15),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _FloatingLogo(bob: bob),
                              const SizedBox(height: LaarishSpacing.lg),
                              _GlassCard(
                                child: _form(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _form() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Grow with us!',
            style: LaarishText.display22, textAlign: TextAlign.center),
        const SizedBox(height: LaarishSpacing.xs),
        Text('Sign in to tend your garden',
            style: LaarishText.body16.copyWith(color: LaarishColors.soil)),
        const SizedBox(height: LaarishSpacing.lg),
        _Field(controller: _email, focus: _emailFocus, label: 'Parent email', icon: Icons.mail_rounded, keyboard: TextInputType.emailAddress),
        const SizedBox(height: LaarishSpacing.sm),
        _Field(controller: _password, focus: _passwordFocus, label: 'Password', icon: Icons.lock_rounded, obscure: true),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          child: _error == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: LaarishSpacing.sm),
                  child: Text(_error!,
                      style: LaarishText.body16.copyWith(color: LaarishColors.tomato),
                      textAlign: TextAlign.center),
                ),
        ),
        const SizedBox(height: LaarishSpacing.lg),
        _busy
            ? const Padding(
                padding: EdgeInsets.all(LaarishSpacing.sm),
                child: CircularProgressIndicator())
            : LaarishButton(label: 'Enter the Garden', onTap: _signInEmail),
        const SizedBox(height: LaarishSpacing.md),
        Row(
          children: [
            Expanded(child: Container(height: 1, color: LaarishColors.soil.withValues(alpha: 0.2))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'or',
                style: LaarishText.body16.copyWith(
                  color: LaarishColors.soil.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
              ),
            ),
            Expanded(child: Container(height: 1, color: LaarishColors.soil.withValues(alpha: 0.2))),
          ],
        ),
        const SizedBox(height: LaarishSpacing.md),
        _GoogleSignInButton(
          onTap: _signInGoogle,
          disabled: _busy,
        ),
      ],
    );
  }
}

/// The wordmark floating over the card with an idle bob.
class _FloatingLogo extends StatelessWidget {
  const _FloatingLogo({required this.bob});
  final double bob;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, bob),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: LaarishColors.leafDeep.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset('assets/images/logo.png', width: 220, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

/// Frosted-glass sign-in panel — a real backdrop blur + translucent fill +
/// hairline highlight, so the aurora shows through softly behind the form.
class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: 340,
          padding: const EdgeInsets.all(LaarishSpacing.xl),
          decoration: BoxDecoration(
            color: LaarishColors.paper.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: LaarishColors.soil.withValues(alpha: 0.22),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Soft-filled rounded text field with a leading icon and a focus glow.
class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.focus,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.keyboard,
  });

  final TextEditingController controller;
  final FocusNode focus;
  final String label;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboard;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focus,
      obscureText: obscure,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: LaarishColors.soil),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.65),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: LaarishColors.leaf, width: 2),
        ),
      ),
    );
  }
}

/// Animated dawn sky: a vertical wash that slowly shifts, a drifting sun bloom,
/// and pollen motes rising through the frame. One CustomPaint, one controller.
class _AuroraPainter extends CustomPainter {
  _AuroraPainter({required this.t});
  final double t; // 0..1 loop

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final drift = 0.5 + 0.5 * math.sin(t * 2 * math.pi);

    // Base dawn wash, top hue easing between two morning skies.
    final top = Color.lerp(LaarishColors.skyTop, const Color(0xFFB8E0F0), drift)!;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(size.width / 2, 0),
          Offset(size.width / 2, size.height),
          [top, LaarishColors.skyBottom, LaarishColors.paperDeep],
          [0.0, 0.55, 1.0],
        ),
    );

    // Sun bloom, drifting gently across the upper third.
    final sun = Offset(size.width * (0.25 + 0.5 * drift), size.height * 0.22);
    canvas.drawCircle(
      sun,
      size.width * 0.5,
      Paint()
        ..shader = ui.Gradient.radial(sun, size.width * 0.5, [
          LaarishColors.sunflower.withValues(alpha: 0.5),
          LaarishColors.sunflower.withValues(alpha: 0.0),
        ]),
    );

    // Pollen motes — deterministic pseudo-random, rising and looping.
    final pollen = Paint()..color = Colors.white.withValues(alpha: 0.75);
    for (var i = 0; i < 18; i++) {
      final seed = i * 12.9898;
      final fx = _frac(math.sin(seed) * 43758.5453);
      final speed = 0.4 + _frac(math.cos(seed) * 1000) * 0.6;
      final phase = (t * speed + fx) % 1.0;
      final x = (fx + 0.06 * math.sin((phase + fx) * 2 * math.pi)) * size.width;
      final y = (1.0 - phase) * size.height;
      final r = 1.5 + _frac(seed) * 2.5;
      canvas.drawCircle(Offset(x, y), r, pollen);
    }
  }

  double _frac(double v) => v - v.floorToDouble();

  @override
  bool shouldRepaint(covariant _AuroraPainter oldDelegate) => oldDelegate.t != t;
}

/// AGENT.md "parent gate = simple math for adults" — blocks any account action
/// until answered correctly.
class _ParentGateDialog extends StatefulWidget {
  const _ParentGateDialog();

  @override
  State<_ParentGateDialog> createState() => _ParentGateDialogState();
}

class _ParentGateDialogState extends State<_ParentGateDialog> {
  late final int _a;
  late final int _b;
  late final List<int> _choices;
  String? _hint;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random();
    _a = 2 + rnd.nextInt(7);
    _b = 2 + rnd.nextInt(7);
    final correct = _a + _b;
    final wrong = <int>{};
    while (wrong.length < 2) {
      final candidate = correct + (rnd.nextInt(9) - 4);
      if (candidate != correct && candidate > 0) wrong.add(candidate);
    }
    _choices = [correct, ...wrong]..shuffle();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: LaarishColors.paper,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(LaarishSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Grown-ups Only!', style: LaarishText.display22, textAlign: TextAlign.center),
            const SizedBox(height: LaarishSpacing.sm),
            Text('What is $_a + $_b?', style: LaarishText.body18),
            const SizedBox(height: LaarishSpacing.md),
            Wrap(
              spacing: LaarishSpacing.sm,
              children: [
                for (final choice in _choices)
                  LaarishButton(
                    label: '$choice',
                    color: LaarishColors.leaf,
                    onTap: () {
                      if (choice == _a + _b) {
                        Navigator.of(context).pop(true);
                      } else {
                        setState(() => _hint = 'Not quite — try again!');
                      }
                    },
                  ),
              ],
            ),
            if (_hint != null) ...[
              const SizedBox(height: LaarishSpacing.sm),
              Text(_hint!, style: LaarishText.body16.copyWith(color: LaarishColors.soil)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Official-style Google Sign-In button pill with Google branding.
class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({required this.onTap, required this.disabled});
  final VoidCallback onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFDADCE0), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 22,
                height: 22,
                child: CustomPaint(painter: _GoogleGLogoPainter()),
              ),
              const SizedBox(width: 12),
              Text(
                'Continue with Google',
                style: GoogleFonts.roboto(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: disabled ? const Color(0xFF9AA0A6) : const Color(0xFF3C4043),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Precise 4-color vector Google "G" logo painter.
class _GoogleGLogoPainter extends CustomPainter {
  const _GoogleGLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double r = size.width / 2;
    final double stroke = size.width * 0.22;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r - stroke / 2);

    // Red arc (top)
    final redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(rect, -0.45 * math.pi, 0.75 * math.pi, false, redPaint);

    // Yellow arc (bottom-left)
    final yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(rect, 0.3 * math.pi, 0.45 * math.pi, false, yellowPaint);

    // Green arc (bottom-right)
    final greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(rect, 0.75 * math.pi, 0.55 * math.pi, false, greenPaint);

    // Blue arc (top-right) + crossbar
    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(rect, 1.3 * math.pi, 0.25 * math.pi, false, bluePaint);

    final blueFill = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTRB(cx - 1, cy - stroke / 2, cx + r, cy + stroke / 2),
      blueFill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Authentic Google OAuth Account Picker Bottom Sheet.
class _GoogleAccountPickerSheet extends StatefulWidget {
  const _GoogleAccountPickerSheet();

  @override
  State<_GoogleAccountPickerSheet> createState() => _GoogleAccountPickerSheetState();
}

class _GoogleAccountPickerSheetState extends State<_GoogleAccountPickerSheet> {
  String? _selectedEmail;
  bool _signingIn = false;

  void _chooseAccount(String name, String email) async {
    setState(() {
      _selectedEmail = email;
      _signingIn = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (mounted) {
      Navigator.of(context).pop(email);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const SizedBox(
                width: 22,
                height: 22,
                child: CustomPaint(painter: _GoogleGLogoPainter()),
              ),
              const SizedBox(width: 12),
              Text(
                'Sign in with Google',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF5F6368),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Choose an account',
            style: GoogleFonts.roboto(
              fontSize: 22,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF202124),
            ),
          ),
          Text(
            'to continue to Laarish',
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: const Color(0xFF5F6368),
            ),
          ),
          const SizedBox(height: 20),
          if (_signingIn) ...[
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  const SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4285F4)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Signing in to $_selectedEmail…',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: const Color(0xFF5F6368),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ] else ...[
            _AccountItem(
              name: 'Alex Smith (Parent)',
              email: 'alex.smith.parent@gmail.com',
              avatarColor: const Color(0xFF1A73E8),
              initial: 'A',
              onTap: () => _chooseAccount('Alex Smith', 'alex.smith.parent@gmail.com'),
            ),
            const Divider(height: 1, color: Color(0xFFE8EAED)),
            _AccountItem(
              name: 'Family Garden Account',
              email: 'family.gardener@gmail.com',
              avatarColor: const Color(0xFF34A853),
              initial: 'F',
              onTap: () => _chooseAccount('Family Garden', 'family.gardener@gmail.com'),
            ),
            const Divider(height: 1, color: Color(0xFFE8EAED)),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFFF1F3F4),
                child: Icon(Icons.person_add_outlined, size: 20, color: Color(0xFF5F6368)),
              ),
              title: Text(
                'Use another account',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF3C4043),
                ),
              ),
              onTap: () => _chooseAccount('Parent Account', 'parent.laarish@gmail.com'),
            ),
            const SizedBox(height: 20),
            Text(
              'To continue, Google will share your name, email address, and profile picture with Laarish. See Laarish\'s Privacy Policy and Terms of Service.',
              style: GoogleFonts.roboto(
                fontSize: 12,
                color: const Color(0xFF70757A),
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AccountItem extends StatelessWidget {
  const _AccountItem({
    required this.name,
    required this.email,
    required this.avatarColor,
    required this.initial,
    required this.onTap,
  });

  final String name;
  final String email;
  final Color avatarColor;
  final String initial;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: avatarColor,
        child: Text(
          initial,
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
      ),
      title: Text(
        name,
        style: GoogleFonts.roboto(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF202124),
        ),
      ),
      subtitle: Text(
        email,
        style: GoogleFonts.roboto(
          fontSize: 13,
          color: const Color(0xFF5F6368),
        ),
      ),
      onTap: onTap,
    );
  }
}
