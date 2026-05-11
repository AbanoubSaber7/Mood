class MoodHistoryEntry {
  final String emotion;
  final double? confidencePercent;
  final DateTime timestamp;
  final String source; // e.g. "model" | "manual"
  final String? predictedEmotion; // if user corrected a low-confidence prediction

  const MoodHistoryEntry({
    required this.emotion,
    required this.timestamp,
    required this.source,
    this.confidencePercent,
    this.predictedEmotion,
  });

  Map<String, dynamic> toJson() => {
        'emotion': emotion,
        'confidencePercent': confidencePercent,
        'timestamp': timestamp.toIso8601String(),
        'source': source,
        'predictedEmotion': predictedEmotion,
      };

  static MoodHistoryEntry fromJson(Map<String, dynamic> json) {
    final ts = json['timestamp'];
    return MoodHistoryEntry(
      emotion: (json['emotion'] ?? 'Neutral') as String,
      confidencePercent: (json['confidencePercent'] as num?)?.toDouble(),
      timestamp: ts is String ? DateTime.tryParse(ts) ?? DateTime.now() : DateTime.now(),
      source: (json['source'] ?? 'unknown') as String,
      predictedEmotion: json['predictedEmotion'] as String?,
    );
  }
}

