import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../constants/virtue_constants.dart';
import '../../models/badge.dart';
import '../../models/report.dart';
import '../../providers/badge_provider.dart';
import '../../providers/child_provider.dart';
import '../../providers/report_provider.dart';
import '../../utils/animation_constants.dart';
import '../../widgets/animations/index.dart';

const _primaryColor = Color(0xFF9B59B6);
const _bgColor = Color(0xFFF5F5F5);
const _cardColor = Color(0xFFFFFFFF);
const _textPrimary = Color(0xFF333333);
const _textSecondary = Color(0xFF999999);

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  late int _selectedYear;
  late int _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonth = now.month;
  }

  @override
  Widget build(BuildContext context) {
    final childAsync = ref.watch(selectedChildProvider);

    return Scaffold(
      backgroundColor: _bgColor,
      body: childAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('エラー: $e')),
        data: (child) => child == null
            ? const Center(child: Text('子供プロフィールを作成してください'))
            : _buildReportContent(child.id),
      ),
    );
  }

  Widget _buildReportContent(String childId) {
    final reportKey = (childId: childId, year: _selectedYear, month: _selectedMonth);
    final reportAsync = ref.watch(monthlyReportProvider(reportKey));
    final previousReportAsync = ref.watch(previousMonthReportProvider(reportKey));

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: _primaryColor,
          title: const Text(
            '月次成長レポート',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        SliverToBoxAdapter(
          child: AnimatedSlideIn(
            direction: SlideDirection.fromBottom,
            duration: AnimationDurations.medium,
            delay: const Duration(milliseconds: 100),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _MonthSelector(
                year: _selectedYear,
                month: _selectedMonth,
                onChanged: (year, month) => setState(() {
                  _selectedYear = year;
                  _selectedMonth = month;
                }),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: AnimatedFadeInScale(
            duration: AnimationDurations.medium,
            beginScale: 0.95,
            endScale: 1.0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: reportAsync.when(
                loading: () => const Center(
                  child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()),
                ),
                error: (e, _) => AnimatedSlideIn(
                  direction: SlideDirection.fromBottom,
                  duration: AnimationDurations.medium,
                  delay: const Duration(milliseconds: 200),
                  child: _ErrorCard(error: e.toString()),
                ),
                data: (report) => report == null
                    ? AnimatedSlideIn(
                      direction: SlideDirection.fromBottom,
                      duration: AnimationDurations.medium,
                      delay: const Duration(milliseconds: 200),
                      child: _EmptyReportCard(year: _selectedYear, month: _selectedMonth, childId: childId),
                    )
                    : previousReportAsync.when(
                      data: (previousReport) => _ReportContent(
                        report: report,
                        previousReport: previousReport,
                      ),
                      loading: () => _ReportContent(
                        report: report,
                        previousReport: null,
                      ),
                      error: (_, __) => _ReportContent(
                        report: report,
                        previousReport: null,
                      ),
                    ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MonthSelector extends StatefulWidget {
  final int year;
  final int month;
  final Function(int, int) onChanged;
  const _MonthSelector({required this.year, required this.month, required this.onChanged});

  @override
  State<_MonthSelector> createState() => _MonthSelectorState();
}

class _MonthSelectorState extends State<_MonthSelector> {
  bool _showMonthPicker = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  final prev = DateTime(widget.year, widget.month - 1);
                  widget.onChanged(prev.year, prev.month);
                },
              ),
              GestureDetector(
                onTap: () => setState(() => _showMonthPicker = !_showMonthPicker),
                child: Row(
                  children: [
                    Text('${widget.year}年 ${widget.month}月',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textPrimary)),
                    const SizedBox(width: 8),
                    Icon(
                      _showMonthPicker ? Icons.expand_less : Icons.expand_more,
                      size: 20,
                      color: _textSecondary,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: DateTime(widget.year, widget.month).isAfter(DateTime.now())
                    ? null
                    : () {
                        final next = DateTime(widget.year, widget.month + 1);
                        widget.onChanged(next.year, next.month);
                      },
              ),
            ],
          ),
        ),
        if (_showMonthPicker) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.2,
                  ),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    final selectMonth = index + 1;
                    final selectYear = widget.year;
                    final isSelected = selectMonth == widget.month && selectYear == widget.year;
                    final isFuture = DateTime(selectYear, selectMonth).isAfter(DateTime.now());

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: isFuture ? null : () {
                          widget.onChanged(selectYear, selectMonth);
                          setState(() => _showMonthPicker = false);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? _primaryColor.withAlpha(40) : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? _primaryColor : Colors.grey.shade200,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '$selectMonth月',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                color: isFuture ? Colors.grey.shade400 : _textPrimary,
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
        ],
      ],
    );
  }
}

