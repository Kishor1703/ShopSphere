import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

import 'failure.dart';

/// Converts any thrown object into a [Failure] with a safe, readable message.
/// Raw exception text and stack traces are never exposed.
Failure mapError(Object error) {
  if (error is Failure) return error;

  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const Failure(
          FailureType.timeout,
          'The request took too long. Check your connection and try again.',
        );
      case DioExceptionType.connectionError:
        return _noInternet;
      case DioExceptionType.badResponse:
        return _fromStatus(error.response?.statusCode);
      case DioExceptionType.cancel:
        return const Failure(FailureType.unknown, 'The request was cancelled.');
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        if (error.error is SocketException) return _noInternet;
        return _unexpected;
    }
  }

  if (error is TimeoutException) {
    return const Failure(
      FailureType.timeout,
      'The request took too long. Check your connection and try again.',
    );
  }

  if (error is FormatException || error is TypeError) {
    return const Failure(
      FailureType.parsing,
      'We received data we could not read. Please try again later.',
    );
  }

  return _unexpected;
}

const _noInternet = Failure(
  FailureType.network,
  'No internet connection. Check your network and try again.',
);

const _unexpected = Failure(
  FailureType.unknown,
  'Something unexpected happened. Please try again.',
);

Failure _fromStatus(int? status) {
  switch (status) {
    case 400:
      return const Failure(FailureType.badRequest, 'The request was invalid.');
    case 401:
      return const Failure(
        FailureType.unauthorized,
        'Your session has expired. Please log in again.',
      );
    case 403:
      return const Failure(
        FailureType.forbidden,
        'You do not have permission to do that.',
      );
    case 404:
      return const Failure(
        FailureType.notFound,
        'We could not find what you were looking for.',
      );
  }
  if (status != null && status >= 500) {
    return const Failure(
      FailureType.server,
      'Our server ran into a problem. Please try again in a moment.',
    );
  }
  return _unexpected;
}
