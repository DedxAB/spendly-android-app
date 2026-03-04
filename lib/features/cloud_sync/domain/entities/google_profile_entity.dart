class GoogleProfileEntity {
  const GoogleProfileEntity({
    required this.email,
    this.displayName,
    this.photoUrl,
  });

  final String email;
  final String? displayName;
  final String? photoUrl;
}
