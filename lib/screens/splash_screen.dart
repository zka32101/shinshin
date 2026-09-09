import 'package:flutter/material.dart';
import 'package:shared_core/widgets/components/app_card.dart';
import 'package:shared_core/widgets/components/app_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/story_provider.dart';
import '../providers/child_provider.dart';
import '../utils/image_cache_utils.dart';
import '../utils/performance_utils.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    // Precache common assets and run startup flow
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Precache common UI assets while splash is visible
    try {
      if (mounted) {
        await ImageCacheUtils.precacheCommonAssets(context);
      }
    } catch (_) {
      // Non-blocking, continue with startup
    }

    // スプラッシュを最低 1.5 秒は表示してから起動フロー開始
    Future.delayed(const Duration(milliseconds: 1500), _runStartupFlow);
  }

  /// 起動フロー: 認証確認 → JWT交換 → 子どもチェック → 適切な画面へ遷移
  Future<void> _runStartupFlow() async {
    if (!mounted || _navigated) return;

    // Firebase 認証状態を確認（まだ読み込み中なら再試行）
    final authState = ref.read(userAuthStateProvider);
    if (authState is AsyncLoading) {
      await Future.delayed(const Duration(milliseconds: 300));
      return _runStartupFlow();
    }

    final user = authState.asData?.value;
    if (user == null) {
      // 未ログイン → 匿名認証で自動サインイン
      try {
        await ref.read(firebaseServiceProvider).signInAnonymously();
      } catch (_) {
        // 匿名認証に失敗（オフライン等）→ ゲストモードでホームへ
        _navigated = true;
        if (mounted) Navigator.of(context).pushReplacementNamed('/home');
        return;
      }
      // authStateChanges の反映を待って起動フローを再試行
      await Future.delayed(const Duration(milliseconds: 300));
      return _runStartupFlow();
    }

    // Firebase ID トークンをバックエンド JWT に交換
    final api = ref.read(apiServiceProvider);
    try {
      final idToken = await user.getIdToken();
      if (idToken != null) {
        final result = await api.loginWithFirebase(idToken);
        final jwt = result['accessToken'] as String?;
        if (jwt != null) api.setAuthToken(jwt);
      }
    } catch (_) {
      // JWT 取得失敗（ネットワーク不調等）→ ゲストモードでホームへ
      _navigated = true;
      if (mounted) Navigator.of(context).pushReplacementNamed('/home');
      return;
    }

    // 子どもプロフィールの存在を確認してルーティング
    try {
      final children = await api.fetchChildrenProfiles();
      if (!mounted) return;
      _navigated = true;
      if (children.isNotEmpty) {
        // 最初の子どもを選択状態にしてホームへ
        ref.read(currentChildIdProvider.notifier).state = children.first.id;
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        // 子どもがいない → 子ども登録画面へ
        Navigator.of(context).pushReplacementNamed('/child-registration');
      }
    } catch (_) {
      // API エラー (ネットワーク不調など) → ゲストモードでホームへ
      _navigated = true;
      if (mounted) Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9FF),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF9B59B6), Color(0xFF8E44AD)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9B59B6).withAlpha(80),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Text('📖', style: TextStyle(fontSize: 50)),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '小学コレ！道徳',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'かっこいい大人になるために',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              strokeWidth: 3,
              color: Color(0xFF9B59B6),
            ),
          ],
        ),
      ),
    );
  }
}
