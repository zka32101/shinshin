import 'package:flutter/material.dart';
import 'package:shared_core/widgets/components/app_button.dart';

/// 体育説明学習画面
/// 運動・身体活動について学ぶ
class PhysicalEducationScreen extends StatefulWidget {
  const PhysicalEducationScreen({super.key});

  @override
  State<PhysicalEducationScreen> createState() =>
      _PhysicalEducationScreenState();
}

class _PhysicalEducationScreenState extends State<PhysicalEducationScreen> {
  int _selectedExerciseIndex = 0;

  final List<ExerciseLesson> _exercises = [
    ExerciseLesson(
      name: '走る',
      emoji: '🏃',
      description: '両足を交互に動かして前に進みます。',
      steps: [
        'まっすぐ前を見ます',
        '腕を軽く曲げて振ります',
        'かかとから着地します',
        'リズムよく続けます',
      ],
      benefits: '心臓や肺が強くなります',
      tips: '無理なく続けることが大切です',
    ),
    ExerciseLesson(
      name: 'ジャンプ',
      emoji: '🦘',
      description: '両足で地面を蹴って上に跳びます。',
      steps: [
        'まっすぐ立ちます',
        '足を少し曲げます',
        '力強く地面を蹴ります',
        'ふんわり着地します',
      ],
      benefits: '足の筋肉が強くなります',
      tips: '着地の時は足全体で受け止めます',
    ),
    ExerciseLesson(
      name: 'ストレッチ',
      emoji: '🧘',
      description: '体を伸ばして柔軟性を高めます。',
      steps: [
        'ゆっくり伸ばします',
        '無理をしません',
        '呼吸を止めません',
        '20秒キープします',
      ],
      benefits: '体が柔らかくなり、ケガが減ります',
      tips: '毎日続けることが効果的です',
    ),
    ExerciseLesson(
      name: 'バランス',
      emoji: '🧗',
      description: '一本足で立つなどバランス感覚を鍛えます。',
      steps: [
        'まっすぐ立ちます',
        'もう片足を上げます',
        '腕を広げます',
        'じっと立ちます',
      ],
      benefits: '体のバランス感覚が向上します',
      tips: '目を一点に集中させます',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final exercise = _exercises[_selectedExerciseIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('⛹️ 体育の勉強'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2C2C2C),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 運動選択タブ
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: List.generate(_exercises.length, (index) {
                    final isSelected = index == _selectedExerciseIndex;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedExerciseIndex = index),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF9B59B6)
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_exercises[index].emoji} ${_exercises[index].name}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            // 運動詳細
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // タイトル
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF9FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          exercise.emoji,
                          style: const TextStyle(fontSize: 60),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          exercise.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C2C2C),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          exercise.description,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666666),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // ステップ
                  const Text(
                    'やり方',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C2C2C),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...exercise.steps.asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: Color(0xFF9B59B6),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${entry.key + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF2C2C2C),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                  // 効果
                  _buildInfoCard('效果', exercise.benefits, Colors.green),
                  const SizedBox(height: 12),
                  // ヒント
                  _buildInfoCard('ヒント', exercise.tips, Colors.blue),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String content, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        border: Border.all(color: color.withAlpha(128)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF2C2C2C),
            ),
          ),
        ],
      ),
    );
  }
}

class ExerciseLesson {
  final String name;
  final String emoji;
  final String description;
  final List<String> steps;
  final String benefits;
  final String tips;

  ExerciseLesson({
    required this.name,
    required this.emoji,
    required this.description,
    required this.steps,
    required this.benefits,
    required this.tips,
  });
}
