import 'emoji_constants.dart';

/// Virtue names and their associated metadata
/// Provides consistent strings, colors, and emojis for all virtues
class VirtueStrings {
  // Virtue IDs
  static const String kindness = 'kindness';
  static const String honesty = 'honesty';
  static const String courage = 'courage';
  static const String respect = 'respect';
  static const String cooperation = 'cooperation';
  static const String responsibility = 'responsibility';

  // Virtue Japanese labels
  static const Map<String, String> labels = {
    kindness: '思いやり',
    honesty: '正直',
    courage: '勇気',
    respect: '礼儀',
    cooperation: '協力',
    responsibility: '責任',
  };

  // Virtue color mappings
  static const Map<String, int> colors = {
    kindness: 0xFFFF69B4,  // Pink
    honesty: 0xFFFFD700,   // Yellow
    courage: 0xFFFF6347,   // Red
    respect: 0xFF90EE90,   // Green
    cooperation: 0xFFFFA500, // Orange
    responsibility: 0xFF87CEEB, // Blue
  };

  // Virtue emoji mappings
  static const Map<String, String> emojis = {
    kindness: EmojiConstants.kindnessEmoji,
    honesty: EmojiConstants.honestyEmoji,
    courage: EmojiConstants.courageEmoji,
    respect: EmojiConstants.respectEmoji,
    cooperation: EmojiConstants.cooperationEmoji,
    responsibility: EmojiConstants.responsibilityEmoji,
  };

  /// Get the Japanese label for a virtue
  static String getLabel(String virtue) => labels[virtue] ?? virtue;

  /// Get the color for a virtue
  static int getColorValue(String virtue) => colors[virtue] ?? 0xFF9B59B6;

  /// Get the emoji for a virtue
  static String getEmoji(String virtue) => emojis[virtue] ?? '⭐';

  /// Get all virtue keys
  static const List<String> allVirtues = [
    kindness,
    honesty,
    courage,
    respect,
    cooperation,
    responsibility,
  ];
}
