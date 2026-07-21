import 'package:flutter/scheduler.dart';

/// Runs an ambient animation at a capped frame rate (default 30fps) while
/// interactive/spring motion elsewhere stays 60fps.
///
/// Project convention: never cut visuals to fix lag on slow-drift ambient
/// layers (background blur, cloud drift, sky shaders) — throttle their
/// update cadence instead. See DESIGN_SYSTEM.md §5 perf convention.
class ThrottledTicker {
  ThrottledTicker(TickerProvider vsync, {this.fps = 30, required this.onTick}) {
    _ticker = vsync.createTicker(_onFrame);
  }

  final int fps;
  final void Function(Duration elapsed) onTick;
  late final Ticker _ticker;
  Duration _lastEmitted = Duration.zero;

  Duration get _frameBudget => Duration(microseconds: 1000000 ~/ fps);

  void _onFrame(Duration elapsed) {
    if (elapsed - _lastEmitted >= _frameBudget) {
      _lastEmitted = elapsed;
      onTick(elapsed);
    }
  }

  void start() => _ticker.start();
  void stop() => _ticker.stop();
  void dispose() => _ticker.dispose();
}
