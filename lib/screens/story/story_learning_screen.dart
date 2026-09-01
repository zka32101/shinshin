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
import 'story_result_screen.dart';
import '../../widgets/animated_option_card.dart';

const _primaryColor = Color(0xFF9B59B6);
const _bgColor = Color(0xFFFAF9FF);
const _textPrimary = Color(0xFF2C2C2C);
const _textSecondary = Color(0xFF888888);

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

  /// Phase tracking: 'reading' → 'choice' → 'branching' → 'reflection' → 'complete'
  String _currentPhase = 'reading'; // 'reading', 'choice', 'branching', 'reflection'

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
      vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();

    _slideController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 350));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _slideController.forward();

    // Start quiz session in background — result captured for completion
    WidgetsBinding.instance.addPostFrameCallback((_) => _startSession());
  }

  /// バックグラウンドでクイズセッションを開始する。
  /// オフラインや失敗時は _sessionId が null のまま → ローカル完了フォールバック。
  Future<void> _startSession() async {
    try {
      final id = await ref.read(
        quizStartProvider((
          childId: widget.childId,
          storyId: widget.storyId,
        )).future,
      );
      if (mounted) setState(() => _sessionId = id);
    } catch (_) {
      // オフライン or API エラー — セッション ID なしで続行
    }
  }

  @override
  void dispose() {
    // ナレーション停止 — ProviderScope が先に破棄された場合（テスト等）は無視
    try {
      ref.read(audioControllerProvider.notifier).stop();
    } catch (_) {}
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
        duration: const Duration(milliseconds: 350),
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
        duration: const Duration(milliseconds: 350),
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
      _currentPhase = 'branching'; // Move to branching phase
    });
    _animatePageChange();

    // 選択肢決定音を再生
    SoundEffectsUtils(ref).playChoiceMadeSound();

    AnalyticsService().logChoiceMade(
      storyId: story.id,
      choiceOrder: story.content?.choices.indexOf(choice) ?? -1,
      isRecommended: false,
    );
  }

  /// Move to reflection phase after showing the branching story
  void _showReflection() {
    setState(() => _currentPhase = 'reflection');
    _animatePageChange();
  }

  /// ストーリー完了 — APIにセッション完了を送信し、結果画面へ遷移する。
  Future<void> _complete(Story story) async {
    if (_completing) return; // 二重送信防止
    setState(() => _completing = true);

    // ストーリー完了音を再生
    SoundEffectsUtils(ref).playStoryCompleteSound();

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
      points = result.pointsEarned > 0 ? result.pointsEarned : 15;
    } else {
      // セッション未開始 (オフライン起動) — ローカル推定値
      points = _selectedChoice != null ? 15 : 10;
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

    // スコアをポイントから計算: 10pt→70%, 15pt→80%, 20pt→90%, 25pt+→100%
    final score = (50 + points * 2).clamp(0, 100);
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
        backgroundColor: _bgColor,
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
        backgroundColor: _bgColor,
        body: Center(child: CircularProgressIndicator(color: _primaryColor)),
      );
    }

    final isLastReadPage = _currentPage == pages.length - 1;

    // 初回表示時にナレーション自動起動
    if (!_storyNarrated && _currentPhase == 'reading') {
      _storyNarrated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _speakPage(pages));
    }

    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ─── ヘッダー ───
            _StoryHeader(
              story: story,
              currentPage: _currentPage,
              totalPages: pages.length,
              showOutcome: _currentPhase != 'reading',
              onClose: () => _confirmExit(context),
            ),

            // ─── コンテンツ ───
            Expanded(
              child: _currentPhase == 'reading' && isLastReadPage
                  ? _ChoiceView(
                      story: story,
                      fadeAnim: _fadeAnim,
                      onChoiceSelected: (c) => _selectChoice(story, c),
                    )
                  : _currentPhase == 'branching' && _selectedChoice != null
                      ? _BranchingStoryView(
                          choice: _selectedChoice!,
                          fadeAnim: _fadeAnim,
                          slideAnim: _slideAnim,
                          onContinue: _showReflection,
                        )
                      : _currentPhase == 'reflection' && _selectedChoice != null
                          ? _ReflectionView(
                              choice: _selectedChoice!,
                              fadeAnim: _fadeAnim,
                              slideAnim: _slideAnim,
                              isCompleting: _completing,
                              onComplete:
                                  _completing ? null : () => _complete(story),
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
            if (_currentPhase == 'reading' && !isLastReadPage)
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
          colors: [_primaryColor, Color(0xFF8E44AD)],
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
                        color: _primaryColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'はじめに',
                        style: TextStyle(
                          color: _primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (!isIntro && index == pages.length - 2)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3CD),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFD43B).withAlpha(100)),
                      ),
                      child: const Row(
                        children: [
                          Text('⚡', style: TextStyle(fontSize: 18)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'もうすぐジレンマの場面です。よく読んで考えてみよう！',
                              style: TextStyle(fontSize: 13, color: Color(0xFF856404)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Text(
                    pages[index],
                    style: const TextStyle(
                      fontSize: 17,
                      height: 2.0,
                      color: _textPrimary,
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
                color: const Color(0xFFF3E5F5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _primaryColor.withAlpha(60)),
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
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    story.content?.dilemmaScene ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.8,
                      color: _textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              'どれを選ぶ？',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _textSecondary,
              ),
            ),
            const SizedBox(height: 12),

            // 選択肢
            ...?story.content?.choices.asMap().entries.map((e) {
              final labels = ['A', 'B', 'C', 'D'];
              final label = e.key < labels.length ? labels[e.key] : '${e.key + 1}';
              return Padding(
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
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: _primaryColor.withAlpha(15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _primaryColor.withAlpha(60)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'あなたの選択',
                      style: TextStyle(
                        fontSize: 12,
                        color: _textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      choice.text,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _primaryColor,
                      ),
                    ),
                  ],
                ),
              ),

              // 分岐ストーリーヘッダー
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryColor.withAlpha(30), _primaryColor.withAlpha(15)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _primaryColor.withAlpha(80)),
                ),
                child: const Row(
                  children: [
                    Text('📖', style: TextStyle(fontSize: 16)),
                    SizedBox(width: 8),
                    Text(
                      'その後のおはなし',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _primaryColor,
                      ),
                    ),
                  ],
                ),
              ),

              // 分岐ストーリーテキスト
              Text(
                choice.branchContent,
                style: const TextStyle(
                  fontSize: 16,
                  height: 2.0,
                  color: _textPrimary,
                  letterSpacing: 0.3,
                ),
              ),

              const SizedBox(height: 32),

              // 続ける ボタン
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'ふりかえりへ',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward),
                    ],
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
    final virtueEmoji = _virtueEmoji(choice.value ?? '');

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
              Row(
                children: [
                  Text(virtueEmoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 10),
                  const Text(
                    'あなたの選択',
                    style: TextStyle(
                      fontSize: 13,
                      color: _textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _primaryColor.withAlpha(15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _primaryColor.withAlpha(60)),
                ),
                child: Text(
                  choice.text,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _primaryColor,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 振り返り
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFFE082)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Text('💭', style: TextStyle(fontSize: 18)),
                        SizedBox(width: 8),
                        Text(
                          'ふりかえり',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF856404),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      choice.reflection,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF856404),
                        height: 1.7,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // 完了ボタン
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onComplete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: isCompleting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '結果を見る',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward),
                          ],
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

  String _virtueEmoji(String value) {
    switch (value) {
      case 'kindness': return '💜';
      case 'honesty': return '💛';
      case 'responsibility': return '💙';
      case 'courage': return '❤️';
      case 'respect': return '💚';
      case 'cooperation': return '🧡';
      default: return '⭐';
    }
  }
}

