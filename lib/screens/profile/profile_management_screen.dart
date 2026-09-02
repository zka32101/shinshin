import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/child_profile.dart';
import '../../providers/child_provider.dart';
import '../../utils/animation_constants.dart';
import '../../widgets/animations/index.dart';
import 'profile_edit_screen.dart';

class ProfileManagementScreen extends ConsumerWidget {
  const ProfileManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('お子様のプロフィール'),
        elevation: 0,
      ),
      body: ref.watch(childrenProfilesProvider).when(
            data: (profiles) {
              return AnimatedFadeInScale(
                duration: AnimationDurations.medium,
                beginScale: 0.95,
                endScale: 1.0,
                child: Column(
                  children: [
                    Expanded(
                      child: profiles.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.person_add,
                                    size: 64,
                                    color: Colors.grey.shade300,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'プロフィールがありません',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: profiles.length,
                              itemBuilder: (context, index) {
                                final profile = profiles[index];
                                return AnimatedSlideIn(
                                  direction: SlideDirection.fromBottom,
                                  duration: AnimationDurations.medium,
                                  delay: Duration(milliseconds: 100 + (index * 75)),
                                  child: ProfileCard(
                                    profile: profile,
                                    onEdit: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ProfileEditScreen(
                                                profile: profile,
                                              ),
                                        ),
                                      );
                                    },
                                    onDelete: () {
                                      _showDeleteConfirmation(
                                        context,
                                        ref,
                                        profile.id,
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                    AnimatedSlideIn(
                      direction: SlideDirection.fromBottom,
                      duration: AnimationDurations.medium,
                      delay: Duration(milliseconds: 200 + (profiles.length * 75)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: SizedBox(
                          width: double.infinity,
                          child: _AddProfileButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ProfileEditScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, st) => Center(
              child: Text('エラー: $error'),
            ),
          ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    String childId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('プロフィール削除'),
        content: const Text('このプロフィールを削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(childProfileNotifierProvider.notifier)
                  .deleteChildProfile(childId);
              Navigator.pop(context);
            },
            child: const Text(
              '削除',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileCard extends StatefulWidget {
  final ChildProfile profile;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProfileCard({
    super.key,
    required this.profile,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard>
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

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
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
        child: Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  widget.profile.avatarEmoji,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            title: Text(
              widget.profile.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              widget.profile.gradeDisplayName,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  onTap: widget.onEdit,
                  child: const Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('編集'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  onTap: widget.onDelete,
                  child: const Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        '削除',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── プロフィール追加ボタン ──────────────────────

/// Button to add a new child profile
class _AddProfileButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _AddProfileButton({
    required this.onPressed,
  });

  @override
  State<_AddProfileButton> createState() => _AddProfileButtonState();
}

class _AddProfileButtonState extends State<_AddProfileButton>
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

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
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
        child: ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 24),
              SizedBox(width: 8),
              Text(
                'プロフィール追加',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
