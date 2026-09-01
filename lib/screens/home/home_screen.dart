import 'package:flutter/material.dart';
import '../../widgets/avatar_display_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('小学コレ！道徳'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Avatar panel in header
              const AvatarPanel(
                userName: 'ユーザー',
              ),
              const SizedBox(height: 32),
              // Main content placeholder
              const Center(
                child: Text('v1.1 実装中...'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
