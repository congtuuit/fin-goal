import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class AudioPlayerManager {
  static final AudioPlayerManager _instance = AudioPlayerManager._internal();
  factory AudioPlayerManager() => _instance;
  
  AudioPlayerManager._internal();

  final AudioPlayer _bgmPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  bool _isMuted = false;

  Future<void> init() async {
    // Tạm thời có thể set volume hoặc pre-load các file
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
  }

  void setMuted(bool muted) {
    _isMuted = muted;
    if (_isMuted) {
      _bgmPlayer.pause();
    } else {
      _bgmPlayer.resume();
    }
  }

  /// Phát nhạc nền
  Future<void> playBgm(String assetPath) async {
    if (_isMuted) return;
    try {
      await _bgmPlayer.play(AssetSource(assetPath));
    } catch (e) {
      // Ignored if asset missing
    }
  }

  /// Phát âm thanh hiệu ứng (Xúc xắc, Ting ting)
  Future<void> playSfx(String assetPath) async {
    if (_isMuted) return;
    try {
      await _sfxPlayer.play(AssetSource(assetPath));
    } catch (e) {
      // Ignored if asset missing
    }
  }

  /// Rung điện thoại khi cần
  void vibrate() {
    HapticFeedback.heavyImpact();
  }
}