class _ReportContent extends StatelessWidget {
  final MonthlyReport report;
  final MonthlyReport? previousReport;
  const _ReportContent({required this.report, this.previousReport});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedSlideIn(
          direction: SlideDirection.fromBottom,
          duration: AnimationDurations.medium,
          delay: const Duration(milliseconds: 200),
          child: _SummaryCard(report: report),
        ),
        const SizedBox(height: 16),
        AnimatedSlideIn(
          direction: SlideDirection.fromBottom,
          duration: AnimationDurations.medium,
          delay: const Duration(milliseconds: 250),
          child: _BadgeSectionForReport(childId: report.childId),
        ),
        const SizedBox(height: 16),
        AnimatedSlideIn(
          direction: SlideDirection.fromBottom,
          duration: AnimationDurations.medium,
          delay: const Duration(milliseconds: 300),
          child: _AICommentCard(report: report),
        ),
        const SizedBox(height: 16),
        if (previousReport != null)
          AnimatedSlideIn(
            direction: SlideDirection.fromBottom,
            duration: AnimationDurations.medium,
            delay: const Duration(milliseconds: 350),
            child: _GrowthComparisonCard(current: report, previous: previousReport!),
          ),
        if (previousReport != null) const SizedBox(height: 16),
        AnimatedSlideIn(
          direction: SlideDirection.fromBottom,
          duration: AnimationDurations.medium,
          delay: Duration(milliseconds: previousReport != null ? 400 : 350),
          child: _ReportRadarCard(
            report: report,
            previousReport: previousReport,
          ),
        ),
        const SizedBox(height: 16),
        AnimatedSlideIn(
          direction: SlideDirection.fromBottom,
          duration: AnimationDurations.medium,
          delay: Duration(milliseconds: previousReport != null ? 500 : 450),
          child: _VirtueScoreTrends(report: report),
        ),
        const SizedBox(height: 16),
        if (report.parentMessage != null)
          AnimatedSlideIn(
            direction: SlideDirection.fromBottom,
            duration: AnimationDurations.medium,
            delay: Duration(milliseconds: previousReport != null ? 600 : 550),
            child: _ParentMessageCard(message: report.parentMessage!),
          ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _SummaryCard extends StatefulWidget {
  final MonthlyReport report;
  const _SummaryCard({required this.report});

  @override
  State<_SummaryCard> createState() => _SummaryCardState();
}

class _SummaryCardState extends State<_SummaryCard>
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
            gradient: const LinearGradient(
              colors: [_primaryColor, Color(0xFF8E44AD)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: _primaryColor.withAlpha(80), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${widget.report.year}年${widget.report.month}月の成果',
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(label: '完了ストーリー', value: '${widget.report.storiesCompleted}', unit: '個'),
                  _StatItem(label: '学習時間', value: '${widget.report.totalStudyMinutes}', unit: '分'),
                  _StatItem(label: '獲得ポイント', value: '${widget.report.totalPointsEarned}', unit: 'pt'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  const _StatItem({required this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RichText(
          text: TextSpan(children: [
            TextSpan(text: value,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            TextSpan(text: unit, style: const TextStyle(fontSize: 14, color: Colors.white70)),
          ]),
        ),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
      ],
    );
  }
}

class _AICommentCard extends StatefulWidget {
  final MonthlyReport report;
  const _AICommentCard({required this.report});

  @override
  State<_AICommentCard> createState() => _AICommentCardState();
}

class _AICommentCardState extends State<_AICommentCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;
  bool _expandedHighlight = false;
  bool _expandedGrowth = false;
  bool _expandedAdvice = false;

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
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('✨ 今月の頑張り',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textPrimary)),
              const SizedBox(height: 12),
              if (widget.report.highlightComment != null)
                _ExpandableCommentBlock(
                  emoji: '🌟',
                  label: '今月のハイライト',
                  text: widget.report.highlightComment!,
                  isExpanded: _expandedHighlight,
                  onToggle: () => setState(() => _expandedHighlight = !_expandedHighlight),
                ),
              if (widget.report.growthComment != null) ...[
                const SizedBox(height: 10),
                _ExpandableCommentBlock(
                  emoji: '📈',
                  label: '成長ポイント',
                  text: widget.report.growthComment!,
                  isExpanded: _expandedGrowth,
                  onToggle: () => setState(() => _expandedGrowth = !_expandedGrowth),
                ),
              ],
              if (widget.report.adviceComment != null) ...[
                const SizedBox(height: 10),
                _ExpandableCommentBlock(
                  emoji: '💡',
                  label: '来月へのアドバイス',
                  text: widget.report.adviceComment!,
                  isExpanded: _expandedAdvice,
                  onToggle: () => setState(() => _expandedAdvice = !_expandedAdvice),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpandableCommentBlock extends StatelessWidget {
  final String emoji;
  final String label;
  final String text;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _ExpandableCommentBlock({
    required this.emoji,
    required this.label,
    required this.text,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onToggle,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Text(emoji),
                const SizedBox(width: 6),
                Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _primaryColor)),
              ]),
              Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                size: 20,
                color: _textSecondary,
              ),
            ],
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(left: 20, top: 8),
            child: Text(text, style: const TextStyle(fontSize: 14, color: _textPrimary, height: 1.5)),
          ),
          crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
      ],
    );
  }
}

