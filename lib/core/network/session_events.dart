import 'dart:async';

/// Lets the network layer announce that the session cannot be recovered,
/// without the network layer depending on any feature code.
class SessionEvents {
  final _controller = StreamController<void>.broadcast();

  Stream<void> get onExpired => _controller.stream;

  void notifyExpired() {
    if (!_controller.isClosed) _controller.add(null);
  }

  void dispose() => _controller.close();
}
