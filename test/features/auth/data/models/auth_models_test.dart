import 'dart:convert';
import 'dart:io';

import 'package:flutter_application_1/features/auth/data/models/auth_response.dart';
import 'package:flutter_application_1/features/auth/data/models/auth_user.dart';
import 'package:flutter_application_1/features/auth/data/models/login_request.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> fixture(String name) =>
    jsonDecode(File('test/fixtures/auth/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  group('LoginRequest', () {
    test('parses and serializes the request fixture', () {
      final json = fixture('login_request');
      final request = LoginRequest.fromJson(json);
      expect(request.username, 'sample_user');
      expect(request.password, 'sample_password');
      expect(request.expiresInMins, 30);
      expect(request.toJson(), json);
      expect(jsonDecode(jsonEncode(request.toJson())), json);
    });

    test('omits missing and explicitly null expiry', () {
      for (final explicitNull in [false, true]) {
        final json = fixture('login_request')..remove('expiresInMins');
        if (explicitNull) json['expiresInMins'] = null;
        final request = LoginRequest.fromJson(json);
        expect(request.expiresInMins, isNull);
        expect(request.toJson().containsKey('expiresInMins'), isFalse);
      }
    });

    test('rejects missing, null, or incorrectly typed credentials', () {
      for (final key in ['username', 'password']) {
        for (final value in [null, 123, false]) {
          final json = fixture('login_request')..[key] = value;
          expect(() => LoginRequest.fromJson(json), throwsFormatException);
        }
        final json = fixture('login_request')..remove(key);
        expect(() => LoginRequest.fromJson(json), throwsFormatException);
      }
    });

    test('rejects non-integer expiry', () {
      for (final value in ['30', 30.5, true]) {
        final json = fixture('login_request')..['expiresInMins'] = value;
        expect(() => LoginRequest.fromJson(json), throwsFormatException);
      }
    });
  });

  group('AuthResponse', () {
    test(
      'parses all tokens and user fields and preserves the flat JSON shape',
      () {
        final json = fixture('login_response');
        final response = AuthResponse.fromJson(json);
        expect(response.accessToken, 'fixture-access-token');
        expect(response.refreshToken, 'fixture-refresh-token');
        expect(response.user.id, 42);
        expect(response.user.username, 'sample_user');
        expect(response.user.email, 'sample@example.com');
        expect(response.user.firstName, 'Sample');
        expect(response.user.lastName, 'User');
        expect(response.user.gender, 'female');
        expect(response.user.image, 'https://example.com/avatar.png');
        expect(response.toJson(), json);
        expect(response.toJson().containsKey('user'), isFalse);
        expect(jsonDecode(jsonEncode(response.toJson())), json);
      },
    );

    test('accepts missing and null optional user fields', () {
      final minimal = fixture('login_response_minimal');
      for (final explicitNull in [false, true]) {
        final json = Map<String, dynamic>.from(minimal);
        if (explicitNull) {
          for (final key in [
            'email',
            'firstName',
            'lastName',
            'gender',
            'image',
          ]) {
            json[key] = null;
          }
        }
        final response = AuthResponse.fromJson(json);
        expect(response.user.email, isNull);
        expect(response.user.firstName, isNull);
        expect(response.user.lastName, isNull);
        expect(response.user.gender, isNull);
        expect(response.user.image, isNull);
        expect(response.toJson(), minimal);
      }
    });

    test('ignores unknown fields', () {
      final json = fixture('login_response')..['extra'] = {'future': true};
      expect(AuthResponse.fromJson(json).toJson(), fixture('login_response'));
    });

    test('rejects missing, null, and wrong-type required fields', () {
      for (final key in ['accessToken', 'refreshToken', 'id', 'username']) {
        final missing = fixture('login_response')..remove(key);
        expect(() => AuthResponse.fromJson(missing), throwsFormatException);
        for (final value in [null, false, <String>[]]) {
          final json = fixture('login_response')..[key] = value;
          expect(() => AuthResponse.fromJson(json), throwsFormatException);
        }
      }
      final json = fixture('login_response')..['id'] = 42.5;
      expect(() => AuthResponse.fromJson(json), throwsFormatException);
    });

    test('rejects malformed optional user fields', () {
      for (final key in ['email', 'firstName', 'lastName', 'gender', 'image']) {
        final json = fixture('login_response')..[key] = 123;
        expect(() => AuthResponse.fromJson(json), throwsFormatException);
      }
    });

    test('parse errors do not disclose field values', () {
      final json = fixture('login_response')
        ..['accessToken'] = ['secret-token'];
      try {
        AuthResponse.fromJson(json);
        fail('Expected a FormatException');
      } on FormatException catch (error) {
        expect(error.toString(), isNot(contains('secret-token')));
      }
    });
  });

  test('AuthUser independently round-trips its user summary', () {
    final json = fixture('login_response')
      ..remove('accessToken')
      ..remove('refreshToken');
    expect(AuthUser.fromJson(json).toJson(), json);
  });
}
