import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fin_goal/app/di/injection.dart';
import 'package:fin_goal/core/utils/audio_player_manager.dart';

part 'audio_provider.g.dart';

@riverpod
class AudioNotifier extends _$AudioNotifier {
  @override
  bool build() {
    final prefs = getIt<SharedPreferences>();
    final isMuted = prefs.getBool('sfx_muted') ?? false;
    AudioPlayerManager().setMuted(isMuted);
    return isMuted;
  }

  Future<void> toggleMute() async {
    final newState = !state;
    final prefs = getIt<SharedPreferences>();
    await prefs.setBool('sfx_muted', newState);
    AudioPlayerManager().setMuted(newState);
    state = newState;
  }
}
