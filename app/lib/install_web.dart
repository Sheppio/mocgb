// The web: uses the install offer that web/index.html keeps from the browser's beforeinstallprompt.
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

import 'install.dart';

@JS('mocgbInstallPrompt')
external _InstallPrompt? get _prompt;

@JS('mocgbInstallPrompt')
external set _prompt(_InstallPrompt? value);

@JS('mocgbInstalled')
external bool? get _installed;

extension type _InstallPrompt(JSObject _) implements JSObject {
  external JSPromise<JSAny?> prompt();
  external JSPromise<JSAny?> get userChoice;
}

extension type _Navigator(JSObject _) implements JSObject {
  /// Safari on iPhone and iPad: true when opened from the home screen.
  external bool? get standalone;
}

bool get _isStandalone =>
    web.window.matchMedia('(display-mode: standalone)').matches ||
    (_Navigator(web.window.navigator as JSObject).standalone ?? false);

bool get _isIOS {
  final nav = web.window.navigator;
  return RegExp('iPad|iPhone|iPod').hasMatch(nav.userAgent) ||
      (nav.platform == 'MacIntel' && nav.maxTouchPoints > 1);
}

InstallOffer _current() {
  if (_isStandalone || (_installed ?? false)) return InstallOffer.none;
  if (_isIOS) return InstallOffer.shareMenu;
  return _prompt != null ? InstallOffer.prompt : InstallOffer.none;
}

ValueNotifier<InstallOffer> watchInstallOffer() {
  final offer = ValueNotifier(_current());
  web.window.addEventListener('mocgb-install-change', ((web.Event _) {
    offer.value = _current();
  }).toJS);
  return offer;
}

Future<void> showInstallPrompt() async {
  final prompt = _prompt;
  if (prompt == null) return;
  await prompt.prompt().toDart;
  await prompt.userChoice.toDart;
  // A prompt can only be shown once; the browser offers a new one later if it was dismissed
  _prompt = null;
  web.window.dispatchEvent(web.Event('mocgb-install-change'));
}
