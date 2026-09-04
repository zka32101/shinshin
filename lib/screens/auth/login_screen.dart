import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../providers/story_provider.dart';
import '../../providers/child_provider.dart';
import '../../utils/animation_constants.dart';
import '../../widgets/animations/index.dart';
import 'email_login_screen.dart';
import 'email_register_screen.dart';

const _primaryColor = Color(0xFF9B59B6);

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9FF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: AnimatedFadeInScale(
            duration: AnimationDurations.medium, // 300ms fade + scale in
            beginScale: 0.95,
            endScale: 1.0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const SizedBox(height: 48),

                  // ─── ロゴ＆タイトル ───
                  AnimatedBounce(
                    duration: AnimationDurations.long,
                    scale: 1.0,
                    delay: Duration(milliseconds: 100),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_primaryColor, Color(0xFF8E44AD)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: _primaryColor.withAlpha(80),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text('📖', style: TextStyle(fontSize: 40)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  AnimatedSlideIn(
                    direction: SlideDirection.fromBottom,
                    duration: AnimationDurations.medium,
                    delay: Duration(milliseconds: 200),
                    child: Column(
                      children: const [
                        Text(
                          '小学コレ！道徳',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: _primaryColor,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'かっこいい大人になるために',
                          style: TextStyle(fontSize: 14, color: Color(0xFF888888)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ─── キャッチコピー ───
                  AnimatedSlideIn(
                    direction: SlideDirection.fromBottom,
                    duration: AnimationDurations.medium,
                    delay: Duration(milliseconds: 300),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E5F5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _primaryColor.withAlpha(40)),
                      ),
                      child: const Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('👨‍👩‍👧', style: TextStyle(fontSize: 24)),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'お子さんの成長を一緒に見守ろう',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            '小学3-4年生対象\n選択肢型ストーリーで道徳を楽しく学習',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: Color(0xFF666666), height: 1.6),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // ─── ログインボタン群 ───
                  if (_isLoading)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Column(
                        children: const [
                          CircularProgressIndicator(color: _primaryColor),
                          SizedBox(height: 12),
                          Text(
                            'ログイン中...',
                            style: TextStyle(color: _primaryColor, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    // Google ログイン
                    AnimatedSlideIn(
                      direction: SlideDirection.fromBottom,
                      duration: AnimationDurations.medium,
                      delay: Duration(milliseconds: 400),
                      child: _AuthButton(
                        onPressed: () => _googleSignIn(context),
                        backgroundColor: Colors.white,
                        borderColor: const Color(0xFFDDDDDD),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF4285F4),
                              ),
                              child: const Center(
                                child: Text('G',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Google でログイン',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF333333),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // メールログイン
                    AnimatedSlideIn(
                      direction: SlideDirection.fromBottom,
                      duration: AnimationDurations.medium,
                      delay: Duration(milliseconds: 500),
                      child: _AuthButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const EmailLoginScreen()),
                        ),
                        backgroundColor: _primaryColor,
                        child: const Text(
                          'メールアドレスでログイン',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 新規登録
                    AnimatedSlideIn(
                      direction: SlideDirection.fromBottom,
                      duration: AnimationDurations.medium,
                      delay: Duration(milliseconds: 600),
                      child: _AuthButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const EmailRegisterScreen()),
                        ),
                        backgroundColor: Colors.transparent,
                        borderColor: _primaryColor,
                        child: const Text(
                          '新規登録（無料）',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // ─── フッター ───
                  Text(
                    'ログインすることで利用規約・プライバシーポリシーに同意したことになります。\n'
                    'このアプリはCOPPA準拠・子どもの個人情報を保護します。',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _googleSignIn(BuildContext context) async {
    setState(() => _isLoading = true);
    // context はコールバック前に保存
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      // 1. Google アカウント選択画面を表示
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // ユーザーがキャンセルした
        return;
      }

      // 2. Google 認証トークンを取得
      final googleAuth = await googleUser.authentication;

      // 3. Firebase 認証情報を作成してサインイン
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      // 4. バックエンドに Firebase IDToken を送ってバックエンド JWT を取得
      final api = ref.read(apiServiceProvider);
      final idToken = await userCredential.user?.getIdToken();
      if (idToken != null) {
        final result = await api.loginWithFirebase(idToken);
        final jwt = result['accessToken'] as String?;
        if (jwt != null) api.setAuthToken(jwt);
      }

      if (!mounted) return;

      // 5. 子どもプロフィールの存在を確認してルーティング
      try {
        final children = await api.fetchChildrenProfiles();
        if (!mounted) return;
        if (children.isNotEmpty) {
          ref.read(currentChildIdProvider.notifier).state = children.first.id;
          navigator.pushReplacementNamed('/home');
        } else {
          navigator.pushReplacementNamed('/child-registration');
        }
      } catch (_) {
        if (mounted) navigator.pushReplacementNamed('/home');
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Googleログインに失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _AuthButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Color backgroundColor;
  final Color? borderColor;

  const _AuthButton({
    required this.onPressed,
    required this.child,
    required this.backgroundColor,
    this.borderColor,
  });

  @override
  State<_AuthButton> createState() => _AuthButtonState();
}

class _AuthButtonState extends State<_AuthButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AnimationDurations.superShort, // 100ms
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: AnimationCurves.snappyEasing),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _onTapUp(TapUpDetails _) {
    setState(() => _isPressed = false);
    _controller.reverse();
    widget.onPressed();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GestureDetector(
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: _isPressed
                  ? [
                      BoxShadow(
                        color: Colors.black.withAlpha(40),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withAlpha(20),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: ElevatedButton(
              onPressed: null, // Handled by GestureDetector
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.backgroundColor,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: widget.borderColor != null
                      ? BorderSide(color: widget.borderColor!)
                      : BorderSide.none,
                ),
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
