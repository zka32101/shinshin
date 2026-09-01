import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/home/home_screen.dart';
import 'screens/subscription/trial_status_screen.dart';
import 'screens/subscription/subscription_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const ProviderScope(
      child: ShougakuKoreDoutokuApp(),
    ),
  );
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
      home: const HomeScreen(),
      routes: {
        '/trial_status': (context) => const TrialStatusScreen(),
        '/subscription': (context) => const SubscriptionScreen(),
      },
    );
  }
}
