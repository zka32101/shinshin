import 'dart:async';

import 'package:cross_promo_kit/cross_promo_kit.dart' show CrossPromoService;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderContainer, UncontrolledProviderScope;
import 'package:shared_core/shared_core.dart'
    show badgeProvider, unifiedBadges, BadgeNotifier;

import 'firebase_options.dart';
import 'providers/lesson_provider.dart' show LessonNotifier, lessonProvider;
import 'providers/theme_provider.dart';
import 'screens/auth/child_registration_screen.dart';
import 'screens/badge/badge_showcase_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/learning/color_learning_screen.dart';
import 'screens/learning/drawing_screen.dart';
import 'screens/learning/physical_education_screen.dart';
import 'screens/learning/piano_learning_screen.dart';
import 'screens/ranking/ranking_screen.dart';
import 'screens/settings/avatar_selection_screen.dart';
import 'screens/settings/avatar_shop_screen.dart';
import 'screens/splash_screen.dart';
import 'services/logger_service.dart';
import 'services/revenue_cat_service.dart';
import 'theme/app_theme.dart';
import 'utils/image_cache_utils.dart';

// Global navigator key for navigation from services (e.g., FCM notifications)
final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  final stopwatch = Stopwatch()..start();

  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize image caching early for better performance
    ImageCacheUtils.configureImageCache();
    LoggerService().log('Image cache configured');

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw TimeoutException(
          'Firebase initialization timeout after 10 seconds. '
          'Check your internet connection and Firebase configuration.',
        );
      },
    );

    LoggerService().log('Firebase initialized successfully');

    // クロスプロモーション初期化
    try {
      await CrossPromoService.init();
    } catch (e) {
      LoggerService().log('CrossPromo initialization skipped: $e');
    }

    // RevenueCat初期化（サブスクリプション管理）
    try {
      await RevenueCatService().initialize();
    } catch (e) {
      LoggerService().log('RevenueCat initialization skipped: $e');
    }

    LoggerService().log('App initialization time: ${stopwatch.elapsedMilliseconds}ms');
  } catch (e, stackTrace) {
    LoggerService().logError('Firebase initialization error', error: e, stackTrace: stackTrace);

    // Show error screen to user instead of crashing
    runApp(
      MaterialApp(
        title: '小学コレ！道徳',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4CAF50),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        home: _ErrorScreen(error: e, stackTrace: stackTrace),
      ),
    );
    return;
  }

  final container = ProviderContainer(
    overrides: [
      // 統一バッジシステム（Phase 4.1）: 道徳コレ用バッジを主題タグで初期化
      badgeProvider.overrideWith(() => BadgeNotifier()),
      // 道徳コレの学習コンテンツ（解説記事）ノティファイアを注入
      lessonProvider.overrideWith(LessonNotifier.new),
    ],
  );

  // バッジシステム初期化: 統一バッジを主題タグで初期化
  container.read(badgeProvider.notifier).setBadgeDefinitions(unifiedBadges, subject: 'morality');

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const ShougakuKoreDoutokuApp(),
    ),
  );
}

/// Error screen shown when Firebase initialization fails
class _ErrorScreen extends StatelessWidget {
  final Object error;
  final StackTrace stackTrace;

  const _ErrorScreen({
    required this.error,
    required this.stackTrace,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Initialization Error'),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 24),
              const Text(
                'Failed to Initialize App',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Error: ${error.toString()}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please check:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                '• Internet connection is active\n'
                '• Firebase credentials are correctly configured\n'
                '• Firebase project is properly set up\n'
                '• Try restarting the app',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  // Restart app
                  main();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Main app widget with theme support
class ShougakuKoreDoutokuApp extends ConsumerWidget {
  const ShougakuKoreDoutokuApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch theme mode and brightness
    ref.watch(initializeThemeProvider);
    final brightness = ref.watch(brightnessProvider);

    return MaterialApp(
      title: '小学コレ！道徳',
      navigatorKey: navigatorKey,
      theme: lightTheme(),
      darkTheme: darkTheme(),
      themeMode: _themeModeToBrightness(brightness),
      home: const SplashScreen(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/child-registration': (context) => const ChildRegistrationScreen(),
        '/avatar_selection': (context) => const AvatarSelectionScreen(),
        '/avatar_shop': (context) => const AvatarShopScreen(),
        '/ranking': (context) => const RankingScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/badge_showcase': (context) => const BadgeShowcaseScreen(),
        '/piano': (context) => const PianoLearningScreen(),
        '/drawing': (context) => const DrawingScreen(),
        '/physical_education': (context) => const PhysicalEducationScreen(),
        '/color_learning': (context) => const ColorLearningScreen(),
      },
    );
  }

  /// Convert brightness to ThemeMode
  static ThemeMode _themeModeToBrightness(Brightness brightness) {
    return brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light;
  }
}
