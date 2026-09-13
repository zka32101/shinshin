import 'package:flutter_riverpod/flutter_riverpod.dart';

final missionListProvider = StateNotifierProvider<MissionNotifier, List<MissionData>>((ref) => MissionNotifier());

class MissionNotifier extends StateNotifier<List<MissionData>> {
  MissionNotifier() : super([]) {
    _initializeMissions();
  }

  void _initializeMissions() {
    state = [
      MissionData(id: '1', title: '10問クリア', description: '今日10問以上クリアしよう', reward: 50, progress: 0, target: 10, isCompleted: false),
      MissionData(id: '2', title: 'ストリーク7日', description: '7日連続ログインしよう', reward: 100, progress: 0, target: 7, isCompleted: false),
    ];
  }

  void updateProgress(String missionId, int progress) {
    state = [for (final m in state) if (m.id == missionId) m.copyWith(progress: progress, isCompleted: progress >= m.target) else m];
  }
}

class MissionData {
  final String id, title, description;
  final int reward, progress, target;
  final bool isCompleted;
  MissionData({required this.id, required this.title, required this.description, required this.reward, required this.progress, required this.target, required this.isCompleted});
  MissionData copyWith({int? progress, bool? isCompleted}) => MissionData(id: id, title: title, description: description, reward: reward, progress: progress ?? this.progress, target: target, isCompleted: isCompleted ?? this.isCompleted);
}
