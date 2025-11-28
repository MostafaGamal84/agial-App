import 'package:audioplayers/audioplayers.dart';

class SoundEffects {
  SoundEffects._();

  static final AudioPlayer _claimPlayer = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop);
  static final AudioPlayer _correctPlayer = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop);

  static Future<void> playClaim() async {
    try {
      await _claimPlayer.stop();
      await _claimPlayer.play(AssetSource('sounds/claim.mp3'));
    } catch (_) {}
  }

  static Future<void> playCorrect() async {
    try {
      await _correctPlayer.stop();
      await _correctPlayer.play(AssetSource('sounds/correct.mp3'));
    } catch (_) {}
  }
}
