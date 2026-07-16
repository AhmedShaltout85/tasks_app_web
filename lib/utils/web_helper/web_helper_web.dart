import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

StreamSubscription<void> onWindowFocus(void Function() callback) {
  final controller = StreamController<void>.broadcast();
  final handler = ((JSObject event) {
    controller.add(null);
    scheduleMicrotask(() => callback());
  }).toJS;
  web.window.addEventListener('focus', handler);
  return controller.stream.listen((_) {});
}

StreamSubscription<void> onWindowBlur(void Function() callback) {
  final controller = StreamController<void>.broadcast();
  final handler = ((JSObject event) {
    controller.add(null);
    scheduleMicrotask(() => callback());
  }).toJS;
  web.window.addEventListener('blur', handler);
  return controller.stream.listen((_) {});
}

StreamSubscription<void> onVisibilityChange(void Function(bool visible) callback) {
  final controller = StreamController<bool>.broadcast();
  final handler = ((JSObject event) {
    final hidden = web.document.hidden;
    controller.add(!hidden);
    scheduleMicrotask(() => callback(!hidden));
  }).toJS;
  web.document.addEventListener('visibilitychange', handler);
  return controller.stream.listen((_) {});
}
