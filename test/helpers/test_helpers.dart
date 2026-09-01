import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'dart:io';

/// Fake PathProvider implementation for testing
class FakePathProvider
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getTemporaryPath() async =>
      Directory.systemTemp.path;

  @override
  Future<String?> getApplicationSupportPath() async =>
      Directory.systemTemp.path;

  @override
  Future<String?> getApplicationDocumentsPath() async =>
      Directory.systemTemp.path;

  @override
  Future<String?> getLibraryPath() async => null;

  @override
  Future<String?> getExternalStoragePath() async => null;

  @override
  Future<List<String>?> getExternalCachePaths() async => null;

  @override
  Future<List<String>?> getExternalStoragePaths({
    StorageDirectory? type,
  }) async => null;

  @override
  Future<String?> getDownloadsPath() async => null;

  @override
  Future<String?> getApplicationCachePath() async =>
      Directory.systemTemp.path;
}

/// Test utilities for common test operations
class TestUtils {
  /// Create a temporary directory for testing
  static Future<Directory> createTempTestDir(String prefix) async {
    return Directory.systemTemp.createTemp(prefix);
  }

  /// Clean up a test directory
  static Future<void> cleanupTestDir(Directory dir) async {
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
  }

  /// Create a temporary test file
  static Future<File> createTempTestFile(
    Directory dir,
    String filename,
    String content,
  ) async {
    final file = File('${dir.path}/$filename');
    await file.create(recursive: true);
    await file.writeAsString(content);
    return file;
  }

  /// Wait for a condition with timeout
  static Future<void> waitFor(
    Future<bool> Function() condition, {
    Duration timeout = const Duration(seconds: 5),
    Duration checkInterval = const Duration(milliseconds: 100),
  }) async {
    final stopwatch = Stopwatch()..start();

    while (!await condition()) {
      if (stopwatch.elapsed > timeout) {
        throw TimeoutException('Condition not met within timeout');
      }
      await Future.delayed(checkInterval);
    }
  }

  /// Assert that a future throws an exception of a specific type
  static Future<void> expectAsync(
    Future Function() fn,
    Type exceptionType, {
    String? reason,
  }) async {
    bool threw = false;
    try {
      await fn();
    } catch (e) {
      if (e.runtimeType == exceptionType) {
        threw = true;
      } else {
        rethrow;
      }
    }

    if (!threw) {
      throw AssertionError(
        'Expected exception of type $exceptionType but no exception was thrown. ${reason ?? ''}',
      );
    }
  }
}

/// Test data generators
class TestDataGenerator {
  static String generateId(String prefix) => '$prefix-${DateTime.now().millisecondsSinceEpoch}';

  static String generateEmail() => 'test-${generateId('user')}@example.com';

  static String generateStoryId() => 'story-${DateTime.now().millisecondsSinceEpoch}';

  static String generateChildId() => 'child-${DateTime.now().millisecondsSinceEpoch}';

  static String generateSessionId() => 'session-${DateTime.now().millisecondsSinceEpoch}';
}

/// TimeoutException for test utilities
class TimeoutException implements Exception {
  final String message;

  TimeoutException(this.message);

  @override
  String toString() => 'TimeoutException: $message';
}
