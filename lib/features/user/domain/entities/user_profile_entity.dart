class UserProfileEntity {
  const UserProfileEntity({
    this.id = 1,
    required this.name,
    this.imageUrl,
    this.email,
    this.phone,
    this.onboardingCompleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String name;
  final String? imageUrl;
  final String? email;
  final String? phone;
  final bool onboardingCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfileEntity copyWith({
    int? id,
    String? name,
    String? imageUrl,
    String? email,
    String? phone,
    bool? onboardingCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfileEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'email': email,
      'phone': phone,
      'onboardingCompleted': onboardingCompleted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserProfileEntity.fromJson(Map<String, dynamic> json) {
    return UserProfileEntity(
      id: json['id'] as int? ?? 1,
      name: json['name'] as String? ?? 'User',
      imageUrl: json['imageUrl'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
      createdAt: json['createdAt'] == null
          ? DateTime.now()
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? DateTime.now()
          : DateTime.parse(json['updatedAt'] as String),
    );
  }
}
