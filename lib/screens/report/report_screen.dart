import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/report_provider.dart';
import '../../providers/child_provider.dart';
import '../../models/report.dart';
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
    final reportAsync = ref.watch(
      monthlyReportProvider((childId: childId, year: _selectedYear, month: _selectedMonth)),
    );

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
                    : _ReportContent(report: report),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MonthSelector extends StatelessWidget {
  final int year;
  final int month;
  final Function(int, int) onChanged;
  const _MonthSelector({required this.year, required this.month, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
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
              final prev = DateTime(year, month - 1);
              onChanged(prev.year, prev.month);
            },
          ),
          Text('$year年 $month月',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textPrimary)),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: DateTime(year, month).isAfter(DateTime.now())
                ? null
                : () {
                    final next = DateTime(year, month + 1);
                    onChanged(next.year, next.month);
                  },
          ),
        ],
      ),
    );
  }
}

class _ReportContent extends StatelessWidget {
  final MonthlyReport report;
  const _ReportContent({required this.report});

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
          delay: const Duration(milliseconds: 300),
          child: _AICommentCard(report: report),
        ),
        const SizedBox(height: 16),
        AnimatedSlideIn(
          direction: SlideDirection.fromBottom,
          duration: AnimationDurations.medium,
          delay: const Duration(milliseconds: 400),
          child: _ReportRadarCard(report: report),
        ),
        const SizedBox(height: 16),
        if (report.parentMessage != null)
          AnimatedSlideIn(
            direction: SlideDirection.fromBottom,
            duration: AnimationDurations.medium,
            delay: const Duration(milliseconds: 500),
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
                _CommentBlock(emoji: '🌟', label: '今月のハイライト', text: widget.report.highlightComment!),
              if (widget.report.growthComment != null) ...[
                const SizedBox(height: 10),
                _CommentBlock(emoji: '📈', label: '成長ポイント', text: widget.report.growthComment!),
              ],
              if (widget.report.adviceComment != null) ...[
                const SizedBox(height: 10),
                _CommentBlock(emoji: '💡', label: '来月へのアドバイス', text: widget.report.adviceComment!),
              ],
            ],
          ),
        ),
      ),
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

class _ReportRadarCard extends StatefulWidget {
  final MonthlyReport report;
  const _ReportRadarCard({required this.report});

  @override
  State<_ReportRadarCard> createState() => _ReportRadarCardState();
}

class _ReportRadarCardState extends State<_ReportRadarCard>
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
              const Text('🌈 徳目バランス',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textPrimary)),
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
