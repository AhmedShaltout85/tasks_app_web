import 'dart:async';
// ignore: deprecated_member_use
import 'dart:html' as html;

StreamSubscription<void> onWindowFocus(void Function() callback) {
  return html.window.onFocus.listen((_) => callback());
}
