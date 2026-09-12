import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_core/shared_core.dart'
    show AddFriendDialog, NotificationSettingsPage, RetentionDashboard;

import '../../providers/audio_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/offline_provider.dart';
import '../../providers/offline_sync_provider.dart';
import '../../services/hive_service.dart';
import '../../utils/parental_gate_helper.dart';
import '../feedback/feedback_form_screen.dart';
import '../profile/profile_management_screen.dart';
import '../ranking/ranking_settings_screen.dart';
import 'help_screen.dart';
import 'privacy_policy_screen.dart';
import 'screen_time_settings_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final soundEnabled = ref.watch(isSoundEnabledProvider);
    final narrationEnabled = ref.watch(isNarrationEnabledProvider);
    final volumeLevel = ref.watch(volumeLevelProvider);
    final currentLocale = ref.watch(currentLocaleProvider);
    final notifSettings = ref.watch(notificationSettingsProvider);
    final syncState = ref.watch(offlineSyncProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        elevation: 0,
        backgroundColor: const Color(0xFF9B59B6),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          // ─── オフライン同期状態 ───
          if (syncState.pendingCount > 0)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFE082)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cloud_upload_outlined, color: Color(0xFF856404)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${syncState.pendingCount}件の未同期データがあります',
                      style: const TextStyle(color: Color(0xFF856404), fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: () => ref.read(offlineSyncProvider.notifier).syncPendingItems(),
                    child: const Text('今すぐ同期'),
                  ),
                ],
              ),
            ),

          // プロフィール設定セクション
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'プロフィール',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('お子様のプロフィール'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ProfileManagementScreen(),
                ),
              );
            },
          ),

          // ─── ランキング設定セクション ───
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'ランキング',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined, color: Color(0xFF9B59B6)),
            title: const Text('ランキング設定'),
            subtitle: const Text('プライバシー設定'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const RankingSettingsScreen(),
                ),
              );
            },
          ),

          // ─── 通知設定セクション ───
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('通知', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.notifications_outlined, color: Color(0xFF9B59B6)),
            title: const Text('デイリーリマインダー'),
            subtitle: const Text('毎日の学習をお知らせ'),
            trailing: Switch(
              value: notifSettings.dailyReminder,
              onChanged: (v) => ref
                  .read(notificationSettingsProvider.notifier)
                  .setDailyReminder(v),
            ),
          ),
          const Divider(height: 0),
          ListTile(
            leading: const Icon(Icons.assessment_outlined, color: Color(0xFF9B59B6)),
            title: const Text('レポート通知'),
            subtitle: const Text('月次レポートが完成したとき'),
            trailing: Switch(
              value: notifSettings.reportReady,
              onChanged: (v) => ref
                  .read(notificationSettingsProvider.notifier)
                  .setReportReady(v),
            ),
          ),
          if (notifSettings.dailyReminder) ...[
            const Divider(height: 0),
            ListTile(
              leading: const Icon(Icons.access_time, color: Color(0xFF9B59B6)),
              title: const Text('リマインダー時刻'),
              trailing: TextButton(
                onPressed: () => _pickReminderTime(context, ref, notifSettings),
                child: Text(
                  '${notifSettings.reminderHour.toString().padLeft(2, '0')}:'
                  '${notifSettings.reminderMinute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],

          // ─── ソーシャル・フレンドセクション ───
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '👥 ソーシャル',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.person_add, color: Color(0xFF9B59B6)),
            title: const Text('フレンドを探す'),
            subtitle: const Text('ユーザーを検索してフレンド申請する'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => const AddFriendDialog(),
              );
            },
          ),

          // ─── 利用時間制限セクション ───
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '利用時間',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.hourglass_bottom, color: Color(0xFF9B59B6)),
            title: const Text('利用時間制限'),
            subtitle: const Text('1日の利用時間の上限を設定（保護者向け）'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _openScreenTimeSettings(context),
          ),

          // ─── 分析セクション ───
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '分析',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.assessment_outlined, color: Color(0xFF9B59B6)),
            title: const Text('ユーザーリテンション分析'),
            subtitle: const Text('あなたの活動パターンと継続性を分析'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const RetentionDashboard(),
              ),
            ),
          ),

          // 音声設定セクション
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '音声設定',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.volume_up),
            title: const Text('効果音'),
            trailing: Switch(
              value: soundEnabled,
              onChanged: (value) {
                ref
                    .read(audioControllerProvider.notifier)
                    .toggleSoundEnabled();
              },
            ),
          ),
          const Divider(height: 0),
          ListTile(
            leading: const Icon(Icons.record_voice_over),
            title: const Text('ナレーション'),
            trailing: Switch(
              value: narrationEnabled,
              onChanged: (value) {
                ref
                    .read(audioControllerProvider.notifier)
                    .toggleNarrationEnabled();
              },
            ),
          ),
          const Divider(height: 0),
          ListTile(
            leading: const Icon(Icons.volume_up_outlined),
            title: const Text('音量'),
            subtitle: Slider(
              value: volumeLevel,
              onChanged: (value) {
                ref
                    .read(audioControllerProvider.notifier)
                    .setVolume(value);
              },
              min: 0,
              max: 1,
            ),
          ),

          // 言語・表示設定セクション
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '表示設定',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('言語'),
            trailing: DropdownButton<SupportedLocale>(
              value: currentLocale,
              underline: const SizedBox(),
              onChanged: (locale) {
                if (locale != null) {
                  ref
                      .read(localeProvider.notifier)
                      .setLocale(locale);
                }
              },
              items: SupportedLocale.values
                  .map((locale) => DropdownMenuItem(
                        value: locale,
                        child: Text(locale.nativeName),
                      ))
                  .toList(),
            ),
          ),

          // ─── キャッシュ管理セクション ───
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'ストレージ',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          _CacheSizeWidget(),
          const Divider(height: 0),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.orange),
            title: const Text('キャッシュをクリア'),
            subtitle: const Text('オフラインデータを削除'),
            onTap: () => _showClearCacheConfirmation(context),
          ),

          // アカウント・その他セクション
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'アカウント・その他',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('ヘルプ'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelpScreen()),
              );
            },
          ),
          const Divider(height: 0),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('プライバシーポリシー'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
              );
            },
          ),
          const Divider(height: 0),
          ListTile(
            leading: const Icon(Icons.bug_report_outlined, color: Color(0xFF9B59B6)),
            title: const Text('バグ報告・ご意見'),
            subtitle: const Text('不具合や改善要望をお寄せください'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FeedbackFormScreen()),
              );
            },
          ),
          const Divider(height: 0),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('このアプリについて'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: '小学コレ！道徳',
                applicationVersion: '0.1.0',
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _openScreenTimeSettings(BuildContext context) async {
    // 利用時間制限の変更は保護者向け操作のため、ゲートを通してから遷移する
    final passedGate = await requireParentalGate(
      context,
      description: 'これは利用時間の設定です。\n下の計算の答えを入力してください。',
    );
    if (!passedGate || !context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScreenTimeSettingsScreen()),
    );
  }

  Future<void> _pickReminderTime(
    BuildContext context,
    WidgetRef ref,
    NotificationSettings settings,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: settings.reminderHour,
        minute: settings.reminderMinute,
      ),
    );
    if (picked != null) {
      ref.read(notificationSettingsProvider.notifier).setReminderTime(
        picked.hour,
        picked.minute,
      );
    }
  }

  Future<void> _showClearCacheConfirmation(BuildContext context) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('キャッシュをクリア'),
        content: const Text('ダウンロード済みのオフラインデータをすべて削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final hive = HiveService();
                await hive.initialize();
                await hive.clearStoriesCache();
                await hive.clearBadgesCache();
                // Reports キャッシュは保持（参考用）
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('キャッシュをクリアしました')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('エラー: $e')),
                  );
                }
              }
            },
            child: const Text(
              'クリア',
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

}

