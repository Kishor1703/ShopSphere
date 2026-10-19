import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shopsphere/core/error/failure.dart';
import 'package:shopsphere/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:shopsphere/features/auth/data/models/user_model.dart';
import 'package:shopsphere/features/auth/data/repositories/auth_repository_impl.dart';

import '../../helpers/factories.dart';
import '../../helpers/fixture_reader.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

void main() {
  late MockAuthRemoteDataSource remote;
  late InMemoryTokenStorage tokens;
  late AuthRepositoryImpl repository;

  final user = UserModel.fromJson(fixtureJson('login_response.json'));

  setUp(() {
    remote = MockAuthRemoteDataSource();
    tokens = InMemoryTokenStorage();
    repository = AuthRepositoryImpl(remote: remote, tokens: tokens);
  });

  Matcher failureOfType(FailureType type) =>
      throwsA(isA<Failure>().having((f) => f.type, 'type', type));

  group('login', () {
    test('returns the user and stores both tokens', () async {
      when(() => remote.login('emilys', 'emilyspass')).thenAnswer(
        (_) async => LoginResult(
          accessToken: 'access-token-value',
          refreshToken: 'refresh-token-value',
          user: user,
        ),
      );

      final result = await repository.login('emilys', 'emilyspass');

      expect(result.username, 'emilys');
      expect(tokens.access, 'access-token-value');
      expect(tokens.refresh, 'refresh-token-value');
    });

    test('reports invalid credentials on a 400 and stores nothing', () async {
      when(() => remote.login(any(), any())).thenThrow(statusError(400));

      await expectLater(
        repository.login('emilys', 'wrong'),
        failureOfType(FailureType.invalidCredentials),
      );
      expect(tokens.access, isNull);
    });

    test('reports a network failure when offline', () async {
      when(() => remote.login(any(), any())).thenThrow(connectionError());

      await expectLater(
        repository.login('emilys', 'emilyspass'),
        failureOfType(FailureType.network),
      );
    });
  });

  group('restoreSession', () {
    test('returns null without calling the server when no tokens exist', () async {
      final result = await repository.restoreSession();

      expect(result, isNull);
      verifyNever(() => remote.getMe());
    });

    test('returns the user when stored tokens are valid', () async {
      tokens
        ..access = 'a'
        ..refresh = 'r';
      when(() => remote.getMe()).thenAnswer((_) async => user);

      expect(await repository.restoreSession(), user);
    });

    test('clears tokens and returns null when the session is rejected', () async {
      tokens
        ..access = 'a'
        ..refresh = 'r';
      when(() => remote.getMe()).thenThrow(statusError(401));

      expect(await repository.restoreSession(), isNull);
      expect(tokens.access, isNull);
      expect(tokens.refresh, isNull);
    });

    test('keeps tokens and reports the failure when offline', () async {
      tokens
        ..access = 'a'
        ..refresh = 'r';
      when(() => remote.getMe()).thenThrow(connectionError());

      await expectLater(
        repository.restoreSession(),
        failureOfType(FailureType.network),
      );
      expect(tokens.access, 'a');
    });
  });

  test('logout clears stored tokens', () async {
    tokens
      ..access = 'a'
      ..refresh = 'r';

    await repository.logout();

    expect(tokens.access, isNull);
    expect(tokens.refresh, isNull);
  });
}