class _CommentBlock extends StatelessWidget {
  final String emoji;
  final String label;
  final String text;
  const _CommentBlock({required this.emoji, required this.label, required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(emoji),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _primaryColor)),
        ]),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Text(text, style: const TextStyle(fontSize: 14, color: _textPrimary, height: 1.5)),
        ),
      ],
    );
  }
}

class _ReportRadarCard extends ConsumerStatefulWidget {
  final MonthlyReport report;
  final MonthlyReport? previousReport;
  const _ReportRadarCard({required this.report, this.previousReport});

  @override
  ConsumerState<_ReportRadarCard> createState() => _ReportRadarCardState();
}

class _ReportRadarCardState extends ConsumerState<_ReportRadarCard>
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
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('🌈 徳目バランス',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textPrimary)),
                  if (widget.previousReport != null)
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _primaryColor.withAlpha(50),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text('今月', style: TextStyle(fontSize: 10, color: _textSecondary)),
                        const SizedBox(width: 12),
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.grey.withAlpha(50),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text('先月', style: TextStyle(fontSize: 10, color: _textSecondary)),
                      ],
                    ),
                ],
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
                          RadarEntry(value: widget.report.kindnessScore),
                          RadarEntry(value: widget.report.honestyScore),
                          RadarEntry(value: widget.report.responsibilityScore),
                          RadarEntry(value: widget.report.courageScore),
                          RadarEntry(value: widget.report.respectScore),
                          RadarEntry(value: widget.report.cooperationScore),
                        ],
                      ),
                      if (widget.previousReport != null)
                        RadarDataSet(
                          fillColor: Colors.grey.withAlpha(30),
                          borderColor: Colors.grey.withAlpha(200),
                          borderWidth: 2,
                          entryRadius: 3,
                          dataEntries: [
                            RadarEntry(value: widget.previousReport!.kindnessScore),
                            RadarEntry(value: widget.previousReport!.honestyScore),
                            RadarEntry(value: widget.previousReport!.responsibilityScore),
                            RadarEntry(value: widget.previousReport!.courageScore),
                            RadarEntry(value: widget.previousReport!.respectScore),
                            RadarEntry(value: widget.previousReport!.cooperationScore),
                          ],
                        ),
                    ],
                    // radarMaxValue removed (not in fl_chart 0.68.0)
                    tickCount: 4,
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

