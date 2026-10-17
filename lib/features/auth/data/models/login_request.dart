import 'json_fields.dart';

/// Payload for POST /auth/login. Null expiry leaves the API default in effect.
class LoginRequest {
  const LoginRequest({
    required this.username,
    required this.password,
    this.expiresInMins,
  });

  final String username;
  final String password;
  final int? expiresInMins;

  factory LoginRequest.fromJson(Map<String, dynamic> json) => LoginRequest(
    username: requiredField<String>(json, 'username'),
    password: requiredField<String>(json, 'password'),
    expiresInMins: optionalField<int>(json, 'expiresInMins'),
  );

  Map<String, dynamic> toJson() => {
    'username': username,
    'password': password,
    if (expiresInMins != null) 'expiresInMins': expiresInMins,
  };
}
