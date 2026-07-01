import 'dart:io';
import 'package:flutter/services.dart';

/// Dart-side wrapper for the native MediaStore save channel.
///
/// Only used on Android — callers must guard with [Platform.isAndroid].
/// On API 29+ the native side inserts via MediaStore.Downloads (proper
/// scoped-storage approach, fixes the zero-MediaStore-record bug confirmed
/// last session). On pre-29 devices the native side falls back to a
/// raw-path write into the public Downloads directory.
///
/// Throws a [StateError] on failure (including any PlatformException from
/// the native side) so callers can let it propagate through
/// AsyncValue.guard() and surface via the existing _showErrorAlert flow.
class MediaStoreSaver {
  static const _channel = MethodChannel('com.worktrackr.worktrackr/media_store');

  /// Returns [Build.VERSION.SDK_INT] from the native side — the only
  /// reliable way to get the actual API level on Android from Dart.
  /// [Platform.operatingSystemVersion] does not expose the SDK int.
  static Future<int> getSdkInt() async {
    assert(Platform.isAndroid, 'MediaStoreSaver is Android-only');
    final result = await _channel.invokeMethod<int>('getSdkInt');
    return result ?? 0;
  }

  /// Saves [bytes] to the public Downloads folder with the given
  /// [displayName] (must already be sanitized — no whitespace) and
  /// [mimeType]. Returns the saved path string on success.
  static Future<String> saveToDownloads({
    required List<int> bytes,
    required String displayName,
    required String mimeType,
  }) async {
    assert(Platform.isAndroid, 'MediaStoreSaver is Android-only');
    try {
      final result = await _channel.invokeMethod<String>('saveToDownloads', {
        'bytes': Uint8List.fromList(bytes),
        'displayName': displayName,
        'mimeType': mimeType,
      });
      if (result == null) {
        throw StateError('MediaStore save returned null path for $displayName');
      }
      return result;
    } on PlatformException catch (e) {
      throw StateError('Failed to save file: ${e.message}');
    }
  }
}
