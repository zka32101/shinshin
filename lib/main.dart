import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/home/home_screen.dart';
import 'screens/subscription/trial_status_screen.dart';
import 'screens/subscription/subscription_screen.dart';
import 'screens/settings/avatar_selection_screen.dart';
import 'screens/settings/avatar_shop_screen.dart';
import 'screens/ranking/ranking_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/child_registration_screen.dart';
import 'screens/learning/piano_learning_screen.dart';
import 'screens/learning/drawing_screen.dart';
import 'screens/learning/physical_education_screen.dart';
import 'screens/learning/color_learning_screen.dart';
import 'screens/badge/badge_showcase_screen.dart';
import 'services/logger_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
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
  } catch (e, stackTrace) {
    LoggerService().logError('Firebase initialization error', e, stackTrace);

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

  runApp(
    const ProviderScope(
      child: ShougakuKoreDoutokuApp(),
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

class ShougakuKoreDoutokuApp extends StatelessWidget {
  const ShougakuKoreDoutokuApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '小学コレ！道徳',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/child-registration': (context) => const ChildRegistrationScreen(),
        '/trial_status': (context) => const TrialStatusScreen(),
        '/subscription': (context) => const SubscriptionScreen(),
        '/avatar_selection': (context) => const AvatarSelectionScreen(),
        '/avatar_shop': (context) => const AvatarShopScreen(),
        '/ranking': (context) => const RankingScreen(),
        '/badge_showcase': (context) => const BadgeShowcaseScreen(),
        '/piano': (context) => const PianoLearningScreen(),
        '/drawing': (context) => const DrawingScreen(),
        '/physical_education': (context) => const PhysicalEducationScreen(),
        '/color_learning': (context) => const ColorLearningScreen(),
      },
    );
  }
}
