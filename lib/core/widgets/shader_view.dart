import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Full-bleed animated fragment-shader layer. Loads a `.frag` from the
/// bundle, drives its `uTime` uniform from a repeating controller, and paints
/// it across [size]/available space. Uniform contract (shared by every
/// Laarish shader): float 0 = time seconds, floats 1..2 = resolution xy.
///
/// Fail-soft: if the shader fails to load or compile on a device, [fallback]
/// is shown instead so a screen is never blank or crashing (ARCHITECTURE.md
/// §3.7). GPU fragment work is cheap, so this runs at display rate — the
/// 30fps perf convention is for CPU blur backgrounds, not GPU shaders.
class ShaderView extends StatefulWidget {
  const ShaderView({
    super.key,
    required this.asset,
    this.fallback = const SizedBox.expand(),
    this.opacity = 1.0,
    this.blendMode = BlendMode.srcOver,
    this.extraFloats = const [],
  });

  /// e.g. 'shaders/sky.frag'.
  final String asset;
  final Widget fallback;
  final double opacity;
  final BlendMode blendMode;

  /// Extra float uniforms set at indices 3, 4, 5, … after the shared
  /// time(0)+resolution(1,2) contract — e.g. a biome colour's r,g,b.
  final List<double> extraFloats;

  @override
  State<ShaderView> createState() => _ShaderViewState();
}

class _ShaderViewState extends State<ShaderView> with SingleTickerProviderStateMixin {
  ui.FragmentShader? _shader;
  bool _failed = false;
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 100),
  )..repeat();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final program = await ui.FragmentProgram.fromAsset(widget.asset);
      if (!mounted) return;
      setState(() => _shader = program.fragmentShader());
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return widget.fallback;
    final shader = _shader;
    if (shader == null) return widget.fallback;

    return Opacity(
      opacity: widget.opacity,
      child: AnimatedBuilder(
        animation: _clock,
        builder: (context, _) => CustomPaint(
          size: Size.infinite,
          painter: _ShaderPainter(shader, _clock.value * 100.0, widget.blendMode, widget.extraFloats),
        ),
      ),
    );
  }
}

class _ShaderPainter extends CustomPainter {
  _ShaderPainter(this.shader, this.time, this.blendMode, this.extraFloats);
  final ui.FragmentShader shader;
  final double time;
  final BlendMode blendMode;
  final List<double> extraFloats;

  @override
  void paint(Canvas canvas, Size size) {
    shader
      ..setFloat(0, time)
      ..setFloat(1, size.width)
      ..setFloat(2, size.height);
    for (var i = 0; i < extraFloats.length; i++) {
      shader.setFloat(3 + i, extraFloats[i]);
    }
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = shader
        ..blendMode = blendMode,
    );
  }

  @override
  bool shouldRepaint(covariant _ShaderPainter old) => old.time != time;
}