/// キャッシュサイズ表示ウィジェット
class _CacheSizeWidget extends ConsumerStatefulWidget {
  const _CacheSizeWidget();

  @override
  ConsumerState<_CacheSizeWidget> createState() => _CacheSizeWidgetState();
}

class _CacheSizeWidgetState extends ConsumerState<_CacheSizeWidget> {
  late Future<Map<String, String>> _cacheSizeFuture;

  @override
  void initState() {
    super.initState();
    _loadCacheSize();
  }

  void _loadCacheSize() {
    _cacheSizeFuture = () async {
      final hive = HiveService();
      await hive.initialize();
      return hive.getCacheSizeInfo();
    }();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String>>(
      future: _cacheSizeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ListTile(
            leading: Icon(Icons.storage),
            title: Text('キャッシュサイズ'),
            subtitle: Text('計算中...'),
          );
        }

        if (snapshot.hasError) {
          return const ListTile(
            leading: Icon(Icons.storage),
            title: Text('キャッシュサイズ'),
            subtitle: Text('計算できませんでした'),
          );
        }

        final cacheInfo = snapshot.data ?? {};
        final total = cacheInfo['total'] ?? '-';

        return ListTile(
          leading: const Icon(Icons.storage),
          title: const Text('キャッシュサイズ'),
          subtitle: Text(total),
          trailing: IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () {
              setState(() {
                _loadCacheSize();
              });
            },
          ),
        );
      },
    );
  }
}
