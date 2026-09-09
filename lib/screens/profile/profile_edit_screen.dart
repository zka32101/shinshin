import 'package:flutter/material.dart';
import 'package:shared_core/widgets/components/app_card.dart';
import 'package:shared_core/widgets/components/app_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/child_profile.dart';
import '../../providers/child_provider.dart';
import '../../utils/animation_constants.dart';
import '../../widgets/animations/index.dart';

const _primaryColor = Color(0xFF9B59B6);

class ProfileEditScreen extends ConsumerStatefulWidget {
  final ChildProfile? profile;

  const ProfileEditScreen({super.key, this.profile});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  late TextEditingController _nameController;
  late int _selectedGrade;
  late String _selectedEmoji;

  static const _avatarEmojis = [
    '🦁', '🐯', '🐶', '🐱', '🐰', '🦊', '🦝', '🐨',
    '🐸', '🦋', '⭐', '🌟', '🌈', '🎵', '🎨', '🚀',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameController = TextEditingController(text: p?.name ?? '');
    _selectedGrade = p?.grade ?? 3;
    _selectedEmoji = p?.avatarEmoji ?? _avatarEmojis.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('お子様の名前を入力してください')),
      );
      return;
    }

    final notifier = ref.read(childProfileNotifierProvider.notifier);

    try {
      if (widget.profile != null) {
        await notifier.updateChildProfile(
          childId: widget.profile!.id,
          name: name,
          grade: _selectedGrade,
          avatarEmoji: _selectedEmoji,
        );
      } else {
        final child = await notifier.createChildProfile(
          name: name,
          grade: _selectedGrade,
          avatarEmoji: _selectedEmoji,
        );
        ref.read(currentChildIdProvider.notifier).state = child.id;
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          widget.profile != null ? 'プロフィール編集' : 'プロフィール作成',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: AnimatedFadeInScale(
        duration: AnimationDurations.medium,
        beginScale: 0.95,
        endScale: 1.0,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // アバター選択
              AnimatedSlideIn(
                direction: SlideDirection.fromBottom,
                duration: AnimationDurations.medium,
                delay: const Duration(milliseconds: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('アバターを選択',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF666666))),
                    const SizedBox(height: 12),
                    GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1,
                      ),
                      itemCount: _avatarEmojis.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        final emoji = _avatarEmojis[index];
                        final isSelected = emoji == _selectedEmoji;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedEmoji = emoji),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            decoration: BoxDecoration(
                              color: isSelected ? _primaryColor.withAlpha(20) : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? _primaryColor : Colors.grey.shade300,
                                width: isSelected ? 2.5 : 1,
                              ),
                            ),
                            child: Center(
                              child: Text(emoji, style: const TextStyle(fontSize: 34)),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 名前入力
              AnimatedSlideIn(
                direction: SlideDirection.fromBottom,
                duration: AnimationDurations.medium,
                delay: const Duration(milliseconds: 200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('お子様の名前',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF666666))),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: '例: 太郎',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: _primaryColor, width: 2)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 学年選択
              AnimatedSlideIn(
                direction: SlideDirection.fromBottom,
                duration: AnimationDurations.medium,
                delay: const Duration(milliseconds: 300),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('学年',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF666666))),
                    const SizedBox(height: 8),
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
                      onSelectionChanged: (s) => setState(() => _selectedGrade = s.first),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // 保存ボタン
              AnimatedSlideIn(
                direction: SlideDirection.fromBottom,
                duration: AnimationDurations.medium,
                delay: const Duration(milliseconds: 400),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: _ProfileSaveButton(
                    label: widget.profile != null ? '変更を保存' : '作成する',
                    onPressed: _saveProfile,
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

// ─── プロフィール保存ボタン ──────────────────────

/// Save button with tap feedback for profile edit screen
class _ProfileSaveButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;

  const _ProfileSaveButton({
    required this.label,
    required this.onPressed,
  });

  @override
  State<_ProfileSaveButton> createState() => _ProfileSaveButtonState();
}

class _ProfileSaveButtonState extends State<_ProfileSaveButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AnimationDurations.short,
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
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AppButton(
          onPressed: null),
            elevation: 0,
          ),
          child: Text(
            widget.label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
