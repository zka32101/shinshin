# Animation Widgets - Phase 4 UI/UX Enhancement

Reusable animation components for consistent, performant animations across the Shinshin app.

## Overview

This package provides 6 core animation widgets built on Material Design 3 animation principles:
- **Natural timing**: Curves and durations that feel responsive and smooth
- **Composable**: Stack animations for complex effects
- **Performant**: Optimized for 60fps on medium devices, 24+ fps on low-end devices
- **Accessible**: Respects `MediaQuery.disableAnimations` and provides alternatives

## Components

### 1. AnimatedBounce

Playful elastic entrance animation using `elasticOut` curve.

**Use Cases**: Badge reveals, achievement unlocks, celebration moments

```dart
import 'package:shinshin/widgets/animations/index.dart';

AnimatedBounce(
  duration: AnimationDurations.long,        // 600ms default
  scale: 1.0,                               // Final scale
  delay: Duration(milliseconds: 200),       // Start delay
  onAnimationComplete: () {
    print('Animation complete!');
  },
  child: Badge(unreadCount: 3),
)
```

**Parameters**:
- `child` (required): Widget to animate
- `duration`: Animation duration (default: 600ms)
- `scale`: Final scale value (default: 1.0)
- `delay`: Delay before animation starts (default: 0ms)
- `onAnimationComplete`: Callback when animation finishes (optional)

---

### 2. AnimatedSlideIn

Smooth slide and fade entrance animation with directional support.

**Use Cases**: Content entry, page transitions, expansions, list items appearing

```dart
import 'package:shinshin/widgets/animations/index.dart';

AnimatedSlideIn(
  direction: SlideDirection.fromBottom,     // fromLeft, fromRight, fromTop, fromBottom
  duration: AnimationDurations.medium,      // 300ms default
  offset: 50,                               // Slide distance in pixels
  delay: Duration(milliseconds: 100),
  child: ProfileCard(user: user),
)
```

**Parameters**:
- `child` (required): Widget to animate
- `direction`: Slide direction (default: fromBottom)
- `duration`: Animation duration (default: 300ms)
- `offset`: Distance to slide from (default: 50px)
- `delay`: Delay before animation starts (default: 0ms)
- `onAnimationComplete`: Callback when animation finishes (optional)

**SlideDirection Options**:
- `SlideDirection.fromLeft`: Slide in from left
- `SlideDirection.fromRight`: Slide in from right
- `SlideDirection.fromTop`: Slide in from top
- `SlideDirection.fromBottom`: Slide in from bottom (default)

---

### 3. AnimatedFadeInScale

Combined fade-in and scale animation for smooth card reveals.

**Use Cases**: Story cards, gallery items, achievement cards, UI elements appearing

```dart
import 'package:shinshin/widgets/animations/index.dart';

AnimatedFadeInScale(
  duration: AnimationDurations.medium,      // 300ms default
  beginScale: 0.8,                          // Start scale (default: 0.8)
  endScale: 1.0,                            // End scale (default: 1.0)
  delay: Duration(milliseconds: 50),
  child: StoryCard(story: story),
)
```

**Parameters**:
- `child` (required): Widget to animate
- `duration`: Animation duration (default: 300ms)
- `beginScale`: Initial scale value (default: 0.8)
- `endScale`: Final scale value (default: 1.0)
- `delay`: Delay before animation starts (default: 0ms)
- `onAnimationComplete`: Callback when animation finishes (optional)

---

### 4. AnimatedShake

Horizontal shake animation for error states and attention-grabbing.

**Use Cases**: Form validation errors, warning alerts, shake notifications

```dart
import 'package:shinshin/widgets/animations/index.dart';

AnimatedShake(
  duration: Duration(milliseconds: 400),    // 400ms default
  distance: 10,                             // Shake distance in pixels
  shakes: 4,                                // Number of shake iterations
  child: TextField(
    decoration: InputDecoration(
      border: Border.all(color: Colors.red),
    ),
  ),
)
```

