import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/story_provider.dart';
import '../../providers/child_provider.dart';
import '../../utils/animation_constants.dart';
import '../../widgets/animations/index.dart';
import 'email_register_screen.dart';

class EmailLoginScreen extends ConsumerStatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  ConsumerState<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends ConsumerState<EmailLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late FocusNode _emailFocus;
  late FocusNode _passwordFocus;
  bool _isLoading = false;
  String? _errorMessage;
  bool _emailFocused = false;
  bool _passwordFocused = false;

  @override
  void initState() {
    super.initState();
    _emailFocus = FocusNode();
    _passwordFocus = FocusNode();

    // Listen to focus changes
    _emailFocus.addListener(_onEmailFocusChange);
    _passwordFocus.addListener(_onPasswordFocusChange);
  }

  void _onEmailFocusChange() {
    setState(() => _emailFocused = _emailFocus.hasFocus);
  }

  void _onPasswordFocusChange() {
    setState(() => _passwordFocused = _passwordFocus.hasFocus);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      final user = await ref.read(
        emailSignInProvider(
          (email: email, password: password),
        ).future,
      );

      if (user == null || !mounted) return;

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
        // JWT 取得失敗でもホームに進む（再試行は apiServiceProvider のリスナーに委ねる）
      }

      if (!mounted) return;

      // 子どもプロフィールの存在を確認してルーティング
      try {
        final children = await api.fetchChildrenProfiles();
        if (!mounted) return;
        if (children.isNotEmpty) {
          ref.read(currentChildIdProvider.notifier).state = children.first.id;
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          Navigator.of(context).pushReplacementNamed('/child-registration');
        }
      } catch (_) {
        if (mounted) Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ログインに失敗しました: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('メールでログイン'),
      ),
      body: AnimatedFadeInScale(
        duration: AnimationDurations.medium, // 300ms fade + scale
        beginScale: 0.95,
        endScale: 1.0,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 40),

            // Email Field
            AnimatedSlideIn(
              direction: SlideDirection.fromBottom,
              duration: AnimationDurations.medium,
              delay: Duration(milliseconds: 100),
              child: AnimatedContainer(
                duration: AnimationDurations.medium,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _emailFocused
                      ? [
                          BoxShadow(
                            color: Theme.of(context).primaryColor.withAlpha(40),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: TextField(
                  controller: _emailController,
                  focusNode: _emailFocus,
                  decoration: InputDecoration(
                    labelText: 'メールアドレス',
                    hintText: 'parent@example.com',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_isLoading,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Password Field
            AnimatedSlideIn(
              direction: SlideDirection.fromBottom,
              duration: AnimationDurations.medium,
              delay: Duration(milliseconds: 200),
              child: AnimatedContainer(
                duration: AnimationDurations.medium,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _passwordFocused
                      ? [
                          BoxShadow(
                            color: Theme.of(context).primaryColor.withAlpha(40),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: TextField(
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  decoration: InputDecoration(
                    labelText: 'パスワード',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                  obscureText: true,
                  enabled: !_isLoading,
                ),
              ),
            ),

            // Error Message with Shake Animation
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              AnimatedShake(
                duration: Duration(milliseconds: 400),
                distance: 8,
                shakes: 3,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Login Button with Animation
            AnimatedSlideIn(
              direction: SlideDirection.fromBottom,
              duration: AnimationDurations.medium,
              delay: Duration(milliseconds: 300),
              child: _AnimatedLoginButton(
                isLoading: _isLoading,
                onPressed: _handleLogin,
              ),
            ),

            const SizedBox(height: 16),

            // Sign Up Link
            AnimatedSlideIn(
              direction: SlideDirection.fromBottom,
              duration: AnimationDurations.medium,
              delay: Duration(milliseconds: 400),
              child: TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const EmailRegisterScreen(),
                          ),
                        );
                      },
                child: const Text('アカウントをお持ちでない方は登録'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated Login Button with loading state
class _AnimatedLoginButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _AnimatedLoginButton({
    required this.isLoading,
    required this.onPressed,
  });

  @override
  State<_AnimatedLoginButton> createState() => _AnimatedLoginButtonState();
}

class _AnimatedLoginButtonState extends State<_AnimatedLoginButton>
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

  void _onTapDown(TapDownDetails details) {
    if (!widget.isLoading) {
      setState(() => _isPressed = true);
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
    if (!widget.isLoading) {
      widget.onPressed();
    }
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: _isPressed && !widget.isLoading
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
            onPressed: null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: AnimatedCrossFade(
              firstChild: const Text('ログイン'),
              secondChild: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  const Text('ログイン中...'),
                ],
              ),
              crossFadeState: widget.isLoading
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: AnimationDurations.short,
            ),
          ),
        ),
      ),
    );
  }
}
