import "package:flutter/foundation.dart";
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioService {
  FlutterTts? _flutterTts;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isInitialized = false;
  bool _isInitializing = false;

  AudioService() {
    _initializeTts();
  }

  /// TTSを初期化 — 二重初期化を防ぐためフラグで保護
  Future<void> _initializeTts() async {
    if (_isInitialized || _isInitializing) return;
    _isInitializing = true;
    try {
      _flutterTts ??= FlutterTts();
      await _flutterTts!.setLanguage('ja-JP');
      await _flutterTts!.setSpeechRate(1.0);
      await _flutterTts!.setVolume(0.8);
      _isInitialized = true;
    } catch (e) {
      debugPrint('Failed to initialize TTS: $e');
    } finally {
      _isInitializing = false;
    }
  }

  /// 効果音を再生 (audio_players パッケージで実装)
  Future<void> playSoundEffect(
    String soundName, {
    double volume = 0.8,
  }) async {
    try {
      final volumeClamped = volume.clamp(0.0, 1.0);
      await _audioPlayer.setVolume(volumeClamped);
      await _audioPlayer.play(
        AssetSource('sounds/$soundName.mp3'),
        volume: volumeClamped,
      );
    } catch (e) {
      debugPrint('Failed to play sound effect: $e');
    }
  }

  /// テキストを音声で読み上げ
  Future<void> speak(
    String text, {
    double speed = 1.0,
    double volume = 0.8,
  }) async {
    if (!_isInitialized) {
      await _initializeTts();
    }

    try {
      await _flutterTts?.setSpeechRate(speed);
      await _flutterTts?.setVolume(volume);
      await _flutterTts?.speak(text);
    } catch (e) {
      debugPrint('Failed to speak text: $e');
    }
  }

  /// 音量を設定
  Future<void> setVolume(double volume) async {
    try {
      await _flutterTts?.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      debugPrint('Failed to set volume: $e');
    }
  }

  /// 音声再生を停止
  Future<void> stop() async {
    try {
      await _flutterTts?.stop();
    } catch (e) {
      debugPrint('Failed to stop audio: $e');
    }
  }

  /// 音声再生を一時停止
  Future<void> pause() async {
    try {
      await _flutterTts?.pause();
    } catch (e) {
      debugPrint('Failed to pause audio: $e');
    }
  }

  /// 音声再生を再開
  // Note: FlutterTts doesn't have a resume method, use speak instead
  Future<void> resume() async {
    try {
      // Resume is not available in flutter_tts
      // Re-speaking the text would be required
      debugPrint('Resume not available in current flutter_tts version');
    } catch (e) {
      debugPrint('Failed to resume audio: $e');
    }
  }

  /// リソースを解放
  Future<void> dispose() async {
    try {
      await _flutterTts?.stop();
    } catch (e) {
      debugPrint('Error disposing TTS: $e');
    }
  }
}
