import 'package:just_audio/just_audio.dart';

/// Sfx enum frozen here (PARALLEL_AGENTS.md §3) — WS7 fills the actual ogg
/// files under assets/audio/sfx/; until then play() no-ops safely.
enum Sfx { tap, pop, reward, sparkle, water, snip, dig, harvestPluck, badgeFanfare, gateCreak }

class AudioService {
  AudioService._();
  static final instance = AudioService._();

  final _bgmPlayer = AudioPlayer();
  final _sfxPlayer = AudioPlayer();
  bool muted = false;

  String _sfxAsset(Sfx sfx) => 'assets/audio/sfx/${sfx.name}.ogg';

  Future<void> playBgm() async {
    if (muted) return;
    try {
      await _bgmPlayer.setAsset('assets/audio/bgm/garden_loop.ogg');
      await _bgmPlayer.setLoopMode(LoopMode.one);
      await _bgmPlayer.play();
    } catch (_) {
      // Asset not shipped yet (WS7) — silence is fine pre-content, never blocks UI.
    }
  }

  Future<void> duckBgm(bool duck) async {
    await _bgmPlayer.setVolume(duck ? 0.25 : 1.0);
  }

  Future<void> play(Sfx sfx) async {
    if (muted) return;
    try {
      await _sfxPlayer.setAsset(_sfxAsset(sfx));
      await _sfxPlayer.play();
    } catch (_) {
      // Same as above — missing asset must never crash an interaction.
    }
  }

  void setMuted(bool value) {
    muted = value;
    if (value) _bgmPlayer.pause();
  }
}
