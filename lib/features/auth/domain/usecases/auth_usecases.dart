import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  const LoginUseCase(this._repository);
  final AuthRepository _repository;

  Future<User> call(String username, String password) =>
      _repository.login(username, password);
}

class RestoreSessionUseCase {
  const RestoreSessionUseCase(this._repository);
  final AuthRepository _repository;

  Future<User?> call() => _repository.restoreSession();
}

class GetCurrentUserUseCase {
  const GetCurrentUserUseCase(this._repository);
  final AuthRepository _repository;

  Future<User> call() => _repository.getCurrentUser();
}

class LogoutUseCase {
  const LogoutUseCase(this._repository);
  final AuthRepository _repository;

  Future<void> call() => _repository.logout();
}
