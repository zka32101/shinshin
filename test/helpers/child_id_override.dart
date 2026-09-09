import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shougaku_kore_doutoku/providers/child_provider.dart';

/// `currentChildIdProvider` を固定の [childId] で上書きする Override を返す。
///
/// `ChildIdNotifier` は永続化処理 (Hive への保存) を持つが、テストでは
/// 単に初期状態を差し替えたいだけなので、生成直後に state をセットする。
Override childIdOverride(String childId) {
  return currentChildIdProvider.overrideWith(
    (ref) => ChildIdNotifier()..state = childId,
  );
}
