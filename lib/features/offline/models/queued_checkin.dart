/// A check-in payload that has been saved to the local Hive queue
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

  Map<String, dynamic> toHive() => {
        'id': id,
        'payload': payload,
        'queuedAt': queuedAt.toUtc().toIso8601String(),
      };

  factory QueuedCheckin.fromHive(Map<dynamic, dynamic> map) => QueuedCheckin(
        id: map['id'] as String,
        payload: Map<String, dynamic>.from(map['payload'] as Map),
        queuedAt: DateTime.parse(map['queuedAt'] as String),
      );

  /// Shape sent to POST /api/v1/checkins/sync/ — payload with offline_id injected
  Map<String, dynamic> toSyncJson() => {
        ...payload,
        'offline_id': id,
      };
}
