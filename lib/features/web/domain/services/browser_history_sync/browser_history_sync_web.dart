// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void syncUrlToBrowserHistory(String url) {
  try {
    html.window.history.replaceState(null, '', url);
  } catch (_) {}
}

void removeWebLoadingIndicator() {
  try {
    final el = html.document.getElementById('loading-indicator');
    el?.remove();
  } catch (_) {}
}
