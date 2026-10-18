import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.username,
    super.firstName,
    super.lastName,
    super.email,
    super.phone,
    super.imageUrl,
  });

  /// Works for both the `/auth/login` and `/auth/me` payloads.
  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: (json['id'] as num).toInt(),
        username: json['username'] as String? ?? '',
        firstName: json['firstName'] as String? ?? '',
        lastName: json['lastName'] as String? ?? '',
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        imageUrl: json['image'] as String?,
      );
}
