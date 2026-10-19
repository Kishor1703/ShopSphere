import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/api_client.dart';
import '../network/session_events.dart';
import '../storage/token_storage.dart';

/// Overridden in `main()` with the initialised instance.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider not overridden'),
);

final tokenStorageProvider =
    Provider<TokenStorage>((ref) => SecureTokenStorage());

final sessionEventsProvider = Provider<SessionEvents>((ref) {
  final events = SessionEvents();
  ref.onDispose(events.dispose);
  return events;
});

final dioProvider = Provider<Dio>((ref) {
  final events = ref.watch(sessionEventsProvider);
  return createDio(
    tokens: ref.watch(tokenStorageProvider),
    onSessionExpired: events.notifyExpired,
  );
});
