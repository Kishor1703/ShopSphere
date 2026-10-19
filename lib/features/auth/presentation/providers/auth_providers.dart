import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/error_mapper.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/auth_usecases.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => AuthRemoteDataSource(ref.watch(dioProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    remote: ref.watch(authRemoteDataSourceProvider),
    tokens: ref.watch(tokenStorageProvider),
    preferences: ref.watch(sharedPreferencesProvider),
  ),
);

final loginUseCaseProvider =
    Provider((ref) => LoginUseCase(ref.watch(authRepositoryProvider)));
final restoreSessionUseCaseProvider =
    Provider((ref) => RestoreSessionUseCase(ref.watch(authRepositoryProvider)));
final logoutUseCaseProvider =
    Provider((ref) => LogoutUseCase(ref.watch(authRepositoryProvider)));
final getCurrentUserUseCaseProvider =
    Provider((ref) => GetCurrentUserUseCase(ref.watch(authRepositoryProvider)));

enum AuthStatus { unknown, authenticated, unauthenticated, error }

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.isSubmitting = false,
    this.message,
  });

  final AuthStatus status;
  final User? user;
  final bool isSubmitting;
  final String? message;

  AuthState copyWith(
          {bool? isSubmitting, String? message, bool clearMessage = false}) =>
      AuthState(
        status: status,
        user: user,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        message: clearMessage ? null : (message ?? this.message),
      );

  @override
  List<Object?> get props => [status, user, isSubmitting, message];
}

const sessionExpiredMessage = 'Your session expired. Please log in again.';

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    final subscription = ref
        .read(sessionEventsProvider)
        .onExpired
        .listen((_) => _handleExpired());
    ref.onDispose(subscription.cancel);
    Future<void>.microtask(restoreSession);
    return const AuthState();
  }

  Future<void> restoreSession() async {
    state = const AuthState();
    try {
      final user = await ref
          .read(restoreSessionUseCaseProvider)()
          .timeout(const Duration(seconds: 30));
      state = user == null
          ? AuthState(
              status: AuthStatus.unauthenticated, message: state.message)
          : AuthState(status: AuthStatus.authenticated, user: user);
    } catch (error) {
      final failure = mapError(error);
      state = AuthState(status: AuthStatus.error, message: failure.message);
    }
  }

  Future<void> login(String username, String password) async {
    if (state.isSubmitting) return;
    state = state.copyWith(isSubmitting: true, clearMessage: true);
    try {
      final user = await ref.read(loginUseCaseProvider)(username, password);
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } on Failure catch (failure) {
      state = state.copyWith(isSubmitting: false, message: failure.message);
    }
  }

  Future<void> logout() async {
    await ref.read(logoutUseCaseProvider)();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void _handleExpired() {
    if (state.status == AuthStatus.unauthenticated) return;
    state = const AuthState(
      status: AuthStatus.unauthenticated,
      message: sessionExpiredMessage,
    );
  }
}

final authProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

/// The signed-in user's id, or null. Cart and checkout depend on this.
final currentUserIdProvider = Provider<int?>(
  (ref) => ref.watch(authProvider.select((s) => s.user?.id)),
);

final profileProvider = FutureProvider.autoDispose<User>(
  (ref) => ref.watch(getCurrentUserUseCaseProvider)(),
);