**Parameters**:
- `child` (required): Widget to shake
- `duration`: Animation duration (default: 400ms)
- `distance`: Shake distance in pixels (default: 10)
- `shakes`: Number of shake iterations (default: 4)
- `onAnimationComplete`: Callback when animation finishes (optional)

---

### 5. AnimatedProgressRing

Circular progress indicator with smooth fill animation.

**Use Cases**: Achievement progress, mastery levels, task completion, loading states

```dart
import 'package:shinshin/widgets/animations/index.dart';

AnimatedProgressRing(
  progress: 0.75,                           // 0.0 to 1.0
  duration: AnimationDurations.long,        // 800ms default
  radius: 60,                               // Ring radius in pixels
  strokeWidth: 8,
  color: Colors.green,
  backgroundColor: Colors.grey.shade200,
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      AnimatedCountUp(endValue: 75),
      Text('% Complete'),
    ],
  ),
)
```

**Parameters**:
- `progress` (required): Progress value (0.0 to 1.0)
- `color`: Ring color (default: green)
- `backgroundColor`: Background ring color (default: light grey)
- `strokeWidth`: Ring stroke width (default: 8)
- `radius`: Ring radius (default: 60)
- `duration`: Animation duration (default: 800ms)
- `child`: Widget displayed in center (optional)
- `onAnimationComplete`: Callback when animation finishes (optional)

---

### 6. AnimatedCountUp

Smooth number counter animation for displaying values.

**Use Cases**: Score reveals, statistic displays, achievement counts, dashboard metrics

```dart
import 'package:shinshin/widgets/animations/index.dart';

AnimatedCountUp(
  endValue: 2500,                           // Final number
  startValue: 0,                            // Start number (default: 0)
  duration: AnimationDurations.extraLong,   // 1000ms default
  style: Theme.of(context).textTheme.headline4,
  prefix: 'Points: ',
  suffix: 'pts',
  formatter: (value) => value.withCommas(), // Custom formatting
  onAnimationComplete: () {
    // Celebrate!
  },
)
```

**Parameters**:
- `endValue` (required): Final number value
- `startValue`: Starting number (default: 0)
- `duration`: Animation duration (default: 1000ms)
- `style`: Text style (optional)
- `formatter`: Number formatting function (optional)
- `prefix`: Text before number (default: '')
- `suffix`: Text after number (default: '')
- `onAnimationComplete`: Callback when animation finishes (optional)

**Built-in Formatters**:
```dart
// Format with thousands separator
value.withCommas()  // 2500 → "2,500"

// Format as percentage
value.asPercentage()  // 75 → "75%"

// Format with suffix
value.withSuffix(' points')  // 100 → "100 points"

// Custom formatter
formatter: (value) => 'Level $value'  // 5 → "Level 5"
```

---

## Animation Constants

All animation components use standardized constants from `lib/utils/animation_constants.dart`:

### Durations
```dart
AnimationDurations.superShort   // 100ms - Quick feedback
AnimationDurations.short        // 150ms - Button taps, focus
AnimationDurations.medium       // 300ms - Page changes, cards
AnimationDurations.long         // 600ms - Complex animations
AnimationDurations.extraLong    // 1000ms - Dramatic effects
```

### Curves
```dart
AnimationCurves.easeInOut       // Smooth, natural motion
AnimationCurves.bounceEasing    // Playful, elastic (elasticOut)
AnimationCurves.snappyEasing    // Quick, responsive (fastOutSlowIn)
AnimationCurves.smoothEasing    // Ease-in acceleration
AnimationCurves.linear          // Consistent, uniform motion
AnimationCurves.easeOut         // Exit animations with deceleration
```

---

## Composition Examples

### Staggered List Animation

```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return AnimatedSlideIn(
      delay: Duration(milliseconds: AnimationPatterns.staggerDelay.inMilliseconds * index),
      direction: SlideDirection.fromBottom,
      child: StoryCard(story: items[index]),
    );
  },
)
```

