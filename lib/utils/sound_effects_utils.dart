import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/sound_constants.dart';
import '../providers/audio_provider.dart';

/// 効果音管理のユーティリティ
/// Riverpodプロバイダーと連携して音声設定を尊重
class SoundEffectsUtils {
  final Ref<dynamic> ref;

  SoundEffectsUtils(Ref<dynamic> ref) : ref = ref;

  /// 効果音を再生（設定に応じて自動的に有効/無効を切り替え）
  Future<void> playSound(String soundName) async {
    // 音声が有効かチェック
    final isSoundEnabled = ref.read(isSoundEnabledProvider);
    if (!isSoundEnabled) {
      return;
    }

    // 音量を取得
    final volumeLevel = ref.read(volumeLevelProvider);

    // オーディオサービスを取得してプロバイダー経由で再生
    final audioService = ref.read(audioServiceProvider);
    await audioService.playSoundEffect(soundName, volume: volumeLevel);
  }

  /// UI ボタンタップ音
  Future<void> playButtonTapSound() => playSound(SoundConstants.buttonTap);

  /// メニュースワイプ音
  Future<void> playMenuSwipeSound() => playSound(SoundConstants.menuSwipe);

  /// ページ遷移音
  Future<void> playPageTransitionSound() => playSound(SoundConstants.pageTransition);

  /// ストーリー開始音
  Future<void> playStoryStartSound() => playSound(SoundConstants.storyStart);

  /// 選択肢決定音
  Future<void> playChoiceMadeSound() => playSound(SoundConstants.choiceMade);

  /// ストーリー完了音
  Future<void> playStoryCompleteSound() => playSound(SoundConstants.storyComplete);

  /// バッジアンロック音
  Future<void> playBadgeUnlockSound() => playSound(SoundConstants.badgeUnlock);

  /// ポイント獲得音
  Future<void> playPointsEarnedSound() => playSound(SoundConstants.pointsEarned);

  /// アチーブメント獲得音
  Future<void> playAchievementUnlockSound() => playSound(SoundConstants.achievementUnlock);

  /// 通知音
  Future<void> playNotificationSound() => playSound(SoundConstants.notification);

  /// エラー音
  Future<void> playErrorSound() => playSound(SoundConstants.error);

  /// 成功音
  Future<void> playSuccessSound() => playSound(SoundConstants.success);
}
