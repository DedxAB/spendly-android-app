class MonthlyReflectionEntity {
  const MonthlyReflectionEntity({
    required this.monthKey,
    required this.note,
    required this.updatedAt,
  });

  final String monthKey;
  final String note;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'monthKey': monthKey,
      'note': note,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MonthlyReflectionEntity.fromJson(Map<String, dynamic> json) {
    return MonthlyReflectionEntity(
      monthKey: json['monthKey'] as String,
      note: json['note'] as String,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
