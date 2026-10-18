import 'package:equatable/equatable.dart';

class User extends Equatable {
  const User({
    required this.id,
    required this.username,
    this.firstName = '',
    this.lastName = '',
    this.email,
    this.phone,
    this.imageUrl,
  });

  final int id;
  final String username;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;
  final String? imageUrl;

  String get fullName {
    final name = '$firstName $lastName'.trim();
    return name.isEmpty ? username : name;
  }

  @override
  List<Object?> get props =>
      [id, username, firstName, lastName, email, phone, imageUrl];
}