/// Badge section for report screen
class _BadgeSectionForReport extends ConsumerWidget {
  final String childId;
  const _BadgeSectionForReport({required this.childId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earnedBadgesAsync = ref.watch(earnedBadgesProvider(childId));
    final badgeCompletionRateAsync = ref.watch(badgeCompletionRateProvider(childId));
    final badgeProgressAsync = ref.watch(badgeProgressProvider(childId));

    return earnedBadgesAsync.when(
      data: (earnedBadges) => badgeCompletionRateAsync.when(
        data: (completionRate) => badgeProgressAsync.when(
          data: (badgeProgress) => _BadgeCard(
            earnedBadges: earnedBadges,
            completionRate: completionRate,
            badgeProgress: badgeProgress,
          ),
          loading: () => const _BadgeCardSkeleton(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        loading: () => const _BadgeCardSkeleton(),
        error: (_, __) => const SizedBox.shrink(),
      ),
      loading: () => const _BadgeCardSkeleton(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Badge display card with progress and earned badges
class _BadgeCard extends StatefulWidget {
  final List<EarnedBadge> earnedBadges;
  final double completionRate;
  final Map<String, double> badgeProgress;

  const _BadgeCard({
    required this.earnedBadges,
    required this.completionRate,
    required this.badgeProgress,
  });

  @override
  State<_BadgeCard> createState() => _BadgeCardState();
}

class _BadgeCardState extends State<_BadgeCard> with SingleTickerProviderStateMixin {
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
    final earnedCount = widget.earnedBadges.length;
    final totalCount = kDoutokuBadges.length;

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
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('🏆 バッジ進捗',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textPrimary)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _primaryColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$earnedCount/$totalCount',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: widget.completionRate,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.completionRate < 0.3
                        ? Colors.orange
                        : widget.completionRate < 0.7
                            ? _primaryColor
                            : Colors.green,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Earned badges display
              if (widget.earnedBadges.isNotEmpty) ...[
                const Text(
                  '獲得済みバッジ',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _textSecondary),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.earnedBadges.take(6).map((badge) {
                    final definition = findBadge(badge.badgeId);
                    return definition != null
                        ? Tooltip(
                            message: definition.name,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.amber.withAlpha(20),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.amber.withAlpha(100)),
                              ),
                              child: Text(
                                definition.emoji,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          )
                        : const SizedBox.shrink();
                  }).toList(),
                ),
                if (widget.earnedBadges.length > 6) ...[
                  const SizedBox(height: 4),
                  Text(
                    '+${widget.earnedBadges.length - 6} more',
                    style: const TextStyle(fontSize: 11, color: _textSecondary),
                  ),
                ],
              ] else
                const Text(
                  'まだバッジを獲得していません',
                  style: TextStyle(fontSize: 12, color: _textSecondary),
                ),
              const SizedBox(height: 12),
              // Next badge hint
              _NextBadgeHint(badgeProgress: widget.badgeProgress),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton loader for badge card
class _BadgeCardSkeleton extends StatelessWidget {
  const _BadgeCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 20,
            width: 100,
            color: Colors.grey.shade200,
          ),
          const SizedBox(height: 12),
          Container(
            height: 8,
            color: Colors.grey.shade200,
          ),
        ],
      ),
    );
  }
}

/// Next badge hint widget
class _NextBadgeHint extends StatelessWidget {
  final Map<String, double> badgeProgress;

  const _NextBadgeHint({required this.badgeProgress});

  @override
  Widget build(BuildContext context) {
    // Find the badge closest to completion that hasn't been earned yet
    String? nextBadgeId;
    double maxProgress = 0;

    for (final entry in badgeProgress.entries) {
      if (entry.value < 1.0 && entry.value > maxProgress) {
        nextBadgeId = entry.key;
        maxProgress = entry.value;
      }
    }

    if (nextBadgeId == null) {
      return const Text(
        'すべてのバッジを獲得しました！',
        style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600),
      );
    }

    final badge = findBadge(nextBadgeId);
    if (badge == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '次のバッジ',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _textSecondary),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(badge.emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    badge.name,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _textPrimary),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: maxProgress,
                      minHeight: 4,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(_primaryColor.withAlpha(150)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(maxProgress * 100).toInt()}%',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _primaryColor),
            ),
          ],
        ),
      ],
    );
  }
}

/// Growth comparison between current and previous month
class _GrowthComparisonCard extends StatefulWidget {
  final MonthlyReport current;
  final MonthlyReport previous;
  const _GrowthComparisonCard({required this.current, required this.previous});

  @override
  State<_GrowthComparisonCard> createState() => _GrowthComparisonCardState();
}

