import 'auth_user.dart';
import 'json_fields.dart';

/// Successful /auth/login response, including its required user summary.
/// Token-only /auth/refresh responses are not login responses.
class AuthResponse {
  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final AuthUser user;

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
    accessToken: requiredField<String>(json, 'accessToken'),
    refreshToken: requiredField<String>(json, 'refreshToken'),
    user: AuthUser.fromJson(json),
  );

  /// DummyJSON puts user fields alongside tokens, not inside a user object.
  Map<String, dynamic> toJson() => {
    ...user.toJson(),
    'accessToken': accessToken,
    'refreshToken': refreshToken,
  };
}
