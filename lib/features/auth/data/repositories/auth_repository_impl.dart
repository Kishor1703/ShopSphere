import 'package:dio/dio.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required TokenStorage tokens,
  })  : _remote = remote,
        _tokens = tokens;

  final AuthRemoteDataSource _remote;
  final TokenStorage _tokens;

  @override
  Future<User> login(String username, String password) async {
    try {
      final result = await _remote.login(username, password);
      await _tokens.save(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
      );
      return result.user;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 400 || status == 401) {
        throw const Failure(
          FailureType.invalidCredentials,
          'Invalid username or password.',
        );
      }
      throw mapError(e);
    } catch (e) {
      throw mapError(e);
    }
  }

  @override
  Future<User?> restoreSession() async {
    try {
      final access = await _tokens.readAccessToken();
      final refresh = await _tokens.readRefreshToken();
      if (access == null && refresh == null) return null;
      return await _remote.getMe();
    } catch (e) {
      final failure = mapError(e);
      if (failure.type == FailureType.unauthorized) {
        await _tokens.clear();
        return null;
      }
      throw failure;
    }
  }

  @override
  Future<User> getCurrentUser() async {
    try {
      return await _remote.getMe();
    } catch (e) {
      throw mapError(e);
    }
  }

  @override
  Future<void> logout() => _tokens.clear();
}
