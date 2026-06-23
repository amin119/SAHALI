class UserModel {
  final String id;
  final String fullName;
  final String? email;
  final String? phone;
  final String role;
  final String preferredLanguage;
  final bool isActive;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.fullName,
    this.email,
    this.phone,
    required this.role,
    required this.preferredLanguage,
    required this.isActive,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        id: j['id'] as String,
        fullName: j['full_name'] as String,
        email: j['email'] as String?,
        phone: j['phone'] as String?,
        role: j['role'] as String,
        preferredLanguage: (j['preferred_language'] as String?) ?? 'fr',
        isActive: (j['is_active'] as bool?) ?? true,
        createdAt: DateTime.parse(j['created_at'] as String),
      );

  bool get isCitizen => role == 'citizen';
}
