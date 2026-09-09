import 'package:flutter/material.dart';
import 'package:shared_core/widgets/components/app_button.dart';
import 'dart:math';

/// 色選び学習画面
/// 色を学んで認識力を高める
class ColorLearningScreen extends StatefulWidget {
  const ColorLearningScreen({super.key});

  @override
  State<ColorLearningScreen> createState() => _ColorLearningScreenState();
}

class _ColorLearningScreenState extends State<ColorLearningScreen> {
  int _currentMode = 0; // 0: 色学習, 1: 色合わせゲーム
  int _score = 0;
  int _currentQuestion = 0;
  late List<ColorItem> _colors;
  late List<ColorQuestion> _questions;
  late Random _random;

  @override
  void initState() {
    super.initState();
    _random = Random();
    _initializeColors();
    _generateQuestions();
  }

  void _initializeColors() {
    _colors = [
      ColorItem(
        name: '赤',
        color: Colors.red,
        description: '太陽や火のような色です',
      ),
      ColorItem(
        name: '青',
        color: Colors.blue,
        description: '空や海のような色です',
      ),
      ColorItem(
        name: '黄',
        color: Colors.yellow,
        description: 'ひまわりやレモンのような色です',
      ),
      ColorItem(
        name: '緑',
        color: Colors.green,
        description: '木や草のような色です',
      ),
      ColorItem(
        name: '紫',
        color: Colors.purple,
        description: 'ぶどうやアメジストのような色です',
      ),
      ColorItem(
        name: 'ピンク',
        color: Colors.pink,
        description: 'さくらやベリーのような色です',
      ),
      ColorItem(
        name: 'オレンジ',
        color: Colors.orange,
        description: 'みかんやニンジンのような色です',
      ),
      ColorItem(
        name: '茶色',
        color: Colors.brown,
        description: '木や土のような色です',
      ),
    ];
  }

  void _generateQuestions() {
    _questions = [];
    for (int i = 0; i < 5; i++) {
      final correctColor = _colors[_random.nextInt(_colors.length)];
      final options = [correctColor];

      while (options.length < 4) {
        final option = _colors[_random.nextInt(_colors.length)];
        if (!options.any((c) => c.name == option.name)) {
          options.add(option);
        }
      }
      options.shuffle();

      _questions.add(ColorQuestion(
        description: correctColor.description,
        correctAnswer: correctColor,
        options: options,
      ));
    }
  }

  void _answerQuestion(ColorItem selected) {
    if (selected.name == _questions[_currentQuestion].correctAnswer.name) {
      setState(() => _score++);
      _showCorrectDialog();
    } else {
      _showIncorrectDialog();
    }
  }

  void _showCorrectDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⭐ 正解！'),
        content: const Text('よくできました！'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (_currentQuestion < _questions.length - 1) {
                setState(() => _currentQuestion++);
              } else {
                _showResults();
              }
            },
            label: '次へ',
          ),
        ],
      ),
    );
  }

  void _showIncorrectDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('もう一度'),
        content: Text(
          '正解は「${_questions[_currentQuestion].correctAnswer.name}」です',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (_currentQuestion < _questions.length - 1) {
                setState(() => _currentQuestion++);
              } else {
                _showResults();
              }
            },
            label: '次へ',
          ),
        ],
      ),
    );
  }

  void _showResults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ゲーム終了'),
        content: Text('${_score}/5 問正解しました！'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _score = 0;
                _currentQuestion = 0;
                _generateQuestions();
              });
            },
            label: 'もう一度',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎨 色選びの勉強'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2C2C2C),
        elevation: 0,
      ),
      body: _currentMode == 0 ? _buildColorLearning() : _buildColorGame(),
    );
  }

  Widget _buildColorLearning() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: AppButton(
                    onPressed: () => setState(() => _currentMode = 0),
                    ),
                    child: const Text('色学習', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(
                    onPressed: () {
                      setState(() => _currentMode = 1);
                      _generateQuestions();
                    },
                    child: const Text('ゲーム', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: _colors.map((colorItem) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colorItem.color,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey),
                        ),
                      ),
                      title: Text(
                        colorItem.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(colorItem.description),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorGame() {
    if (_questions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final question = _questions[_currentQuestion];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: AppButton(
                  onPressed: () => setState(() => _currentMode = 0),
                  child: const Text('色学習', style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppButton(
                  onPressed: () => setState(() => _currentMode = 1),
                  ),
                  child: const Text('ゲーム', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${_currentQuestion + 1}/5',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF9FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  question.description,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C2C2C),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 48),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: question.options.map((option) {
                    return GestureDetector(
                      onTap: () => _answerQuestion(option),
                      child: Container(
                        decoration: BoxDecoration(
                          color: option.color,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            option.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ColorItem {
  final String name;
  final Color color;
  final String description;

  ColorItem({
    required this.name,
    required this.color,
    required this.description,
  });
}

class ColorQuestion {
  final String description;
  final ColorItem correctAnswer;
  final List<ColorItem> options;

  ColorQuestion({
    required this.description,
    required this.correctAnswer,
    required this.options,
  });
}
