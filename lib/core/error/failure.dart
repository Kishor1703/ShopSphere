import 'package:equatable/equatable.dart';

/// Categories of user-facing failures.
enum FailureType {
  network,
  timeout,
  badRequest,
  invalidCredentials,
  unauthorized,
  forbidden,
  notFound,
  server,
  parsing,
  unknown,
}

/// A framework-agnostic error whose [message] is safe to show to users.
class Failure extends Equatable implements Exception {
  const Failure(this.type, this.message);

  final FailureType type;
  final String message;

  @override
  List<Object?> get props => [type, message];

  @override
  String toString() => 'Failure($type)';
}
