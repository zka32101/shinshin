import 'package:flutter/material.dart';
import 'package:shared_core/widgets/components/app_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/child_provider.dart';
import '../../providers/progress_provider.dart';
import '../../models/child_profile.dart';
import '../../utils/animation_constants.dart';
import '../../widgets/animations/index.dart';

const _primaryColor = Color(0xFF9B59B6);
const _bgColor = Color(0xFFF5F5F5);
const _cardColor = Color(0xFFFFFFFF);
const _textPrimary = Color(0xFF333333);
const _textSecondary = Color(0xFF999999);

class GrowthScreen extends ConsumerWidget {
  const GrowthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childAsync = ref.watch(selectedChildProvider);

    return Scaffold(
      backgroundColor: _bgColor,
      body: childAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('エラー: $e')),
        data: (child) => child == null
            ? const _NoChildView()
            : _GrowthContent(child: child),
      ),
    );
  }
}

class _NoChildView extends StatelessWidget {
  const _NoChildView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('👶', style: TextStyle(fontSize: 60)),
          SizedBox(height: 16),
          Text('子供プロフィールを作成してください', style: TextStyle(color: _textSecondary)),
        ],
      ),
    );
  }
}

class _GrowthContent extends ConsumerWidget {
  final ChildProfile child;
  const _GrowthContent({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      slivers: [
        // ヘッダー
        SliverAppBar(
          pinned: true,
          backgroundColor: _primaryColor,
          title: Text(
            '${child.name}の成長',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                child.avatarEmoji,
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ],
        ),

        SliverToBoxAdapter(
          child: AnimatedFadeInScale(
            duration: AnimationDurations.medium,
            beginScale: 0.95,
            endScale: 1.0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // レベル・ポイントカード
                  AnimatedSlideIn(
                    direction: SlideDirection.fromBottom,
                    duration: AnimationDurations.medium,
                    delay: const Duration(milliseconds: 100),
                    child: _LevelCard(child: child),
                  ),
                  const SizedBox(height: 16),

                  // 徳目レーダーチャート
                  AnimatedSlideIn(
                    direction: SlideDirection.fromBottom,
                    duration: AnimationDurations.medium,
                    delay: const Duration(milliseconds: 200),
                    child: _VirtueRadarCard(child: child),
                  ),
                  const SizedBox(height: 16),

                  // 徳目詳細リスト
                  AnimatedSlideIn(
                    direction: SlideDirection.fromBottom,
                    duration: AnimationDurations.medium,
                    delay: const Duration(milliseconds: 300),
                    child: _VirtueDetailList(child: child),
                  ),
                  const SizedBox(height: 16),

                  // 週間活動グラフ
                  AnimatedSlideIn(
                    direction: SlideDirection.fromBottom,
                    duration: AnimationDurations.medium,
                    delay: const Duration(milliseconds: 400),
                    child: _WeeklyActivityCard(childId: child.id),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LevelCard extends StatefulWidget {
  final ChildProfile child;
  const _LevelCard({required this.child});

  @override
  State<_LevelCard> createState() => _LevelCardState();
}

class _LevelCardState extends State<_LevelCard>
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

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
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
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final nextLevelPoints = widget.child.level * 100;
    final currentLevelPoints = widget.child.totalPoints % 100;
    final progress = currentLevelPoints / 100;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_primaryColor, Color(0xFF8E44AD)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: _primaryColor.withAlpha(80), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('現在のレベル', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text(
                        'レベル ${widget.child.level}',
                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('累計ポイント', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text(
                        '${widget.child.totalPoints}pt',
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '次のレベルまで: ${nextLevelPoints - currentLevelPoints}pt',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: Colors.white.withAlpha(60),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VirtueRadarCard extends StatefulWidget {
  final ChildProfile child;
  const _VirtueRadarCard({required this.child});

  @override
  State<_VirtueRadarCard> createState() => _VirtueRadarCardState();
}

class _VirtueRadarCardState extends State<_VirtueRadarCard>
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

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
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
            color: _cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🌈 徳目レーダーチャート',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textPrimary),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 240,
                child: RadarChart(
                  RadarChartData(
                    dataSets: [
                      RadarDataSet(
                        fillColor: _primaryColor.withAlpha(50),
                        borderColor: _primaryColor,
                        borderWidth: 2,
                        entryRadius: 4,
                        dataEntries: [
                          RadarEntry(value: widget.child.kindnessScore),
                          RadarEntry(value: widget.child.honestyScore),
                          RadarEntry(value: widget.child.responsibilityScore),
                          RadarEntry(value: widget.child.courageScore),
                          RadarEntry(value: widget.child.respectScore),
                          RadarEntry(value: widget.child.cooperationScore),
                        ],
                      ),
                    ],
                    // radarMaxValue removed (not in fl_chart 0.68.0)
                    tickCount: 5,
                    ticksTextStyle: const TextStyle(fontSize: 8, color: _textSecondary),
                    gridBorderData: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
                    titleTextStyle: const TextStyle(fontSize: 11, color: _textPrimary, fontWeight: FontWeight.w600),
                    getTitle: (index, angle) {
                      const titles = ['思いやり', '正直さ', '責任感', '勇気', '礼儀', '協調性'];
                      return RadarChartTitle(text: titles[index]);
                    },
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

class _VirtueDetailList extends StatefulWidget {
  final ChildProfile child;
  const _VirtueDetailList({required this.child});

  @override
  State<_VirtueDetailList> createState() => _VirtueDetailListState();
}

class _VirtueDetailListState extends State<_VirtueDetailList>
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

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
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
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final virtues = [
      _VirtueData('思いやり', '💜', widget.child.kindnessScore),
      _VirtueData('正直さ', '💛', widget.child.honestyScore),
      _VirtueData('責任感', '💙', widget.child.responsibilityScore),
      _VirtueData('勇気', '❤️', widget.child.courageScore),
      _VirtueData('礼儀', '💚', widget.child.respectScore),
      _VirtueData('協調性', '🧡', widget.child.cooperationScore),
    ];

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: Container(
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '📊 徳目スコア詳細',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textPrimary),
              ),
              const SizedBox(height: 12),
              ...virtues.map((v) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Text(v.emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 60,
                      child: Text(v.name, style: const TextStyle(fontSize: 13, color: _textPrimary)),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: v.score / 100,
                          minHeight: 8,
                          backgroundColor: const Color(0xFFEEEEEE),
                          valueColor: AlwaysStoppedAnimation(_getBarColor(v.score)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 36,
                      child: Text(
                        '${v.score.toInt()}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _textPrimary),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Color _getBarColor(double score) {
    if (score >= 80) return const Color(0xFF27AE60);
    if (score >= 60) return const Color(0xFF2ECC71);
    if (score >= 40) return const Color(0xFFF39C12);
    return const Color(0xFFE74C3C);
  }
}

class _WeeklyActivityCard extends ConsumerWidget {
  final String childId;
  const _WeeklyActivityCard({required this.childId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(weeklyActivityProvider(childId));
    final weeklyData = activityAsync.maybeWhen(
      data: (data) => data,
      orElse: () => List<int>.filled(7, 0),
    );
    final days = ['月', '火', '水', '木', '金', '土', '日'];

    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📅 今週の学習状況',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textPrimary),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 6,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= days.length) return const SizedBox.shrink();
                        return Text(days[idx], style: const TextStyle(fontSize: 11, color: _textSecondary));
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (i) => BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: weeklyData[i].toDouble(),
                      color: _primaryColor,
                      width: 20,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                  ],
                )),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '今週の合計: ${weeklyData.reduce((a, b) => a + b)} ストーリー',
              style: const TextStyle(fontSize: 12, color: _textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _VirtueData {
  final String name;
  final String emoji;
  final double score;
  const _VirtueData(this.name, this.emoji, this.score);
}
