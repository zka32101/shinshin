import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

/// ピアノ学習画面
/// 鍵盤をタッチして音を学ぶ
class PianoLearningScreen extends StatefulWidget {
  const PianoLearningScreen({super.key});

  @override
  State<PianoLearningScreen> createState() => _PianoLearningScreenState();
}

class _PianoLearningScreenState extends State<PianoLearningScreen> {
  late AudioPlayer _audioPlayer;
  String? _currentNote;

  // ド〜ド（1オクターブ）
  final List<Map<String, dynamic>> _notes = [
    {'name': 'ド', 'frequency': 261.63, 'color': Colors.white},
    {'name': 'レ', 'frequency': 293.66, 'color': Colors.white},
    {'name': 'ミ', 'frequency': 329.63, 'color': Colors.white},
    {'name': 'ファ', 'frequency': 349.23, 'color': Colors.white},
    {'name': 'ソ', 'frequency': 392.00, 'color': Colors.white},
    {'name': 'ラ', 'frequency': 440.00, 'color': Colors.white},
    {'name': 'シ', 'frequency': 493.88, 'color': Colors.white},
    {'name': 'ド', 'frequency': 523.25, 'color': Colors.white},
  ];

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  /// 周波数の音を生成して再生（仮実装）
  Future<void> _playNote(String noteName) async {
    setState(() => _currentNote = noteName);

    // 実装注：実際の音声生成にはより高度なオーディオライブラリが必要です
    // 一時的にシンプルなトーン再生を実装

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _currentNote = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎹 ピアノレッスン'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2C2C2C),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'ピアノの鍵盤をタッチしよう',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C2C2C),
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (_currentNote != null)
                    Text(
                      _currentNote!,
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF9B59B6),
                      ),
                    )
                  else
                    const Text(
                      '?',
                      style: TextStyle(
                        fontSize: 48,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ),
          ),
          // ピアノ鍵盤
          Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _notes.map((note) {
                  final isActive = _currentNote == note['name'];
                  return GestureDetector(
                    onTap: () => _playNote(note['name']),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 50,
                      height: 120,
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFF9B59B6)
                            : note['color'],
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          if (isActive)
                            BoxShadow(
                              color: const Color(0xFF9B59B6).withAlpha(128),
                              blurRadius: 8,
                            ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          note['name'],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isActive ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
