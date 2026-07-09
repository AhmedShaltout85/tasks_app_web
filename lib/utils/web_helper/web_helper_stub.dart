import 'dart:async';

StreamSubscription<void> onWindowFocus(void Function() callback) {
  // No-op on non-web platforms
  return Stream<void>.empty().listen((_) {});
}
