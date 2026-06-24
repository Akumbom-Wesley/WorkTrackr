/// A check-in payload that has been saved to the local SQLite queue
/// because the device was offline at submission time.
class QueuedCheckin {
  final String id;          // UUID — dedup key sent to backend
  final Map<String, dynamic> payload; // CheckinPayload.toJson() output
  final DateTime queuedAt;

  const QueuedCheckin({
    required this.id,
    required this.payload,
    required this.queuedAt,
  });

  /// Row shape for the `checkin_queue` table. `payload` is JSON-encoded
  /// by the caller before insertion (see CheckinQueue.enqueue).
  Map<String, dynamic> toRow(String payloadJson) => {
        'id': id,
        'payload': payloadJson,
        'queued_at': queuedAt.toUtc().toIso8601String(),
      };

  /// Builds a [QueuedCheckin] from a sqflite row, given the already
  /// JSON-decoded payload map.
  factory QueuedCheckin.fromRow(
    Map<String, dynamic> row,
    Map<String, dynamic> decodedPayload,
  ) => QueuedCheckin(
        id: row['id'] as String,
        payload: decodedPayload,
        queuedAt: DateTime.parse(row['queued_at'] as String),
      );

  /// Shape sent to POST /api/v1/checkins/sync/ — payload with offline_id injected
  Map<String, dynamic> toSyncJson() => {
        ...payload,
        'offline_id': id,
      };
}
