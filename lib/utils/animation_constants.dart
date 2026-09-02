/// Animation Constants - Standardized timings, curves, and durations
///
/// This module defines all animation constants used throughout the app.
/// By centralizing these values, we ensure consistency and can easily adjust
/// animation feel across the entire application.

import 'package:flutter/material.dart';

/// Animation Duration Constants
///
/// Follows Material Design 3 timing conventions:
/// - Short: 150ms for quick feedback (button taps, focus)
/// - Medium: 300ms for standard transitions (page changes, card reveals)
/// - Long: 600ms for complex animations (chart draws, celebrations)
/// - Extra Long: 1000ms for dramatic effects (count-ups, celebrations)
abstract class AnimationDurations {
  /// Quick feedback for immediate user interaction response
  /// Use for: button presses, checkbox toggling, quick state changes
  static const Duration short = Duration(milliseconds: 150);

  /// Standard transition duration for most UI changes
  /// Use for: page transitions, card animations, focus changes
  static const Duration medium = Duration(milliseconds: 300);

  /// Complex animation duration for elaborate sequences
  /// Use for: chart animations, badge reveals, progress indicators
  static const Duration long = Duration(milliseconds: 600);

  /// Dramatic animation duration for showstopping effects
  /// Use for: count-up animations, celebration sequences, complex reveals
  static const Duration extraLong = Duration(milliseconds: 1000);

  /// Very quick animations for snappy feedback
  static const Duration superShort = Duration(milliseconds: 100);
}

/// Animation Curve Constants
///
/// Different curves for different animation purposes:
/// - easeInOut: Smooth, natural motion (default for most animations)
/// - bounceEasing: Playful, elastic feel (badge reveals, achievements)
/// - snappyEasing: Quick, responsive feel (immediate feedback)
/// - smoothEasing: Ease-in feel (entrance animations)
abstract class AnimationCurves {
  /// Smooth ease-in-out for natural, balanced motion
  /// Best for: general-purpose animations, transitions, state changes
  static const Curve easeInOut = Curves.easeInOut;

  /// Elastic bounce effect for playful, delightful animations
  /// Best for: badge reveals, achievement unlocks, surprise moments
  static const Curve bounceEasing = Curves.elasticOut;

  /// Quick, snappy response for immediate feedback
  /// Best for: button taps, quick toggles, instant responses
  static const Curve snappyEasing = Curves.fastOutSlowIn;

  /// Ease-in for entrance animations with acceleration
  /// Best for: content entering screen, expansions
  static const Curve smoothEasing = Curves.easeInCubic;

  /// Linear for consistent, uniform motion
  /// Best for: progress bars, loading indicators
  static const Curve linear = Curves.linear;

  /// Ease-out for exit animations with deceleration
  /// Best for: content leaving screen, collapses
  static const Curve easeOut = Curves.easeOutCubic;
}

/// Common Animation Sequences
///
/// Pre-defined animation patterns that can be composed together
abstract class AnimationPatterns {
  /// Stagger delay for sequential animations
  /// Each item in a list/grid gets delayed by this amount
  static const Duration staggerDelay = Duration(milliseconds: 100);

  /// Maximum stagger delay (avoid animations lasting too long)
  static const Duration maxStaggerDelay = Duration(milliseconds: 500);

  /// Ripple animation effect
  static const Duration rippleDuration = AnimationDurations.short;

  /// Fade animation (standard opacity change)
  static const Duration fadeDuration = AnimationDurations.medium;

  /// Slide animation (moving across screen)
  static const Duration slideDuration = AnimationDurations.medium;

  /// Scale animation (growing/shrinking)
  static const Duration scaleDuration = AnimationDurations.short;

  /// Rotation animation
  static const Duration rotateDuration = AnimationDurations.long;
}

/// Animation Scale Values
///
/// Commonly used scale values for animations
abstract class AnimationScales {
  /// Default scale for tap animations (slight shrink)
  static const double tapScale = 0.95;

  /// Hover scale for interactive elements
  static const double hoverScale = 1.05;

  /// Emphasis scale for attention-grabbing
  static const double emphasisScale = 1.1;

  /// Subtle scale change
  static const double subtleScale = 0.98;
}

/// Offset Values for Slide Animations
///
/// Pre-defined offsets for common slide directions
abstract class AnimationOffsets {
  /// Slide from bottom (entrance from bottom)
  static const Offset slideUpSmall = Offset(0, 20);
  static const Offset slideUpMedium = Offset(0, 40);
  static const Offset slideUpLarge = Offset(0, 100);

  /// Slide from top (entrance from top)
  static const Offset slideDownSmall = Offset(0, -20);
  static const Offset slideDownMedium = Offset(0, -40);
  static const Offset slideDownLarge = Offset(0, -100);

  /// Slide from left (entrance from left)
  static const Offset slideRightSmall = Offset(-20, 0);
  static const Offset slideRightMedium = Offset(-40, 0);
  static const Offset slideRightLarge = Offset(-100, 0);

  /// Slide from right (entrance from right)
  static const Offset slideLeftSmall = Offset(20, 0);
  static const Offset slideLeftMedium = Offset(40, 0);
  static const Offset slideLeftLarge = Offset(100, 0);
}

/// Rotation Values for Spin Animations
///
/// Common rotation values for spinners and rotations
abstract class AnimationRotations {
  /// Single full rotation (360 degrees)
  static const double fullRotation = 1.0;

  /// Half rotation (180 degrees)
  static const double halfRotation = 0.5;

  /// Quarter rotation (90 degrees)
  static const double quarterRotation = 0.25;
}

/// Shadow Values for Depth Animations
///
/// Shadow elevation values for depth effects
abstract class AnimationShadows {
  /// No shadow
  static const double elevationNone = 0;

  /// Subtle shadow (button hover state)
  static const double elevationSmall = 2;

  /// Standard shadow (card elevation)
  static const double elevationMedium = 4;

  /// Strong shadow (modal elevation)
  static const double elevationLarge = 8;

  /// Maximum shadow (floating action button)
  static const double elevationMax = 12;
}