class _GrowthComparisonCardState extends State<_GrowthComparisonCard>
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

  double _getScoreDiff(String virtue) {
    final currentScore = _getCurrentScore(virtue);
    final previousScore = _getPreviousScore(virtue);
    return currentScore - previousScore;
  }

  double _getCurrentScore(String virtue) {
    switch (virtue) {
      case 'kindness':
        return widget.current.kindnessScore;
      case 'honesty':
        return widget.current.honestyScore;
      case 'responsibility':
        return widget.current.responsibilityScore;
      case 'courage':
        return widget.current.courageScore;
      case 'respect':
        return widget.current.respectScore;
      case 'cooperation':
        return widget.current.cooperationScore;
      default:
        return 50.0;
    }
  }

  double _getPreviousScore(String virtue) {
    switch (virtue) {
      case 'kindness':
        return widget.previous.kindnessScore;
      case 'honesty':
        return widget.previous.honestyScore;
      case 'responsibility':
        return widget.previous.responsibilityScore;
      case 'courage':
        return widget.previous.courageScore;
      case 'respect':
        return widget.previous.respectScore;
      case 'cooperation':
        return widget.previous.cooperationScore;
      default:
        return 50.0;
    }
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
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('📈 先月からの成長',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textPrimary)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _GrowthIndicator(
                    label: '学習時間',
                    current: widget.current.totalStudyMinutes,
                    previous: widget.previous.totalStudyMinutes,
                    unit: '分',
                  ),
                  _GrowthIndicator(
                    label: 'ストーリー',
                    current: widget.current.storiesCompleted,
                    previous: widget.previous.storiesCompleted,
                    unit: '個',
                  ),
                  _GrowthIndicator(
                    label: 'ポイント',
                    current: widget.current.totalPointsEarned,
                    previous: widget.previous.totalPointsEarned,
                    unit: 'pt',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GrowthIndicator extends StatelessWidget {
  final String label;
  final int current;
  final int previous;
  final String unit;

  const _GrowthIndicator({
    required this.label,
    required this.current,
    required this.previous,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final diff = current - previous;
    final isGrowth = diff >= 0;

    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _textSecondary)),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(children: [
            TextSpan(
              text: '$current',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textPrimary),
            ),
            TextSpan(text: unit, style: const TextStyle(fontSize: 12, color: _textSecondary)),
          ]),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isGrowth ? Icons.trending_up : Icons.trending_down,
              size: 14,
              color: isGrowth ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 4),
            Text(
              '${isGrowth ? '+' : ''}$diff',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isGrowth ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Virtue score trends display
class _VirtueScoreTrends extends ConsumerWidget {
  final MonthlyReport report;
  const _VirtueScoreTrends({required this.report});

  double _getVirtueScore(String virtue) {
    switch (virtue) {
      case 'kindness':
        return report.kindnessScore;
      case 'honesty':
        return report.honestyScore;
      case 'responsibility':
        return report.responsibilityScore;
      case 'courage':
        return report.courageScore;
      case 'respect':
        return report.respectScore;
      case 'cooperation':
        return report.cooperationScore;
      default:
        return 50.0;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📊 徳目スコア詳細',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textPrimary)),
          const SizedBox(height: 16),
          ...[
            ('思いやり', 'kindness'),
            ('正直さ', 'honesty'),
            ('責任感', 'responsibility'),
            ('勇気', 'courage'),
            ('礼儀', 'respect'),
            ('協調性', 'cooperation'),
          ].map((virtue) {
            final score = _getVirtueScore(virtue.$2);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ScoreBar(label: virtue.$1, score: score.toInt()),
            );
          }).toList(),
        ],
      ),
    );
  }
}

/// Individual score bar with progress indicator
class _ScoreBar extends StatelessWidget {
  final String label;
  final int score;
  const _ScoreBar({required this.label, required this.score});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textPrimary)),
            Text('$score/100', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _primaryColor)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: score / 100.0,
            minHeight: 6,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              score < 40 ? Colors.red : score < 60 ? Colors.orange : Colors.green,
            ),
          ),
        ),
      ],
    );
  }
}

class _ParentMessageCard extends StatefulWidget {
  final String message;
  const _ParentMessageCard({required this.message});

  @override
  State<_ParentMessageCard> createState() => _ParentMessageCardState();
}

class _ParentMessageCardState extends State<_ParentMessageCard>
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
            color: const Color(0xFFF3E5F5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _primaryColor.withAlpha(80)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(children: [
                Text('💌', style: TextStyle(fontSize: 20)),
                SizedBox(width: 8),
                Text('保護者の方へ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _primaryColor)),
              ]),
              const SizedBox(height: 12),
              Text(widget.message, style: const TextStyle(fontSize: 14, color: _textPrimary, height: 1.6)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyReportCard extends ConsumerWidget {
  final int year;
  final int month;
  final String childId;
  const _EmptyReportCard({required this.year, required this.month, required this.childId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const Text('📋', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text('$year年$month月のレポートはまだありません',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textPrimary),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text('ストーリーを学習するとレポートが生成されます',
              style: TextStyle(fontSize: 13, color: _textSecondary), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              final key = (childId: childId, year: year, month: month);
              ref.invalidate(monthlyReportProvider(key));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('レポートを確認する'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              final key = (childId: childId, year: year, month: month);
              ref.invalidate(generateMonthlyReportProvider(key));
              ref.read(generateMonthlyReportProvider(key));
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: _primaryColor,
              side: const BorderSide(color: _primaryColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('AIレポートを生成する'),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String error;
  const _ErrorCard({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFDEDEC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE74C3C).withAlpha(80)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFE74C3C)),
          const SizedBox(width: 12),
          Expanded(child: Text(error, style: const TextStyle(color: Color(0xFFE74C3C)))),
        ],
      ),
    );
  }
}
