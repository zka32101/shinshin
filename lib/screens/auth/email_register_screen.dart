import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/story_provider.dart';
import '../../utils/animation_constants.dart';
import '../../widgets/animations/index.dart';

class EmailRegisterScreen extends ConsumerStatefulWidget {
  const EmailRegisterScreen({super.key});

  @override
  ConsumerState<EmailRegisterScreen> createState() =>
      _EmailRegisterScreenState();
}

class _EmailRegisterScreenState extends ConsumerState<EmailRegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  late FocusNode _nameFocus;
  late FocusNode _emailFocus;
  late FocusNode _passwordFocus;
  late FocusNode _confirmPasswordFocus;
  bool _isLoading = false;
  String? _errorMessage;
  bool _nameFocused = false;
  bool _emailFocused = false;
  bool _passwordFocused = false;
  bool _confirmPasswordFocused = false;

  @override
  void initState() {
    super.initState();
    _nameFocus = FocusNode();
    _emailFocus = FocusNode();
    _passwordFocus = FocusNode();
    _confirmPasswordFocus = FocusNode();

    _nameFocus.addListener(() => setState(() => _nameFocused = _nameFocus.hasFocus));
    _emailFocus.addListener(() => setState(() => _emailFocused = _emailFocus.hasFocus));
    _passwordFocus.addListener(() => setState(() => _passwordFocused = _passwordFocus.hasFocus));
    _confirmPasswordFocus.addListener(() => setState(() => _confirmPasswordFocused = _confirmPasswordFocus.hasFocus));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final name = _nameController.text.trim();

    // Validation
    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      setState(() {
        _errorMessage = 'すべての項目を入力してください';
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _errorMessage = 'パスワードが一致しません';
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _errorMessage = 'パスワードは6文字以上である必要があります';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Firebase でユーザーを作成
      final firebaseUser = await ref.read(
        emailRegisterProvider(
          (email: email, password: password, displayName: name),
        ).future,
      );
      if (firebaseUser == null) return;

      // 2. バックエンドに Firebase IDToken を送って JWT を取得
      final api = ref.read(apiServiceProvider);
      try {
        final idToken = await firebaseUser.getIdToken();
        if (idToken != null) {
          final result = await api.loginWithFirebase(idToken);
          final jwt = result['accessToken'] as String?;
          if (jwt != null) api.setAuthToken(jwt);
        }
      } catch (_) {
        // バックエンド登録に失敗してもホームへ進む
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/child-registration');
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('登録に失敗しました: ${e.toString()}')),
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
        title: const Text('保護者登録'),
      ),
      body: AnimatedFadeInScale(
        duration: AnimationDurations.medium,
        beginScale: 0.95,
        endScale: 1.0,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 24),

            // Step 1: Name Field
            AnimatedSlideIn(
              direction: SlideDirection.fromBottom,
              duration: AnimationDurations.medium,
              delay: Duration(milliseconds: 100),
              child: _AnimatedFormField(
                controller: _nameController,
                focusNode: _nameFocus,
                isFocused: _nameFocused,
                labelText: 'お名前',
                hintText: '太郎',
                prefixIcon: Icons.person,
                enabled: !_isLoading,
              ),
            ),
            const SizedBox(height: 16),

            // Step 2: Email Field
            AnimatedSlideIn(
              direction: SlideDirection.fromBottom,
              duration: AnimationDurations.medium,
              delay: Duration(milliseconds: 200),
              child: _AnimatedFormField(
                controller: _emailController,
                focusNode: _emailFocus,
                isFocused: _emailFocused,
                labelText: 'メールアドレス',
                hintText: 'parent@example.com',
                prefixIcon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                enabled: !_isLoading,
              ),
            ),
            const SizedBox(height: 16),

            // Step 3: Password Field
            AnimatedSlideIn(
              direction: SlideDirection.fromBottom,
              duration: AnimationDurations.medium,
              delay: Duration(milliseconds: 300),
              child: _AnimatedFormField(
                controller: _passwordController,
                focusNode: _passwordFocus,
                isFocused: _passwordFocused,
                labelText: 'パスワード',
                hintText: '6文字以上',
                prefixIcon: Icons.lock,
                obscureText: true,
                enabled: !_isLoading,
              ),
            ),
            const SizedBox(height: 16),

            // Step 4: Confirm Password Field
            AnimatedSlideIn(
              direction: SlideDirection.fromBottom,
              duration: AnimationDurations.medium,
              delay: Duration(milliseconds: 400),
              child: _AnimatedFormField(
                controller: _confirmPasswordController,
                focusNode: _confirmPasswordFocus,
                isFocused: _confirmPasswordFocused,
                labelText: 'パスワード（確認）',
                prefixIcon: Icons.lock,
                obscureText: true,
                enabled: !_isLoading,
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
                          style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Register Button with Animation
            AnimatedSlideIn(
              direction: SlideDirection.fromBottom,
              duration: AnimationDurations.medium,
              delay: Duration(milliseconds: 500),
              child: _AnimatedRegisterButton(
                isLoading: _isLoading,
                onPressed: _handleRegister,
              ),
            ),

            const SizedBox(height: 24),

            // COPPA Notice
            AnimatedSlideIn(
              direction: SlideDirection.fromBottom,
              duration: AnimationDurations.medium,
              delay: Duration(milliseconds: 600),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'COPPA準拠: お子さんの個人情報は名前と学年のみ保存されます。',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.blue.shade700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated Form Field with focus shadow effect
class _AnimatedFormField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isFocused;
  final String labelText;
  final String? hintText;
  final IconData prefixIcon;
  final bool obscureText;
  final bool enabled;
  final TextInputType? keyboardType;

  const _AnimatedFormField({
    required this.controller,
    required this.focusNode,
    required this.isFocused,
    required this.labelText,
    required this.prefixIcon,
    this.hintText,
    this.obscureText = false,
    this.enabled = true,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AnimationDurations.medium,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: isFocused
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
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          prefixIcon: Icon(prefixIcon),
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
        obscureText: obscureText,
        keyboardType: keyboardType,
        enabled: enabled,
      ),
    );
  }
}

/// Animated Register Button with loading state
class _AnimatedRegisterButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _AnimatedRegisterButton({
    required this.isLoading,
    required this.onPressed,
  });

  @override
  State<_AnimatedRegisterButton> createState() => _AnimatedRegisterButtonState();
}

class _AnimatedRegisterButtonState extends State<_AnimatedRegisterButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AnimationDurations.superShort,
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
              firstChild: const Text('登録'),
              secondChild: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  const Text('登録中...'),
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
