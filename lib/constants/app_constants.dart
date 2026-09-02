/// Application-wide constants for business logic and magic numbers
class AppConstants {
  // Progress action types
  static const String actionStoryCompleted = 'story_completed';
  static const String actionProgressRecorded = 'progress_recorded';
  static const String actionBadgeEarned = 'badge_earned';

  // Days of week labels (Monday = 0, Sunday = 6)
  static const List<String> dayLabels = ['月', '火', '水', '木', '金', '土', '日'];

  // Week configuration
  static const int daysInWeek = 7;
  static const int firstDayOfWeekOffset = 1; // Monday

  // Score calculation constants
  static const int scoreMinPoints = 10;
  static const int scoreMaxPoints = 25;
  static const int scoreBaseValue = 50;
  static const int scorePointMultiplier = 2;
  static const int scoreMinValue = 0;
  static const int scoreMaxValue = 100;

  // Default score thresholds for virtue display
  static const int scoreThresholdExcellent = 80;
  static const int scoreThresholdGood = 60;
  static const int scoreThresholdFair = 40;

  // Progress estimation values
  static const int estimatedPointsWithChoice = 15;
  static const int estimatedPointsWithoutChoice = 10;

  // Badge-related constants
  static const int maxRecentBadgesDisplayed = 3;

  // UI element constraints
  static const int maxQuizSessionRetries = 3;
  static const double minBarChartHeight = 100;
  static const double barWidth = 24.0;

  // Alpha values for colors
  static const int alphaVeryLight = 15; // ~6% opacity
  static const int alphaLight = 25; // ~10% opacity
  static const int alphaMedium = 50; // ~20% opacity
  static const int alphaDark = 60; // ~24% opacity
  static const int alphaHighlight = 100; // ~39% opacity

  // Story phase constants
  static const String phaseReading = 'reading';
  static const String phaseChoice = 'choice';
  static const String phaseBranching = 'branching';
  static const String phaseReflection = 'reflection';
  static const String phaseComplete = 'complete';

  // User greeting hour boundaries
  static const int morningBoundary = 12;
  static const int afternoonBoundary = 18;
}
