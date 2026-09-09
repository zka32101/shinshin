import 'package:flutter/material.dart';
import 'package:shared_core/widgets/components/app_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/notification_preferences.dart';
import '../../providers/notification_preferences_provider.dart';
import '../../providers/auth_provider.dart';

const _primaryColor = Color(0xFF9B59B6);
const _bgColor = Color(0xFFF5F5F5);
const _cardColor = Color(0xFFFFFFFF);
const _textPrimary = Color(0xFF333333);
const _textSecondary = Color(0xFF999999);

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  late NotificationPreferences _prefs;
  bool _isLoading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    // ユーザーIDを取得（ゲスト環境では null になる可能性）
    final authState = ref.read(userAuthStateProvider);
    _userId = authState.valueOrNull?.uid;

    if (_userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final prefs = await ref
          .read(notificationPreferencesProvider(_userId!).future);
      setState(() {
        _prefs = prefs;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Failed to load notification preferences: $e');
      setState(() {
        _prefs = NotificationPreferences.defaultPreferences();
        _isLoading = false;
      });
    }
  }

  Future<void> _savePreferences() async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ゲストユーザーは設定を保存できません')),
      );
      return;
    }

    try {
      await ref.read(updateNotificationPreferencesProvider(
        (userId: _userId!, prefs: _prefs),
      ).future);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('設定を保存しました')),
        );
      }
    } catch (e) {
      debugPrint('Failed to save notification preferences: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存に失敗しました')),
        );
      }
    }
  }

  void _showTimePicker() async {
    final now = DateTime.now();
    final timeParts = _prefs.emailTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.tryParse(timeParts[0]) ?? 18,
      minute: int.tryParse(timeParts[1]) ?? 0,
    );

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (selectedTime != null) {
      setState(() {
        _prefs = _prefs.copyWith(
          emailTime:
              '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('メール配信設定')),
        body: const Center(child: CircularProgressIndicator(color: _primaryColor)),
      );
    }

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        title: const Text('メール配信設定'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Email notifications 有効/無効
          Card(
            child: SwitchListTile(
              title: const Text('メール配信を有効にする'),
              subtitle: const Text('親向けの週間学習レポートをメール配信します'),
              value: _prefs.emailNotificationsEnabled,
              onChanged: (v) => setState(
                () =>
                    _prefs = _prefs.copyWith(emailNotificationsEnabled: v),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 以下のオプションはメール配信有効時のみ表示
          if (_prefs.emailNotificationsEnabled) ...[
            // 配信周期
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📅 配信周期',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        _FrequencyChip(
                          label: '毎週',
                          value: 'weekly',
                          selected:
                              _prefs.emailFrequency == 'weekly',
                          onSelected: (selected) => setState(
                            () => _prefs = _prefs.copyWith(
                              emailFrequency: 'weekly',
                              customEmailDays: [],
                            ),
                          ),
                        ),
                        _FrequencyChip(
                          label: '2週間ごと',
                          value: 'biweekly',
                          selected:
                              _prefs.emailFrequency == 'biweekly',
                          onSelected: (selected) => setState(
                            () => _prefs = _prefs.copyWith(
                              emailFrequency: 'biweekly',
                              customEmailDays: [],
                            ),
                          ),
                        ),
                        _FrequencyChip(
                          label: '月1回',
                          value: 'monthly',
                          selected:
                              _prefs.emailFrequency == 'monthly',
                          onSelected: (selected) => setState(
                            () => _prefs = _prefs.copyWith(
                              emailFrequency: 'monthly',
                              customEmailDays: [],
                            ),
                          ),
                        ),
                        _FrequencyChip(
                          label: 'カスタム',
                          value: 'custom',
                          selected:
                              _prefs.emailFrequency == 'custom',
                          onSelected: (selected) => setState(
                            () => _prefs = _prefs.copyWith(
                              emailFrequency: 'custom',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Custom Days 選択
            if (_prefs.emailFrequency == 'custom')
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📆 配信日（複数選択可）',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          ('日', 0),
                          ('月', 1),
                          ('火', 2),
                          ('水', 3),
                          ('木', 4),
                          ('金', 5),
                          ('土', 6),
                        ].map((e) {
                          final isSelected = _prefs.customEmailDays.contains(e.$2);
                          return FilterChip(
                            label: Text(e.$1),
                            selected: isSelected,
                            onSelected: (_) {
                              setState(() {
                                if (isSelected) {
                                  _prefs = _prefs.copyWith(
                                    customEmailDays:
                                        List.from(_prefs.customEmailDays)
                                          ..remove(e.$2),
                                  );
                                } else {
                                  _prefs = _prefs.copyWith(
                                    customEmailDays:
                                        List.from(_prefs.customEmailDays)
                                          ..add(e.$2)
                                          ..sort(),
                                  );
                                }
                              });
                            },
                            selectedColor:
                                _primaryColor.withAlpha(40),
                            checkmarkColor: _primaryColor,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // 配信時刻
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '⏰ 配信時刻',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _showTimePicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _prefs.emailTime,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Icon(Icons.schedule),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // タイムゾーン
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🌍 タイムゾーン',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButton<String>(
                      value: _prefs.emailTimeZone,
                      isExpanded: true,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _prefs =
                                _prefs.copyWith(emailTimeZone: value);
                          });
                        }
                      },
                      items: [
                        'Asia/Tokyo',
                        'Asia/Shanghai',
                        'Asia/Bangkok',
                        'Asia/Kolkata',
                        'Europe/London',
                        'America/New_York',
                        'America/Los_Angeles',
                        'Australia/Sydney',
                      ].map((tz) {
                        return DropdownMenuItem(
                          value: tz,
                          child: Text(tz),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 保存ボタン
            AppButton(
              onPressed: _savePreferences,
              ),
              child: const Text(
                '💾 保存',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FrequencyChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final ValueChanged<bool> onSelected;

  const _FrequencyChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: _primaryColor.withAlpha(40),
      checkmarkColor: _primaryColor,
      labelStyle: TextStyle(
        color: selected ? _primaryColor : _textSecondary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