### Achievement Celebration

```dart
Column(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    AnimatedBounce(
      duration: AnimationDurations.long,
      child: Icon(Icons.star, size: 64, color: Colors.amber),
    ),
    SizedBox(height: 20),
    AnimatedCountUp(
      endValue: badgePoints,
      duration: AnimationDurations.extraLong,
      style: Theme.of(context).textTheme.headline3,
    ),
    SizedBox(height: 10),
    AnimatedSlideIn(
      delay: Duration(milliseconds: 400),
      direction: SlideDirection.fromBottom,
      child: Text('Badge Unlocked!'),
    ),
  ],
)
```

### Form Error Feedback

```dart
Column(
  children: [
    TextField(
      decoration: InputDecoration(
        label: Text('Email'),
        border: OutlineInputBorder(
          borderSide: BorderSide(
            color: isError ? Colors.red : Colors.grey,
          ),
        ),
      ),
    ),
    if (isError)
      AnimatedShake(
        child: Text(
          'Invalid email address',
          style: TextStyle(color: Colors.red),
        ),
      ),
  ],
)
```

---

## Performance Considerations

### Best Practices
1. **Use appropriate durations**: Short animations for quick feedback, longer for dramatic effects
2. **Minimize listeners**: Avoid rebuilding entire trees during animations
3. **Layer animations**: Combine simple animations rather than creating complex custom ones
4. **Test on low-end devices**: Verify 24+ fps on Redmi 9 class devices
5. **Respect accessibility**: Honor `MediaQuery.disableAnimations` when possible

### Performance Targets
- **Medium devices** (Pixel 4a+): 60 FPS
- **Low-end devices** (Redmi 9): 24+ FPS
- **Each animation**: < 1MB memory
- **Total animation overhead**: < 5MB

---

## Accessibility

### Built-in Support
- All animations are reversible (no `curve` magic)
- Duration can be adjusted for accessibility needs
- Consider using `MediaQuery.disableAnimations` check:

```dart
if (!MediaQuery.of(context).disableAnimations) {
  return AnimatedBounce(child: widget.child);
} else {
  return widget.child; // Show directly without animation
}
```

---

## Testing

### Unit Tests
```dart
testWidgets('AnimatedBounce animates', (WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AnimatedBounce(
          duration: Duration(milliseconds: 200),
          child: Icon(Icons.star),
        ),
      ),
    ),
  );

  expect(find.byIcon(Icons.star), findsOneWidget);
  
  await tester.pumpAndSettle(Duration(milliseconds: 200));
  // Assert animation state
});
```

### Performance Testing
```bash
flutter test --trace-startup --verbose
```

---

## Migration Guide

### From Custom Animations
Replace custom animation implementations with provided widgets:

```dart
// Before: Custom implementation
class CustomBounceWidget extends StatefulWidget { ... }

// After: Use AnimatedBounce
AnimatedBounce(
  duration: AnimationDurations.long,
  child: widget.child,
)
```

---

## Future Enhancements

Planned additions for Phase 4:
- [ ] AnimatedParallax - Parallax scroll effect
- [ ] AnimatedReveal - Staggered content reveal
- [ ] AnimatedTransform - Combined rotation, scale, translation
- [ ] AnimatedConfetti - Celebratory particle effect
- [ ] AnimatedFlipCard - Card flip effect

---

## Related Documentation

- **Phase 4 Plan**: `PHASE_4_UIUX_PLAN.md`
- **Animation Constants**: `lib/utils/animation_constants.dart`
- **Accessibility Checklist**: `ACCESSIBILITY_CHECKLIST.md` (upcoming)
- **Material Design 3**: https://m3.material.io/

---

**Created**: 2026-09-02  
**Framework Version**: Flutter 3.x  
**Riverpod Integration**: For state-driven animations  
**Status**: Phase 4 - Core Animation Framework Complete ✅
