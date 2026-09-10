import 'package:shougaku_kore_doutoku/providers/child_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'fake_hive_service.dart';

/// `currentChildIdProvider` を固定の [childId] で上書きする Override を返す。
///
/// テストでは FakeHiveService を使用して、Hive I/O を避ける。
Override childIdOverride(String childId) {
  return currentChildIdProvider.overrideWith(
    (ref) {
      final notifier = ChildIdNotifier(hiveService: FakeHiveService());
      notifier.state = childId;
      return notifier;
    },
  );
}