// ─── 選択後の結果表示 ──────────────────────────────

class _OutcomeView extends StatelessWidget {
  final StoryChoice choice;
  final Animation<double> fadeAnim;
  final Animation<Offset> slideAnim;
  final VoidCallback? onComplete;
  final bool isCompleting;

  const _OutcomeView({
    required this.choice,
    required this.fadeAnim,
    required this.slideAnim,
    required this.onComplete,
    this.isCompleting = false,
  });

  @override
  Widget build(BuildContext context) {
    final virtueEmoji = _virtueEmoji(choice.value ?? '');

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
              Row(
                children: [
                  Text(virtueEmoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 10),
                  const Text(
                    'あなたの選択',
                    style: TextStyle(
                      fontSize: 13,
                      color: _textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _primaryColor.withAlpha(15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _primaryColor.withAlpha(60)),
                ),
                child: Text(
                  choice.text,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _primaryColor,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 結果テキスト
              const Text(
                '📖 その後のおはなし',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                choice.branchContent,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.9,
                  color: _textPrimary,
                ),
              ),

              const SizedBox(height: 24),

              // 振り返り
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFFE082)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Text('💭', style: TextStyle(fontSize: 18)),
                        SizedBox(width: 8),
                        Text(
                          'ふりかえり',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF856404),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      choice.reflection,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF856404),
                        height: 1.7,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // 完了ボタン
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onComplete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: isCompleting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '結果を見る',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward),
                          ],
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

  String _virtueEmoji(String value) {
    switch (value) {
      case 'kindness': return '💜';
      case 'honesty': return '💛';
      case 'responsibility': return '💙';
      case 'courage': return '❤️';
      case 'respect': return '💚';
      case 'cooperation': return '🧡';
      default: return '⭐';
    }
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
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
                  side: const BorderSide(color: Color(0xFFE0E0E0)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
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
                backgroundColor: isNearEnd ? const Color(0xFFE74C3C) : _primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isNearEnd ? '選択へ進む 🤔' : '次のページへ',
                    style: const TextStyle(
                      fontSize: 15,
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
