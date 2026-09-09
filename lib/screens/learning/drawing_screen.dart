import 'package:flutter/material.dart';
import 'package:shared_core/widgets/components/app_card.dart';
import 'package:shared_core/widgets/components/app_button.dart';

/// 絵描き学習画面
/// 自由に描画して創意表現を学ぶ
class DrawingScreen extends StatefulWidget {
  const DrawingScreen({super.key});

  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  late CustomPainter _painter;
  final List<DrawingPoint> _points = [];
  Color _selectedColor = Colors.black;
  double _brushSize = 3.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎨 お絵かき'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2C2C2C),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              setState(() => _points.clear());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // キャンバス
          Expanded(
            child: GestureDetector(
              onPanDown: (details) {
                setState(() {
                  _points.add(DrawingPoint(
                    offset: details.localPosition,
                    color: _selectedColor,
                    size: _brushSize,
                  ));
                });
              },
              onPanUpdate: (details) {
                setState(() {
                  _points.add(DrawingPoint(
                    offset: details.localPosition,
                    color: _selectedColor,
                    size: _brushSize,
                  ));
                });
              },
              child: Container(
                color: Colors.white,
                child: CustomPaint(
                  painter: DrawingPainter(_points),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
          // ツールバー
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFFFAF9FF),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 色選択
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildColorButton(Colors.black),
                    _buildColorButton(Colors.red),
                    _buildColorButton(Colors.blue),
                    _buildColorButton(Colors.green),
                    _buildColorButton(Colors.yellow),
                    _buildColorButton(Colors.purple),
                  ],
                ),
                const SizedBox(height: 16),
                // ペンサイズ調整
                Row(
                  children: [
                    const Icon(Icons.brush),
                    Expanded(
                      child: Slider(
                        value: _brushSize,
                        min: 1.0,
                        max: 20.0,
                        onChanged: (value) {
                          setState(() => _brushSize = value);
                        },
                      ),
                    ),
                    Text('${_brushSize.toInt()}px'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorButton(Color color) {
    final isSelected = _selectedColor == color;
    return GestureDetector(
      onTap: () => setState(() => _selectedColor = color),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey,
            width: isSelected ? 3 : 1,
          ),
        ),
      ),
    );
  }
}

class DrawingPoint {
  final Offset offset;
  final Color color;
  final double size;

  DrawingPoint({
    required this.offset,
    required this.color,
    required this.size,
  });
}

class DrawingPainter extends CustomPainter {
  final List<DrawingPoint> points;

  DrawingPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i].offset != Offset.infinite &&
          points[i + 1].offset != Offset.infinite) {
        canvas.drawLine(
          points[i].offset,
          points[i + 1].offset,
          Paint()
            ..color = points[i].color
            ..strokeWidth = points[i].size
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      }
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) => true;
}
