/// 徳目（virtue）定義と関連データの定数
class VirtueConstants {
  // 徳目の種類
  static const String kindness = 'kindness';
  static const String honesty = 'honesty';
  static const String responsibility = 'responsibility';
  static const String courage = 'courage';
  static const String respect = 'respect';
  static const String cooperation = 'cooperation';

  /// 徳目のemoji マッピング — 単一の真実のソース
  static const Map<String, String> virtueEmojiMap = {
    kindness: '💜',
    honesty: '💛',
    responsibility: '💙',
    courage: '❤️',
    respect: '💚',
    cooperation: '🧡',
  };

  /// 徳目の日本語ラベル
  static const Map<String, String> virtueLabelMap = {
    kindness: '思いやり',
    honesty: '正直',
    responsibility: '責任',
    courage: '勇気',
    respect: '礼儀',
    cooperation: '協力',
  };

  /// 徳目のemoji を取得（デフォルト⭐）
  static String getVirtueEmoji(String? value) {
    return virtueEmojiMap[value] ?? '⭐';
  }

  /// 徳目の日本語ラベルを取得
  static String getVirtueLabel(String? value) {
    return virtueLabelMap[value] ?? value ?? '不明';
  }
}
