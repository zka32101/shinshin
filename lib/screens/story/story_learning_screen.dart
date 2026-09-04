import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/story.dart';
import '../../providers/story_provider.dart';
import '../../providers/audio_provider.dart';
import '../../providers/child_provider.dart';
import '../../providers/progress_provider.dart';
import '../../providers/quiz_completion_provider.dart';
import '../../providers/firestore_provider.dart';
import '../../services/analytics_service.dart';
import '../../utils/sound_effects_utils.dart';
import '../../utils/animation_constants.dart';
import '../../widgets/animations/index.dart';
import '../../constants/virtue_constants.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../constants/app_constants.dart';
import 'story_result_screen.dart';
import '../../widgets/animated_option_card.dart';

/// ストーリー読解画面
/// 読む → 選択 → 結果の3フェーズ
class StoryLearningScreen extends ConsumerStatefulWidget {
  final String storyId;
  final String childId;

  const StoryLearningScreen({
    super.key,
    required this.storyId,
    required this.childId,
  });

  @override
  ConsumerState<StoryLearningScreen> createState() => _StoryLearningScreenState();
}

class _StoryLearningScreenState extends ConsumerState<StoryLearningScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  StoryChoice? _selectedChoice;

  /// Phase tracking: reading → choice → branching → reflection → complete
  String _currentPhase = AppConstants.phaseReading;

  bool _completing = false;
  bool _storyNarrated = false; // 最初のページを自動読み上げ済みかどうか

  /// Session ID from backend — null until the API responds (or if offline)
  String? _sessionId;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnim;

  final _startTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this, duration: AppStyles.animationSlow);
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();

    _slideController = AnimationController(
      vsync: this, duration: AppStyles.animationNormal);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _slideController.forward();

    // Start quiz session in background — result captured for completion
    WidgetsBinding.instance.addPostFrameCallback((_) => _startSession());
  }

  /// バックグラウンドでクイズセッションを開始する。
  /// オフラインや失敗時は _sessionId が null のまま → ローカル完了フォールバック。
  /// マウント状態と widget.childId が有効であることを確認してから実行。
  Future<void> _startSession() async {
    if (!mounted || widget.childId.isEmpty) return;

    try {
      final id = await ref.read(
        quizStartProvider((
          childId: widget.childId,
          storyId: widget.storyId,
        )).future,
      );
      // setStateの前に再度マウント状態を確認
      if (mounted && id != null) {
        setState(() => _sessionId = id);
      }
    } catch (e) {
      // オフライン or API エラー — セッション ID なしで続行
      debugPrint('Failed to start quiz session: $e');
    }
  }

  @override
  void dispose() {
    // ナレーション停止 — ProviderScope が先に破棄された場合（テスト等）は無視
    try {
      if (mounted) {
        final audioController = ref.read(audioControllerProvider.notifier);
        audioController.stop();
      }
    } catch (e) {
      debugPrint('Error stopping audio during dispose: $e');
    }
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  List<String> _buildPages(Story story) {
    // content は detail エンドポイントが常に返す。
    // ただし Hive キャッシュからのフォールバック時はリスト取得分のみで null になる可能性がある。
    final c = story.content;
    if (c == null) return const [];
    return [
      c.introduction,
      ...c.mainNarrative,
      c.dilemmaScene,
    ];
  }

  void _nextPage(int total) {
    if (_currentPage < total - 1) {
      _pageController.nextPage(
        duration: AppStyles.animationNormal,
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage++);
      _animatePageChange();
      // ページ遷移後にナレーション (storyAsync の pages が必要なため storyId 経由で取得しない — 呼び出し元で渡す)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final story = ref.read(storyDetailProvider(widget.storyId)).asData?.value;
        if (story != null) _speakPage(_buildPages(story));
      });
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: AppStyles.animationNormal,
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage--);
      _animatePageChange();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final story = ref.read(storyDetailProvider(widget.storyId)).asData?.value;
        if (story != null) _speakPage(_buildPages(story));
      });
    }
  }

  void _animatePageChange() {
    _fadeController.forward(from: 0);
    _slideController.forward(from: 0);
  }

  /// ナレーション: 現在ページのテキストを読み上げる
  void _speakPage(List<String> pages) {
    if (!ref.read(isNarrationEnabledProvider)) return;
    if (_currentPage >= pages.length) return;
    final audio = ref.read(audioControllerProvider.notifier);
    audio.speakText(pages[_currentPage], audioId: 'page_$_currentPage');
  }

  void _selectChoice(Story story, StoryChoice choice) {
    setState(() {
      _selectedChoice = choice;
      _currentPhase = AppConstants.phaseBranching;
    });
    _animatePageChange();

    // 選択肢決定音を再生
    unawaited(SoundEffectsUtils(ref as Ref<dynamic>).playChoiceMadeSound());

    AnalyticsService().logChoiceMade(
      storyId: story.id,
      choiceOrder: story.content?.choices.indexOf(choice) ?? -1,
      isRecommended: false,
    );
  }

  /// Move to reflection phase after showing the branching story
  void _showReflection() {
    setState(() => _currentPhase = AppConstants.phaseReflection);
    _animatePageChange();
  }

  /// ストーリー完了 — APIにセッション完了を送信し、結果画面へ遷移する。
  Future<void> _complete(Story story) async {
    if (_completing) return; // 二重送信防止
    setState(() => _completing = true);

    // ストーリー完了音を再生
    unawaited(SoundEffectsUtils(ref as Ref<dynamic>).playStoryCompleteSound());

    final elapsed = DateTime.now().difference(_startTime).inSeconds;

    int points;
    if (_sessionId != null && _selectedChoice != null) {
      // オンライン: APIで完了・ポイントを取得 (オフライン時はプロバイダーがHiveにエンキュー)
      final result = await ref.read(
        quizCompleteProvider((
          sessionId: _sessionId!,
          childId: widget.childId,
          chosenChoiceId: _selectedChoice!.id,
          timeSpentSeconds: elapsed,
          reflectionText: null,
        )).future,
      );
      // オフラインフォールバックは pointsEarned == 0 を返す → ローカル推定値で補完
      points = result.pointsEarned > 0
          ? result.pointsEarned
          : AppConstants.estimatedPointsWithChoice;
    } else {
      // セッション未開始 (オフライン起動) — ローカル推定値
      points = _selectedChoice != null
          ? AppConstants.estimatedPointsWithChoice
          : AppConstants.estimatedPointsWithoutChoice;
    }

    if (!mounted) return;

    // 子どもプロフィール（totalPoints）と進捗リストを無効化 → ホーム・成長画面で最新値を表示
    ref.invalidate(childProfileProvider(widget.childId));
    ref.invalidate(userProgressProvider(widget.childId));

    AnalyticsService().logStoryCompleted(
      storyId: story.id,
      theme: story.theme,
      pointsEarned: points,
      timeSpentSeconds: elapsed,
      chosenVirtue: _selectedChoice?.value ?? '',
    );

    // Firestore にクエスト完了を記録 (fire-and-forget — Firebase 未初期化時は無視)
    final uid = ref.read(currentUidProvider);
    if (uid != null && widget.childId.isNotEmpty) {
      ref
          .read(firestoreServiceProvider)
          .recordQuestCompletion(
            uid: uid,
            childId: widget.childId,
            storyId: story.id,
            pointsDelta: points,
            chosenVirtue: _selectedChoice?.value ?? story.theme,
            timeSpentSeconds: elapsed,
          )
          .catchError((_) {});
    }

    // スコアをポイントから計算
    final score = (AppConstants.scoreBaseValue + points * AppConstants.scorePointMultiplier)
        .clamp(AppConstants.scoreMinValue, AppConstants.scoreMaxValue);
    final navigator = Navigator.of(context);
    navigator.pushReplacement(
      MaterialPageRoute(
        builder: (_) => StoryResultScreen(
          storyTitle: story.title,
          score: score,
          pointsEarned: points,
          childId: widget.childId,
          chosenChoice: _selectedChoice,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storyAsync = ref.watch(storyDetailProvider(widget.storyId));

    return storyAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('エラー: $e')),
      ),
      data: (story) => _buildStory(context, story),
    );
  }

  Widget _buildStory(BuildContext context, Story story) {
    final pages = _buildPages(story);

    // content が null（リストキャッシュからのフォールバック時）— ローディングを再表示
    if (pages.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final isLastReadPage = _currentPage == pages.length - 1;

    // 初回表示時にナレーション自動起動
    if (!_storyNarrated && _currentPhase == AppConstants.phaseReading) {
      _storyNarrated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _speakPage(pages));
    }

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // ─── ヘッダー ───
            _StoryHeader(
              story: story,
              currentPage: _currentPage,
              totalPages: pages.length,
              showOutcome: _currentPhase != AppConstants.phaseReading,
              onClose: () => _confirmExit(context),
            ),

            // ─── コンテンツ ───
            Expanded(
              child: _currentPhase == AppConstants.phaseReading &&
                      isLastReadPage
                  ? _ChoiceView(
                      story: story,
                      fadeAnim: _fadeAnim,
                      onChoiceSelected: (c) => _selectChoice(story, c),
                    )
                  : _currentPhase == AppConstants.phaseBranching &&
                          _selectedChoice != null
                      ? _BranchingStoryView(
                          choice: _selectedChoice!,
                          fadeAnim: _fadeAnim,
                          slideAnim: _slideAnim,
                          onContinue: _showReflection,
                        )
                      : _currentPhase == AppConstants.phaseReflection &&
                              _selectedChoice != null
                          ? _ReflectionView(
                              choice: _selectedChoice!,
                              fadeAnim: _fadeAnim,
                              slideAnim: _slideAnim,
                              isCompleting: _completing,
                              onComplete: _completing
                                  ? null
                                  : () => _complete(story),
                            )
                          : _NarrativePageView(
                              pages: pages,
                              controller: _pageController,
                              currentPage: _currentPage,
                              fadeAnim: _fadeAnim,
                              slideAnim: _slideAnim,
                            ),
            ),

            // ─── ナビゲーション ───
            if (_currentPhase == AppConstants.phaseReading && !isLastReadPage)
              _NavigationBar(
                currentPage: _currentPage,
                totalPages: pages.length,
                onPrev: _currentPage > 0 ? _prevPage : null,
                onNext: () => _nextPage(pages.length),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmExit(BuildContext context) async {
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ストーリーを中断しますか？'),
        content: const Text('進捗は保存されません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('続ける'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('中断する', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) navigator.pop();
  }
}

// ─── ヘッダー ─────────────────────────────────────

class _StoryHeader extends StatelessWidget {
  final Story story;
  final int currentPage;
  final int totalPages;
  final bool showOutcome;
  final VoidCallback onClose;

  const _StoryHeader({
    required this.story,
    required this.currentPage,
    required this.totalPages,
    required this.showOutcome,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final progress = showOutcome ? 1.0 : (currentPage + 1) / (totalPages + 1);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: onClose,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        story.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (!showOutcome)
                        Text(
                          '${currentPage + 1} / $totalPages ページ',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        )
                      else
                        const Text(
                          '✅ 選択完了',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                    ],
                  ),
                ),
                // 音声ナレーション ボタン
                const _AudioButton(),
              ],
            ),
          ),
          // プログレスバー
          TweenAnimationBuilder<double>(
            tween: Tween(end: progress),
            duration: const Duration(milliseconds: 400),
            builder: (context, val, child) => LinearProgressIndicator(
              value: val,
              minHeight: 3,
              backgroundColor: Colors.white.withAlpha(50),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── ページ表示 ───────────────────────────────────

class _NarrativePageView extends StatelessWidget {
  final List<String> pages;
  final PageController controller;
  final int currentPage;
  final Animation<double> fadeAnim;
  final Animation<Offset> slideAnim;

  const _NarrativePageView({
    required this.pages,
    required this.controller,
    required this.currentPage,
    required this.fadeAnim,
    required this.slideAnim,
  });

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: controller,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: pages.length,
      itemBuilder: (context, index) {
        final isIntro = index == 0;
        return FadeTransition(
          opacity: fadeAnim,
          child: SlideTransition(
            position: slideAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isIntro)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(AppConstants.alphaLight),
                        borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
                      ),
                      child: const Text(
                        'はじめに',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: AppStyles.fontSizeSmallMedium,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (!isIntro && index == pages.length - 2)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.warningBg,
                        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                        border: Border.all(
                            color: AppColors.warningBorder
                                .withAlpha(AppConstants.alphaHighlight)),
                      ),
                      child: const Row(
                        children: [
                          Text('⚡', style: TextStyle(fontSize: AppStyles.fontSizeTitle)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'もうすぐジレンマの場面です。よく読んで考えてみよう！',
                              style: TextStyle(
                                  fontSize: AppStyles.fontSizeBase,
                                  color: AppColors.reflectionText),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Text(
                    pages[index],
                    style: const TextStyle(
                      fontSize: AppStyles.fontSizeLargeTitle,
                      height: 2.0,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── 選択肢画面 ────────────────────────────────────

class _ChoiceView extends StatelessWidget {
  final Story story;
  final Animation<double> fadeAnim;
  final ValueChanged<StoryChoice> onChoiceSelected;

  const _ChoiceView({
    required this.story,
    required this.fadeAnim,
    required this.onChoiceSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnim,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ジレンマ場面
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.dilemmaBg,
                borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
                border: Border.all(
                    color: AppColors.primary
                        .withAlpha(AppConstants.alphaDark)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text('🤔', style: TextStyle(fontSize: 20)),
                      SizedBox(width: 8),
                      Text(
                        'どうする？',
                        style: TextStyle(
                          fontSize: AppStyles.fontSizeTitle,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    story.content?.dilemmaScene ?? '',
                    style: const TextStyle(
                      fontSize: AppStyles.fontSizeLarge,
                      height: 1.8,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              'どれを選ぶ？',
              style: TextStyle(
                fontSize: AppStyles.fontSizeMedium,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),

            // 選択肢
            ...?story.content?.choices.asMap().entries.map((e) {
              final labels = ['A', 'B', 'C', 'D'];
              final label = e.key < labels.length ? labels[e.key] : '${e.key + 1}';
              return AnimatedSlideIn(
                direction: SlideDirection.fromBottom,
                duration: AnimationDurations.medium,
                delay: Duration(milliseconds: 200 + (e.key * 100)),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AnimatedOptionCard(
                    key: ValueKey(e.value.id),
                    label: label,
                    text: e.value.text,
                    isSelected: false,
                    isCorrect: false,
                    showFeedback: false,
                    onTap: () => onChoiceSelected(e.value),
                  ),
                ),
              );
            }),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─── 分岐ストーリー表示 ────────────────────────────

/// Shows the branching story (branchContent) with distinct styling
class _BranchingStoryView extends StatelessWidget {
  final StoryChoice choice;
  final Animation<double> fadeAnim;
  final Animation<Offset> slideAnim;
  final VoidCallback onContinue;

  const _BranchingStoryView({
    required this.choice,
    required this.fadeAnim,
    required this.slideAnim,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnim,
      child: SlideTransition(
        position: slideAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 選択の確認
              AnimatedSlideIn(
                direction: SlideDirection.fromBottom,
                duration: AnimationDurations.medium,
                delay: Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.primary
                        .withAlpha(AppConstants.alphaVeryLight),
                    borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                    border: Border.all(
                        color: AppColors.primary
                            .withAlpha(AppConstants.alphaDark)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'あなたの選択',
                        style: TextStyle(
                          fontSize: AppStyles.fontSizeSmallMedium,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        choice.text,
                        style: const TextStyle(
                          fontSize: AppStyles.fontSizeMedium,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 分岐ストーリーヘッダー
              AnimatedSlideIn(
                direction: SlideDirection.fromBottom,
                duration: AnimationDurations.medium,
                delay: Duration(milliseconds: 300),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary
                            .withAlpha(AppConstants.alphaLight),
                        AppColors.primary
                            .withAlpha(AppConstants.alphaVeryLight)
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
                    border: Border.all(
                        color: AppColors.primary
                            .withAlpha(AppConstants.alphaMedium)),
                  ),
                  child: const Row(
                    children: [
                      Text('📖', style: TextStyle(fontSize: AppStyles.fontSizeTitle)),
                      SizedBox(width: 8),
                      Text(
                        'その後のおはなし',
                        style: TextStyle(
                          fontSize: AppStyles.fontSizeBase,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 分岐ストーリーテキスト
              Text(
                choice.branchContent,
                style: const TextStyle(
                  fontSize: AppStyles.fontSizeLarge,
                  height: 2.0,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.3,
                ),
              ),

              const SizedBox(height: 32),

              // 続ける ボタン
              AnimatedSlideIn(
                direction: SlideDirection.fromBottom,
                duration: AnimationDurations.medium,
                delay: Duration(milliseconds: 400),
                child: SizedBox(
                  width: double.infinity,
                  child: _StoryActionButton(
                    label: 'ふりかえりへ',
                    onPressed: onContinue,
                    icon: Icons.arrow_forward,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── ふりかえり表示 ────────────────────────────────

/// Shows the reflection/learning point
class _ReflectionView extends StatelessWidget {
  final StoryChoice choice;
  final Animation<double> fadeAnim;
  final Animation<Offset> slideAnim;
  final VoidCallback? onComplete;
  final bool isCompleting;

  const _ReflectionView({
    required this.choice,
    required this.fadeAnim,
    required this.slideAnim,
    required this.onComplete,
    this.isCompleting = false,
  });

  @override
  Widget build(BuildContext context) {
    final virtueEmoji = VirtueConstants.getVirtueEmoji(choice.value);

    return FadeTransition(
      opacity: fadeAnim,
      child: SlideTransition(
        position: slideAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 選択ラベル
              AnimatedSlideIn(
                direction: SlideDirection.fromBottom,
                duration: AnimationDurations.medium,
                delay: Duration(milliseconds: 200),
                child: Row(
                  children: [
                    Text(virtueEmoji,
                        style: const TextStyle(fontSize: AppStyles.fontSizeEmoji)),
                    const SizedBox(width: 10),
                    const Text(
                      'あなたの選択',
                      style: TextStyle(
                        fontSize: AppStyles.fontSizeBase,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              AnimatedSlideIn(
                direction: SlideDirection.fromBottom,
                duration: AnimationDurations.medium,
                delay: Duration(milliseconds: 250),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary
                        .withAlpha(AppConstants.alphaVeryLight),
                    borderRadius:
                        BorderRadius.circular(AppStyles.radiusMedium),
                    border: Border.all(
                        color: AppColors.primary
                            .withAlpha(AppConstants.alphaDark)),
                  ),
                  child: Text(
                    choice.text,
                    style: const TextStyle(
                      fontSize: AppStyles.fontSizeTitle,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 振り返り
              AnimatedSlideIn(
                direction: SlideDirection.fromBottom,
                duration: AnimationDurations.medium,
                delay: Duration(milliseconds: 300),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.reflectionBg,
                    borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                    border: Border.all(color: AppColors.reflectionBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Text('💭',
                              style: TextStyle(fontSize: AppStyles.fontSizeTitle)),
                          SizedBox(width: 8),
                          Text(
                            'ふりかえり',
                            style: TextStyle(
                              fontSize: AppStyles.fontSizeMedium,
                              fontWeight: FontWeight.bold,
                              color: AppColors.reflectionText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        choice.reflection,
                        style: const TextStyle(
                          fontSize: AppStyles.fontSizeMedium,
                          color: AppColors.reflectionText,
                          height: 1.7,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // 完了ボタン
              AnimatedSlideIn(
                direction: SlideDirection.fromBottom,
                duration: AnimationDurations.medium,
                delay: Duration(milliseconds: 350),
                child: SizedBox(
                  width: double.infinity,
                  child: _StoryActionButton(
                    label: '結果を見る',
                    onPressed: onComplete,
                    isLoading: isCompleting,
                    icon: Icons.arrow_forward,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── ナビゲーションバー ────────────────────────────

class _NavigationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback? onPrev;
  final VoidCallback onNext;

  const _NavigationBar({
    required this.currentPage,
    required this.totalPages,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final isNearEnd = currentPage >= totalPages - 2;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: AppStyles.shadowSmall,
      ),
      child: Row(
        children: [
          // 戻るボタン
          if (onPrev != null)
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: onPrev,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppStyles.radiusMedium)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_back, size: 16),
                    SizedBox(width: 4),
                    Text('前へ'),
                  ],
                ),
              ),
            ),

          if (onPrev != null) const SizedBox(width: 12),

          // 次へボタン
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isNearEnd ? AppColors.error : AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppStyles.radiusMedium)),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isNearEnd ? '選択へ進む 🤔' : '次のページへ',
                    style: const TextStyle(
                      fontSize: AppStyles.fontSizeTitle,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (!isNearEnd)
                    const Icon(Icons.arrow_forward, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 音声ボタン ────────────────────────────────────

class _AudioButton extends ConsumerWidget {
  const _AudioButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isNarrating = ref.watch(isNarrationEnabledProvider);

    return IconButton(
      icon: Icon(
        isNarrating ? Icons.volume_up : Icons.volume_off,
        color: Colors.white,
      ),
      onPressed: () {
        ref.read(isNarrationEnabledProvider.notifier).state = !isNarrating;
      },
    );
  }
}

// ─── ストーリーアクション ボタン ───────────────────

/// Reusable action button with tap feedback and optional loading state
class _StoryActionButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  const _StoryActionButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  @override
  State<_StoryActionButton> createState() => _StoryActionButtonState();
}

class _StoryActionButtonState extends State<_StoryActionButton>
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
    if (!widget.isLoading) {
      setState(() => _isPressed = true);
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails _) {
    setState(() => _isPressed = false);
    _controller.reverse();
    if (!widget.isLoading && widget.onPressed != null) {
      widget.onPressed!();
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
        child: ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
            ),
            elevation: 0,
          ),
          child: widget.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.label,
                      style: const TextStyle(
                        fontSize: AppStyles.fontSizeLarge,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.icon != null) ...[
                      const SizedBox(width: 8),
                      Icon(widget.icon),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
