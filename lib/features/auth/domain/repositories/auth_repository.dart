import '../entities/user.dart';

abstract class AuthRepository {
  /// Signs in and securely stores the tokens. Throws a `Failure`.
  Future<User> login(String username, String password);

  /// Returns the signed-in user when a valid session exists, otherwise null.
  Future<User?> restoreSession();

  /// Fetches the authenticated user's profile from the server.
  Future<User> getCurrentUser();

  /// Clears the stored session.
  Future<void> logout();
}
