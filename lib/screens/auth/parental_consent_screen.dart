// ========================================================
// 親向け同意確認画面
// 小学コレ！道徳アプリ - COPPA準拠
//
// 機能:
// - 親のメールアドレス確認
// - プライバシーポリシーの同意
// - データ処理に関する同意
// ========================================================

import 'package:flutter/material.dart';
import 'package:shared_core/widgets/components/app_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/parental_consent.dart';
import '../../services/logger_service.dart';
import '../../providers/auth_provider.dart';

/// 親向け同意確認画面のプロバイダー
final parentalConsentNotifierProvider = StateNotifierProvider<
    ParentalConsentNotifier,
    AsyncValue<void>>((ref) {
  return ParentalConsentNotifier(ref);
});

/// 親の同意状態を管理するプロバイダー
final consentFormProvider = StateProvider<ConsentFormState>((ref) {
  return ConsentFormState();
});

/// 同意フォームの状態
class ConsentFormState {
  bool agreePrivacy = false;
  bool agreeDataProcessing = false;
  bool agreeThirdPartySharing = false;
  bool agreeAnalytics = false;
  String parentEmail = '';
  String childEmail = '';

  bool get allAgreed =>
      agreePrivacy &&
      agreeDataProcessing &&
      agreeThirdPartySharing &&
      agreeAnalytics &&
      parentEmail.isNotEmpty &&
      childEmail.isNotEmpty;

  ConsentFormState copy({
    bool? agreePrivacy,
    bool? agreeDataProcessing,
    bool? agreeThirdPartySharing,
    bool? agreeAnalytics,
    String? parentEmail,
    String? childEmail,
  }) {
    return ConsentFormState()
      ..agreePrivacy = agreePrivacy ?? this.agreePrivacy
      ..agreeDataProcessing = agreeDataProcessing ?? this.agreeDataProcessing
      ..agreeThirdPartySharing =
          agreeThirdPartySharing ?? this.agreeThirdPartySharing
      ..agreeAnalytics = agreeAnalytics ?? this.agreeAnalytics
      ..parentEmail = parentEmail ?? this.parentEmail
      ..childEmail = childEmail ?? this.childEmail;
  }
}

/// 親の同意確認スクリーン
class ParentalConsentScreen extends ConsumerStatefulWidget {
  const ParentalConsentScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ParentalConsentScreen> createState() =>
      _ParentalConsentScreenState();
}

