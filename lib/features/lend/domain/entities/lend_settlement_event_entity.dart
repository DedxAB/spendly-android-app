class LendSettlementEventEntity {
  const LendSettlementEventEntity({
    required this.id,
    required this.entryId,
    required this.personId,
    required this.amount,
    required this.date,
    required this.createdAt,
    this.isDeleted = false,
  });

  final String id;
  final String entryId;
  final String personId;
  final double amount;
  final DateTime date;
  final DateTime createdAt;
  final bool isDeleted;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entryId': entryId,
      'personId': personId,
      'amount': amount,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'isDeleted': isDeleted,
    };
  }

  factory LendSettlementEventEntity.fromJson(Map<String, dynamic> json) {
    return LendSettlementEventEntity(
      id: json['id'] as String,
      entryId: json['entryId'] as String,
      personId: json['personId'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }
}
