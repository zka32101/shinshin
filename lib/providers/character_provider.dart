import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart';

// ─── Phase 4.1: CharacterProfile統合版 ────────────────────────────────────

/// 道徳コレ！キャラクター管理（Phase 4.1: CharacterProfile対応）
class CharacterNotifier extends BaseCharacterProfileNotifier {
  @override
  List<BaseCharacter> get characterList => []; // 道徳ではキャラ使用なし

  @override
  String get storageKey => 'shinshin_character_profiles';

  @override
  Subject get appSubject => Subject.doutoku;
}

/// 統一キャラクタープロバイダー（Phase 4.1）
final characterProvider = NotifierProvider<CharacterNotifier, CharacterProfileMap>(
  CharacterNotifier.new,
);