class _ParentalConsentScreenState
    extends ConsumerState<ParentalConsentScreen> {
  late TextEditingController _parentEmailController;
  late TextEditingController _childEmailController;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _parentEmailController = TextEditingController();
    _childEmailController = TextEditingController();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _parentEmailController.dispose();
    _childEmailController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _updateFormState({
    bool? agreePrivacy,
    bool? agreeDataProcessing,
    bool? agreeThirdPartySharing,
    bool? agreeAnalytics,
    String? parentEmail,
    String? childEmail,
  }) {
    ref.read(consentFormProvider.notifier).state =
        ref.read(consentFormProvider).copy(
              agreePrivacy: agreePrivacy,
              agreeDataProcessing: agreeDataProcessing,
              agreeThirdPartySharing: agreeThirdPartySharing,
              agreeAnalytics: agreeAnalytics,
              parentEmail: parentEmail ?? _parentEmailController.text,
              childEmail: childEmail ?? _childEmailController.text,
            );
  }

  Future<void> _submitConsent() async {
    final formState = ref.read(consentFormProvider);

    if (!formState.allAgreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('すべての項目に同意してください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 同意を送信
    ref.read(parentalConsentNotifierProvider.notifier).submitConsent(
          parentEmail: formState.parentEmail,
          childEmail: formState.childEmail,
          consentData: {
            'dataProcessing': formState.agreeDataProcessing,
            'thirdPartySharing': formState.agreeThirdPartySharing,
            'analyticsTracking': formState.agreeAnalytics,
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(consentFormProvider);
    final consentState = ref.watch(parentalConsentNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('親の同意確認'),
        elevation: 0,
      ),
      body: consentState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          error.toString(),
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppButton(
                  onPressed: () => Navigator.pop(context),
                  label: '戻る',
                ),
              ],
            ),
          ),
        ),
        data: (_) => SingleChildScrollView(
          controller: _scrollController,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ヘッダー
                _buildHeader(),
                const SizedBox(height: 24),

                // メールアドレス入力
                _buildEmailInputSection(
                  _parentEmailController,
                  '親のメールアドレス',
                  formState.parentEmail,
                  (value) => _updateFormState(parentEmail: value),
                ),
                const SizedBox(height: 16),

                _buildEmailInputSection(
                  _childEmailController,
                  '子どものメールアドレス（確認用）',
                  formState.childEmail,
                  (value) => _updateFormState(childEmail: value),
                ),
                const SizedBox(height: 24),

                // 同意セクション
                const Text(
                  '以下の項目にご同意ください',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // プライバシーポリシー
                _buildConsentCheckbox(
                  value: formState.agreePrivacy,
                  label: 'プライバシーポリシーに同意します',
                  onChanged: (value) =>
                      _updateFormState(agreePrivacy: value ?? false),
                  onTap: () => _showPrivacyPolicy(),
                ),
                const SizedBox(height: 12),

                // データ処理の同意
                _buildConsentCheckbox(
                  value: formState.agreeDataProcessing,
                  label: 'お子様の学習データの処理に同意します',
                  subtitle:
                      'アプリの改善とカスタマイズ学習のため、お子様の学習履歴を分析します',
                  onChanged: (value) =>
                      _updateFormState(agreeDataProcessing: value ?? false),
                ),
                const SizedBox(height: 12),

                // 第三者共有の同意
                _buildConsentCheckbox(
                  value: formState.agreeThirdPartySharing,
                  label: '第三者との情報共有に同意します',
                  subtitle: 'Firebase等の第三者サービスでの処理を許可します',
                  onChanged: (value) =>
                      _updateFormState(agreeThirdPartySharing: value ?? false),
                ),
                const SizedBox(height: 12),

                // アナリティクスの同意
                _buildConsentCheckbox(
                  value: formState.agreeAnalytics,
                  label: 'アナリティクス解析に同意します',
                  subtitle: '利用統計の匿名化された収集を許可します',
                  onChanged: (value) =>
                      _updateFormState(agreeAnalytics: value ?? false),
                ),
                const SizedBox(height: 24),

                // COPPA準拠の説明
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'COPPA準拠',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'このアプリは米国子どもオンラインプライバシー保護法'
                        '（COPPA）に準拠しています。\n\n'
                        '13歳未満のお子様のご利用には、親様の書面同意が必要です。\n\n'
                        '詳細は「利用規約とプライバシーポリシー」をご覧ください。',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 送信ボタン
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    onPressed: formState.allAgreed ? _submitConsent : null,
                      backgroundColor: Colors.green,
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                    child: Text(
                      '同意して続ける',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: formState.allAgreed
                            ? Colors.white
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // キャンセルボタン
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    label: 'キャンセル',
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ヘッダーイメージ
        Container(
          width: double.infinity,
          height: 140,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.green.shade50,
          ),
          child: _buildImageWithFallback(
            'assets/images/parental_consent/header_image.png',
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.verified_user, color: Colors.green.shade700),
                  const SizedBox(width: 8),
                  Text(
                    '親様の同意確認',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'お子様が「小学コレ！道徳」をご利用いただくため、'
                '親様からの同意確認が必要です。',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 画像を表示するヘルパー関数（フォールバック付き）
  Widget _buildImageWithFallback(String imagePath) {
    return Image.asset(
      imagePath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[200],
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_not_supported,
                  color: Colors.grey[400],
                  size: 32,
                ),
                const SizedBox(height: 4),
                Text(
                  'Image',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmailInputSection(
    TextEditingController controller,
    String label,
    String currentValue,
    Function(String) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: 'example@email.com',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConsentCheckbox({
    required bool value,
    required String label,
    String? subtitle,
    required Function(bool?) onChanged,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: value ? Colors.green : Colors.grey.shade300,
            width: value ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: value ? Colors.green.shade50 : Colors.transparent,
        ),
        child: Row(
          children: [
            Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.green,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacyPolicy() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'プライバシーポリシー',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '小学コレ！道徳アプリは、お客様のプライバシーを尊重します。'
                  'このポリシーでは、当アプリがどのような情報を収集し、'
                  'どのように使用するかを説明します。',
                ),
                const SizedBox(height: 16),
                const Text(
                  '1. 収集する情報\n'
                  '当アプリは以下の情報を収集します：\n'
                  '• 名前\n'
                  '• メールアドレス\n'
                  '• 学習履歴\n'
                  '• デバイス情報\n\n'
                  '2. 生年月日について\n'
                  '13歳未満のお子様の生年月日は一切保存いたしません。'
                  'これはCOPPA準拠のためです。\n\n'
                  '3. 情報の使用\n'
                  'お子様の学習データは以下の目的で使用されます：\n'
                  '• アプリの改善\n'
                  '• カスタマイズ学習の実現\n'
                  '• 月次成長レポートの生成\n\n'
                  '4. 第三者とのデータ共有\n'
                  'お客様のデータはFirebaseなどのサービスプロバイダーと'
                  '共有される場合があります。',
                  style: TextStyle(fontSize: 13, height: 1.6),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 親の同意を管理するプロバイダー
class ParentalConsentNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  ParentalConsentNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<void> submitConsent({
    required String parentEmail,
    required String childEmail,
    required Map<String, bool> consentData,
  }) async {
    state = const AsyncValue.loading();

    try {
      final firebaseService = ref.read(firebaseServiceProvider);
      final currentUser = firebaseService.currentUser;

      if (currentUser == null) {
        throw Exception('User not authenticated. Please sign in first.');
      }

      // Save parental consent to Firestore for audit trail (COPPA compliance)
      await firebaseService.saveParentalConsent(
        parentUid: currentUser.uid,
        childEmail: childEmail,
        consentData: consentData,
        privacyPolicyVersion: '1.0',
      );

      LoggerService().log(
        'Parental consent submitted for email: $parentEmail, child: $childEmail',
      );

      state = const AsyncValue.data(null);
    } catch (e, st) {
      LoggerService().logError('Failed to submit parental consent', error: e, stackTrace: st);
      state = AsyncValue.error(e, st);
    }
  }
}
