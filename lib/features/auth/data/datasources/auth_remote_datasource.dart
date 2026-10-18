import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../models/user_model.dart';

class LoginResult {
  const LoginResult({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final UserModel user;
}

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dio);

  final Dio _dio;

  Future<LoginResult> login(String username, String password) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {
        'username': username,
        'password': password,
        'expiresInMins': ApiConfig.tokenLifetimeMins,
      },
    );
    final data = response.data!;
    return LoginResult(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
      user: UserModel.fromJson(data),
    );
  }

  Future<UserModel> getMe() async {
    final response = await _dio.get<Map<String, dynamic>>('/auth/me');
    return UserModel.fromJson(response.data!);
  }
}
