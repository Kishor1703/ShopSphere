import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopsphere/core/network/api_client.dart';
import '../helpers/factories.dart';

class TestAdapter implements HttpClientAdapter {
  TestAdapter(this.reply);
  final Future<ResponseBody> Function(RequestOptions) reply;
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream,
          Future<void>? cancel) =>
      reply(options);
  @override
  void close({bool force = false}) {}
}

ResponseBody response(int status, [Map<String, dynamic> data = const {}]) =>
    ResponseBody.fromString(
      jsonEncode(data),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType]
      },
    );

void main() {
  late Dio dio;
  late Dio refresh;
  late InMemoryTokenStorage tokens;
  var expired = 0;
  setUp(() {
    expired = 0;
    tokens = InMemoryTokenStorage()
      ..access = 'old'
      ..refresh = 'refresh';
    dio = Dio(BaseOptions(baseUrl: 'https://dummyjson.com'));
    refresh = Dio(BaseOptions(baseUrl: 'https://dummyjson.com'));
    dio.interceptors.add(AuthInterceptor(
        dio: dio,
        refreshDio: refresh,
        tokens: tokens,
        onSessionExpired: () => expired++));
  });
  tearDown(() {
    dio.close();
    refresh.close();
  });

  test('concurrent 401s share a refresh and retry with new tokens', () async {
    var refreshes = 0;
    final entered = Completer<void>();
    final gate = Completer<void>();
    refresh.httpClientAdapter = TestAdapter((options) async {
      refreshes++;
      expect(options.path, '/auth/refresh');
      expect(options.data['refreshToken'], 'refresh');
      entered.complete();
      await gate.future;
      return response(200, {'accessToken': 'new', 'refreshToken': 'next'});
    });
    dio.httpClientAdapter = TestAdapter((options) async =>
        options.headers['Authorization'] == 'Bearer new'
            ? response(200)
            : response(401));
    final results = Future.wait(
        [dio.get<dynamic>('/auth/me'), dio.get<dynamic>('/auth/me')]);
    await entered.future;
    gate.complete();
    expect((await results).map((r) => r.statusCode), [200, 200]);
    expect(refreshes, 1);
    expect(tokens.refresh, 'next');
    expect(expired, 0);
  });

  test('refresh 403 clears tokens and announces expiration', () async {
    dio.httpClientAdapter = TestAdapter((_) async => response(401));
    refresh.httpClientAdapter = TestAdapter((_) async => response(403));
    await expectLater(
        dio.get<dynamic>('/auth/me'), throwsA(isA<DioException>()));
    expect(tokens.access, isNull);
    expect(tokens.refresh, isNull);
    expect(expired, 1);
  });

  test('401 after successful refresh expires session instead of looping',
      () async {
    var count = 0;
    dio.httpClientAdapter = TestAdapter((_) async => response(401));
    refresh.httpClientAdapter = TestAdapter((_) async {
      count++;
      return response(200, {'accessToken': 'new', 'refreshToken': 'next'});
    });
    await expectLater(
        dio.get<dynamic>('/auth/me'), throwsA(isA<DioException>()));
    expect(count, 1);
    expect(expired, 1);
    expect(tokens.access, isNull);
  });

  test('temporary refresh connection failure preserves session', () async {
    dio.httpClientAdapter = TestAdapter((_) async => response(401));
    refresh.httpClientAdapter = TestAdapter((options) async =>
        throw DioException(
            requestOptions: options, type: DioExceptionType.connectionError));
    await expectLater(
        dio.get<dynamic>('/auth/me'),
        throwsA(isA<DioException>()
            .having((e) => e.type, 'type', DioExceptionType.connectionError)));
    expect(tokens.access, 'old');
    expect(expired, 0);
  });

  test('missing access token can recover using stored refresh token', () async {
    tokens.access = null;
    dio.httpClientAdapter = TestAdapter((options) async =>
        options.headers['Authorization'] == 'Bearer new'
            ? response(200)
            : response(401));
    refresh.httpClientAdapter = TestAdapter((_) async =>
        response(200, {'accessToken': 'new', 'refreshToken': 'next'}));
    expect((await dio.get<dynamic>('/auth/me')).statusCode, 200);
  });
}
