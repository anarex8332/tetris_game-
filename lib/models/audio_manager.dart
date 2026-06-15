import 'package:audioplayers/audioplayers.dart';

/// Менеджер звуковых эффектов.
class AudioManager {
  static final AudioManager _instance = AudioManager._();
  factory AudioManager() => _instance;
  AudioManager._();

  bool muted = false;

  final AudioPlayer _player = AudioPlayer();

  void playMove() => _play('sounds/move.wav');
  void playRotate() => _play('sounds/rotate.wav');
  void playDrop() => _play('sounds/drop.wav');
  void playClear(int lines) => _play('sounds/clear1.wav');
  void playTetris() => _play('sounds/tetris.wav');
  void playGameOver() => _play('sounds/gameover.wav');

  Future<void> _play(String path) async {
    if (muted) return;
    try {
      await _player.stop();
      await _player.play(AssetSource(path));
    } catch (_) {}
  }
}
