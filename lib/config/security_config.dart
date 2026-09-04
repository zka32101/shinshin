/// Security configuration for sensitive data protection.
/// This file contains utilities and documentation for enabling encryption at rest.

import 'package:hive_flutter/hive_flutter.dart';

/// Security configuration constants
class SecurityConfig {
  /// COPPA Compliance Checklist
  /// Child data must be minimized and encrypted at rest.
  ///
  /// Implemented:
  /// ✓ Minimal child data collection (name, grade, avatar only)
  /// ✓ Input validation and sanitization
  /// ✓ Cache TTL/expiry for temporary data
  /// ✓ Parent authentication required
  ///
  /// TODO - Before Production Release:
  /// [ ] Enable Hive encryption for sensitive boxes
  /// [ ] Implement COPPA data deletion endpoint
  /// [ ] Validate Firebase Firestore rules enforce parent/child isolation
  /// [ ] Add end-to-end error logging without PII leakage
  /// [ ] Configure CORS and security headers on FastAPI backend
  /// [ ] Rate limit authentication endpoints
  /// [ ] Review Firebase security rules in Firebase Console

  /// How to enable Hive encryption (production setup):
  ///
  /// 1. Add to pubspec.yaml:
  ///    dependencies:
  ///      hive_flutter: ^1.1.0
  ///      pointycastle: ^3.6.0
  ///
  /// 2. Generate encryption key (run once, store securely):
  ///    ```dart
  ///    import 'dart:typed_data';
  ///    import 'package:pointycastle/export.dart';
  ///
  ///    final key = List<int>.from(SecureRandom(32).nextBytes(32));
  ///    print('Encryption key (base64): ${base64.encode(key)}');
  ///    // Store in:
  ///    // - iOS: Keychain via flutter_secure_storage
  ///    // - Android: KeyStore via flutter_secure_storage
  ///    // - Web: IndexedDB with encryption (avoid localStorage)
  ///    ```
  ///
  /// 3. Load key in HiveService.initialize():
  ///    ```dart
  ///    final secureStorage = FlutterSecureStorage();
  ///    final keyString = await secureStorage.read(key: 'hive_encryption_key');
  ///    final key = base64.decode(keyString!);
  ///    final cipher = HiveAesCipher(key);
  ///
  ///    // Open encrypted boxes:
  ///    _storiesBoxInstance = await Hive.openBox<String>(
  ///      storiesBox,
  ///      encryptionCipher: cipher,
  ///    );
  ///    ```
  ///
  /// 4. Update tearDown in tests:
  ///    ```dart
  ///    tearDown(() async {
  ///      await Hive.close();
  ///      if (testDir.existsSync()) testDir.deleteSync(recursive: true);
  ///    });
  ///    ```

  /// Sensitive data boxes that should be encrypted:
  static const List<String> encryptedBoxes = [
    'user', // User authentication tokens
    'reports', // Child progress reports
    'progress', // Child learning progress
    'pending_sync', // Offline queue with child data
  ];

  /// Non-sensitive boxes (optional encryption, faster reads):
  static const List<String> unencryptedBoxes = [
    'stories', // Public story content
    'settings', // User preferences
  ];

  /// Child data retention policy
  ///
  /// COPPA requires that child data be deleted upon request.
  /// Implement the following data retention and deletion rules:
  ///
  /// - Progress: Delete after 12 months of inactivity
  /// - Reports: Delete after 24 months (keep 2 years for parent reference)
  /// - Reflection Text: Delete immediately after API sync (3 months if offline)
  /// - Pending Sync Queue: Delete after successful sync
  ///
  /// Deletion Endpoint: DELETE /parent/{parentId}/child/{childId}
  /// - Cascades to all child data
  /// - Logs deletion without storing child PII
  /// - Returns success confirmation
}

/// Example: Parent deletion request handler (implement in FastAPI backend)
///
/// ```python
/// @router.delete("/parent/{parent_id}/child/{child_id}")
/// async def delete_child(parent_id: str, child_id: str, current_user: User = Depends(get_current_parent)):
///     # Verify parent owns this child
///     child = db.query(Child).filter(
///         Child.id == child_id,
///         Child.parent_id == current_user.id
///     ).first()
///
///     if not child:
///         raise HTTPException(status_code=404, detail="Child not found")
///
///     # Delete all child data
///     db.query(Progress).filter(Progress.child_id == child_id).delete()
///     db.query(MonthlyReport).filter(MonthlyReport.child_id == child_id).delete()
///     db.query(Child).filter(Child.id == child_id).delete()
///     db.commit()
///
///     # Log deletion without storing PII
///     logger.info(f"Child deleted: {hash(child_id)}", extra={"action": "coppa_deletion"})
///
///     return {"status": "success", "message": "Child data deleted"}
/// ```
