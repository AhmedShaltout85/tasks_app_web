import 'dart:async';

StreamSubscription<void> onWindowFocus(void Function() callback) {
  return Stream<void>.empty().listen((_) {});
}

StreamSubscription<void> onWindowBlur(void Function() callback) {
  return Stream<void>.empty().listen((_) {});
}

StreamSubscription<void> onVisibilityChange(void Function(bool visible) callback) {
  return Stream<void>.empty().listen((_) {});
}
