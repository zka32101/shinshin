import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/mission_provider.dart';

class MissionCard extends ConsumerWidget {
  final MissionData mission;
  const MissionCard({super.key, required this.mission});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(mission.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: mission.progress / mission.target),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('${mission.progress}/${mission.target}'),
              Text('+${mission.reward} coins', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
            ]),
          ],
        ),
      ),
    );
  }
}
