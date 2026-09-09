import 'package:flutter/material.dart';
import 'package:shared_core/widgets/components/app_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/child_provider.dart';
import '../../utils/animation_constants.dart';
import '../../widgets/animations/index.dart';

const _primaryColor = Color(0xFF9B59B6);

class ChildRegistrationScreen extends ConsumerStatefulWidget {
  const ChildRegistrationScreen({super.key});

  @override
  ConsumerState<ChildRegistrationScreen> createState() =>
      _ChildRegistrationScreenState();
}

class _ChildRegistrationScreenState
    extends ConsumerState<ChildRegistrationScreen> {
  final _nicknameController = TextEditingController();
  int _selectedGrade = 3;
  int _selectedAvatar = 0;
  bool _isLoading = false;

  static const _avatarEmojis = [
    '🦁', '🐯', '🐶', '🐱', '🐰', '🦊', '🦝', '🐨',
  ];

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _handleComplete() async {
    final name = _nicknameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ニックネームを入力してください')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final notifier = ref.read(childProfileNotifierProvider.notifier);
      final child = await notifier.createChildProfile(
        name: name,
        grade: _selectedGrade,
        avatarEmoji: _avatarEmojis[_selectedAvatar],
      );

      // 作成した子どもを現在の子どもとして設定
      ref.read(currentChildIdProvider.notifier).state = child.id;

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('登録に失敗しました: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F5FF),
      appBar: AppBar(
        title: const Text('お子さんの情報登録'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _primaryColor,
      ),
      body: AnimatedFadeInScale(
        duration: AnimationDurations.medium,
        beginScale: 0.95,
        endScale: 1.0,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // ヘッダー
            AnimatedSlideIn(
              direction: SlideDirection.fromBottom,
              duration: AnimationDurations.medium,
              delay: Duration(milliseconds: 100),
              child: AnimatedBounce(
                duration: AnimationDurations.long,
                scale: 1.0,
                delay: Duration(milliseconds: 200),
                child: Center(
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: _primaryColor.withAlpha(20),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text('👶', style: TextStyle(fontSize: 36)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'お子さんのプロフィールを作成しましょう',
                        style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ニックネーム入力
            AnimatedSlideIn(
              direction: SlideDirection.fromBottom,
              duration: AnimationDurations.medium,
              delay: Duration(milliseconds: 200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ニックネーム',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nicknameController,
                    decoration: InputDecoration(
                      hintText: '例）たろう',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _primaryColor, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // 学年選択（3〜4年生のみ）
            AnimatedSlideIn(
              direction: SlideDirection.fromBottom,
              duration: AnimationDurations.medium,
              delay: Duration(milliseconds: 300),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '学年',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 3, label: Text('3年生')),
                      ButtonSegment(value: 4, label: Text('4年生')),
                    ],
                    selected: {_selectedGrade},
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: _primaryColor,
                      selectedForegroundColor: Colors.white,
                    ),
                    onSelectionChanged: (Set<int> newSelection) {
                      setState(() => _selectedGrade = newSelection.first);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // アバター選択
            AnimatedSlideIn(
              direction: SlideDirection.fromBottom,
              duration: AnimationDurations.medium,
              delay: Duration(milliseconds: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'アバターを選択',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1,
                    ),
                    itemCount: _avatarEmojis.length,
                    itemBuilder: (context, index) {
                      final isSelected = _selectedAvatar == index;
                      return AnimatedSlideIn(
                        direction: SlideDirection.fromBottom,
                        duration: AnimationDurations.medium,
                        delay: Duration(milliseconds: 450 + (index * 50)),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedAvatar = index),
                          child: AnimatedContainer(
                            duration: AnimationDurations.medium,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _primaryColor.withAlpha(20)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? _primaryColor : Colors.grey.shade300,
                                width: isSelected ? 2.5 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: _primaryColor.withAlpha(50),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : null,
                            ),
                            child: AnimatedScale(
                              duration: AnimationDurations.short,
                              scale: isSelected ? 1.08 : 1.0,
                              child: Center(
                                child: Text(
                                  _avatarEmojis[index],
                                  style: const TextStyle(fontSize: 38),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // 完了ボタン
            AnimatedSlideIn(
              direction: SlideDirection.fromBottom,
              duration: AnimationDurations.medium,
              delay: Duration(milliseconds: 500),
              child: _AnimatedCompleteButton(
                isLoading: _isLoading,
                onPressed: _handleComplete,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

/// Animated Complete Button with loading and success states
class _AnimatedCompleteButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _AnimatedCompleteButton({
    required this.isLoading,
    required this.onPressed,
  });

  @override
  State<_AnimatedCompleteButton> createState() => _AnimatedCompleteButtonState();
}

class _AnimatedCompleteButtonState extends State<_AnimatedCompleteButton>
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

  void _onTapDown(TapDownDetails _) {
    if (!widget.isLoading) {
      setState(() => _isPressed = true);
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails _) {
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
            borderRadius: BorderRadius.circular(14),
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
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: AppButton(
              onPressed: null,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: AnimatedCrossFade(
                firstChild: const Text(
                  '登録して始める',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                secondChild: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      '登録中...',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
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
      ),
    );
  }
}
