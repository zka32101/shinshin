/// Input validation and sanitization utilities for child safety and security.
/// Implements COPPA-compliant validation for user-generated content.

class ValidationUtils {
  /// Maximum length for user-generated text (reflection, etc)
  static const int maxReflectionTextLength = 500;

  /// Validates and sanitizes reflection text input
  /// Returns the sanitized text or null if invalid
  static String? validateReflectionText(String? input) {
    if (input == null) return null;

    // Trim whitespace
    final trimmed = input.trim();

    // Check length constraints
    if (trimmed.isEmpty) return null;
    if (trimmed.length > maxReflectionTextLength) {
      return trimmed.substring(0, maxReflectionTextLength);
    }

    // Sanitize: remove potentially dangerous content
    final sanitized = _sanitizeText(trimmed);

    return sanitized.isEmpty ? null : sanitized;
  }

  /// Removes script tags and other dangerous HTML
  static String _sanitizeText(String text) {
    // Remove script tags
    var result = text.replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false), '');
    // Remove event handlers (onclick, onload, etc.)
    result = result.replaceAll(RegExp(r'on[a-z]+\s*=', caseSensitive: false), '');

    // Remove null bytes
    result = result.replaceAll('\x00', '');

    // Normalize whitespace
    result = result.replaceAll(RegExp(r'\s+'), ' ').trim();

    return result;
  }

  /// Validates sessionId format (UUID v4 or alphanumeric)
  static bool isValidSessionId(String? sessionId) {
    if (sessionId == null || sessionId.isEmpty) return false;
    // Allow UUID v4, ULID, or alphanumeric strings up to 50 chars
    return RegExp(r'^[a-zA-Z0-9\-]{8,50}$').hasMatch(sessionId);
  }

  /// Validates choice ID format
  static bool isValidChoiceId(String? choiceId) {
    if (choiceId == null || choiceId.isEmpty) return false;
    return RegExp(r'^[a-zA-Z0-9\-_]{1,100}$').hasMatch(choiceId);
  }

  /// Validates time spent in seconds
  static bool isValidTimeSpent(int? seconds) {
    if (seconds == null) return false;
    // Between 0 and 24 hours in seconds
    return seconds >= 0 && seconds <= 86400;
  }

  /// Validates child ID format
  static bool isValidChildId(String? childId) {
    if (childId == null || childId.isEmpty) return false;
    return RegExp(r'^[a-zA-Z0-9\-_]{1,50}$').hasMatch(childId);
  }
}
