import 'package:firebase_core/firebase_core.dart';

// Firebase initialization
Future<void> initializeFirebase() async {
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'PLACEHOLDER_FIREBASE_API_KEY',
      appId: 'PLACEHOLDER_FIREBASE_APP_ID',
      messagingSenderId: 'PLACEHOLDER_MESSAGING_SENDER_ID',
      projectId: 'shougaku-kore-doutoku',
      storageBucket: 'shougaku-kore-doutoku.appspot.com',
    ),
  );
}
