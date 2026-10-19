import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopsphere/core/error/error_mapper.dart';
import 'package:shopsphere/core/error/failure.dart';

import '../helpers/factories.dart';

void main() {
  FailureType typeOf(Object error) => mapError(error).type;

  test('maps HTTP status codes to failure types', () {
    expect(typeOf(statusError(400)), FailureType.badRequest);
    expect(typeOf(statusError(401)), FailureType.unauthorized);
    expect(typeOf(statusError(403)), FailureType.forbidden);
    expect(typeOf(statusError(404)), FailureType.notFound);
    expect(typeOf(statusError(500)), FailureType.server);
    expect(typeOf(statusError(503)), FailureType.server);
  });

  test('maps timeouts and connection errors', () {
    final receiveTimeout = DioException(
      requestOptions: RequestOptions(path: '/x'),
      type: DioExceptionType.receiveTimeout,
    );
    expect(typeOf(receiveTimeout), FailureType.timeout);
    final timeout = DioException(
      requestOptions: RequestOptions(path: '/x'),
      type: DioExceptionType.transformTimeout,
    );
    expect(typeOf(timeout), FailureType.timeout);
    expect(typeOf(connectionError()), FailureType.network);
  });

  test('never leaks raw exception text', () {
    final failure = mapError(StateError('secret internal detail'));
    expect(failure.message, isNot(contains('secret')));
    expect(failure.type, FailureType.unknown);
  });
}
