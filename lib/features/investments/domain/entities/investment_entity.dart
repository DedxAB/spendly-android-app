class InvestmentEntity {
  const InvestmentEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.amountInvested,
    this.currentValue,
    required this.investedDate,
    this.note,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
  });

  final String id;
  final String name;
  final String type;
  final double amountInvested;
  final double? currentValue;
  final DateTime investedDate;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'amountInvested': amountInvested,
      'currentValue': currentValue,
      'investedDate': investedDate.toIso8601String(),
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDeleted': isDeleted,
    };
  }

  factory InvestmentEntity.fromJson(Map<String, dynamic> json) {
    return InvestmentEntity(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      amountInvested: (json['amountInvested'] as num).toDouble(),
      currentValue: (json['currentValue'] as num?)?.toDouble(),
      investedDate: DateTime.parse(json['investedDate'] as String),
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }
}
