import 'json_fields.dart';

/// User summary returned by login; unrelated profile fields are ignored.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.username,
    this.email,
    this.firstName,
    this.lastName,
    this.gender,
    this.image,
  });

  final int id;
  final String username;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? gender;
  final String? image;

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: requiredField<int>(json, 'id'),
    username: requiredField<String>(json, 'username'),
    email: optionalField<String>(json, 'email'),
    firstName: optionalField<String>(json, 'firstName'),
    lastName: optionalField<String>(json, 'lastName'),
    gender: optionalField<String>(json, 'gender'),
    image: optionalField<String>(json, 'image'),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    if (email != null) 'email': email,
    if (firstName != null) 'firstName': firstName,
    if (lastName != null) 'lastName': lastName,
    if (gender != null) 'gender': gender,
    if (image != null) 'image': image,
  };
}
