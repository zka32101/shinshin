import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/audio_service.dart';
import '../services/hive_service.dart';
import './locale_provider.dart';

// ── Hive 永続化ノティファイアー ────────────────────────────────────────────

class _BoolSettingNotifier extends StateNotifier<bool> {
  _BoolSettingNotifier(this._key, bool defaultValue) : super(defaultValue) {
    _load(defaultValue);
  }
  final String _key;
  final _hive = HiveService();

  Future<void> _load(bool fallback) async {
    final v = await _hive.getSetting<bool>(_key);
    if (v != null && mounted) state = v;
  }

  @override
  set state(bool value) {
    super.state = value;
    _hive.saveSetting(_key, value);
  }
}

class _DoubleSettingNotifier extends StateNotifier<double> {
  _DoubleSettingNotifier(this._key, double defaultValue) : super(defaultValue) {
    _load(defaultValue);
  }
  final String _key;
  final _hive = HiveService();

  Future<void> _load(double fallback) async {
    final v = await _hive.getSetting<double>(_key);
    if (v != null && mounted) state = v;
  }

  @override
  set state(double value) {
    super.state = value;
    _hive.saveSetting(_key, value);
  }
}

// ── オーディオ設定プロバイダー（アプリ再起動後も復元） ─────────────────────

/// オーディオサービスプロバイダー
/// ロケール変更に応じてTTS言語を更新
final audioServiceProvider = Provider((ref) {
  final locale = ref.watch(currentLocaleProvider);

  // TTS言語コード: ja -> ja-JP, en -> en-US
  final ttsLanguage = locale.code == 'ja' ? 'ja-JP' : 'en-US';

  final audioService = AudioService(language: ttsLanguage);

  // ロケール変更時にTTS言語を更新
  ref.listen(currentLocaleProvider, (previous, next) {
    final newLanguage = next.code == 'ja' ? 'ja-JP' : 'en-US';
    audioService.setLanguage(newLanguage);
  });

  return audioService;
});

/// 音声再生有効フラグプロバイダー
final isSoundEnabledProvider =
    StateNotifierProvider<_BoolSettingNotifier, bool>(
  (ref) => _BoolSettingNotifier('sound_enabled', true),
);

/// ナレーション有効フラグプロバイダー
final isNarrationEnabledProvider =
    StateNotifierProvider<_BoolSettingNotifier, bool>(
  (ref) => _BoolSettingNotifier('narration_enabled', true),
);

/// 音量レベルプロバイダー (0.0 - 1.0)
final volumeLevelProvider =
    StateNotifierProvider<_DoubleSettingNotifier, double>(
  (ref) => _DoubleSettingNotifier('volume_level', 0.8),
);

/// ナレーション速度プロバイダー
final narrationSpeedProvider =
    StateNotifierProvider<_DoubleSettingNotifier, double>(
  (ref) => _DoubleSettingNotifier('narration_speed', 1.0),
);

/// 現在再生中の音声IDプロバイダー
final currentlyPlayingAudioProvider = StateProvider<String?>((ref) {
  return null;
});

/// オーディオ操作用Notifier
class AudioControllerNotifier extends StateNotifier<void> {
  final AudioService _audioService;
  final Ref _ref;

  AudioControllerNotifier(this._audioService, this._ref) : super(null);

  /// 効果音を再生
  Future<void> playSoundEffect(String soundName) async {
    if (!_ref.read(isSoundEnabledProvider)) return;

    final volume = _ref.read(volumeLevelProvider);
    await _audioService.playSoundEffect(soundName, volume: volume);
  }

  /// テキストをナレーション
  Future<void> speakText(String text, {String? audioId}) async {
    if (!_ref.read(isNarrationEnabledProvider)) return;

    if (audioId != null) {
      _ref.read(currentlyPlayingAudioProvider.notifier).state = audioId;
    }

    final speed = _ref.read(narrationSpeedProvider);
    final volume = _ref.read(volumeLevelProvider);

    await _audioService.speak(
      text,
      speed: speed,
      volume: volume,
    );
  }

  /// 再生を停止
  Future<void> stop() async {
    await _audioService.stop();
    _ref.read(currentlyPlayingAudioProvider.notifier).state = null;
  }

  /// 音量を設定
  void setVolume(double volume) {
    _ref.read(volumeLevelProvider.notifier).state = volume;
    _audioService.setVolume(volume);
  }

  /// ナレーション速度を設定
  void setNarrationSpeed(double speed) {
    _ref.read(narrationSpeedProvider.notifier).state = speed;
  }

  /// 音声再生設定を切り替え
  void toggleSoundEnabled() {
    final current = _ref.read(isSoundEnabledProvider);
    _ref.read(isSoundEnabledProvider.notifier).state = !current;
  }

  /// ナレーション設定を切り替え
  void toggleNarrationEnabled() {
    final current = _ref.read(isNarrationEnabledProvider);
    _ref.read(isNarrationEnabledProvider.notifier).state = !current;
  }
}

/// オーディオコントローラープロバイダー
final audioControllerProvider =
    StateNotifierProvider<AudioControllerNotifier, void>((ref) {
  final audioService = ref.watch(audioServiceProvider);
  return AudioControllerNotifier(audioService, ref);
});
