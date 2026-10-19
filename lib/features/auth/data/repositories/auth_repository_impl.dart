import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

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
    SharedPreferences? preferences,
  })  : _remote = remote,
        _tokens = tokens,
        _preferences = preferences;

  final AuthRemoteDataSource _remote;
  final TokenStorage _tokens;
  final SharedPreferences? _preferences;

  Future<void> _remember(User user) async {
    try {
      await _preferences?.setString(
          'session_profile',
          jsonEncode({
            'id': user.id,
            'username': user.username,
            'firstName': user.firstName,
            'lastName': user.lastName,
            'email': user.email,
            'phone': user.phone,
            'image': user.imageUrl,
          }));
    } catch (_) {
      // Offline caching is best-effort; authentication still succeeds.
    }
  }

  User? _cachedUser() {
    try {
      final raw = _preferences?.getString('session_profile');
      return raw == null
          ? null
          : UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  bool _offline(Failure failure) =>
      failure.type == FailureType.network ||
      failure.type == FailureType.timeout;

  @override
  Future<User> login(String username, String password) async {
    try {
      final result = await _remote.login(username, password);
      await _tokens.save(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
      );
      await _remember(result.user);
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
      final user = await _remote.getMe();
      await _remember(user);
      return user;
    } catch (e) {
      final failure = mapError(e);
      if (failure.type == FailureType.unauthorized) {
        await _tokens.clear();
        return null;
      }
      final cached = _cachedUser();
      if (_offline(failure) && cached != null) return cached;
      throw failure;
    }
  }

  @override
  Future<User> getCurrentUser() async {
    try {
      final user = await _remote.getMe();
      await _remember(user);
      return user;
    } catch (e) {
      final failure = mapError(e);
      final cached = _cachedUser();
      if (_offline(failure) &&
          cached != null &&
          await _tokens.readAccessToken() != null) {
        return cached;
      }
      throw failure;
    }
  }

  @override
  Future<void> logout() async {
    await _tokens.clear();
    await _preferences?.remove('session_profile');
  }
}
