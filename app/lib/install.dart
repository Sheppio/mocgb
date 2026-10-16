// Installing the web app (the "Install" button in the top bar). Only does anything on the web:
// phone builds are installed from the app stores.
import 'package:flutter/material.dart';

import 'install_stub.dart' if (dart.library.js_interop) 'install_web.dart' as platform;

enum InstallOffer {
  /// Already installed, or this browser can't install apps.
  none,

  /// The browser can show its own install prompt (Chrome, Edge, Android).
  prompt,

  /// iPhone or iPad: no prompt, so explain the Share menu instead.
  shareMenu,
}

/// What the Install button can offer right now; changes when the browser allows installing or it's done.
final ValueNotifier<InstallOffer> installOffer = platform.watchInstallOffer();

class InstallButton extends StatelessWidget {
  const InstallButton({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
        valueListenable: installOffer,
        builder: (context, offer, _) => switch (offer) {
          InstallOffer.none => const SizedBox.shrink(),
          InstallOffer.prompt => _button(context, platform.showInstallPrompt),
          InstallOffer.shareMenu => _button(context, () => _shareMenuHelp(context)),
        },
      );

  Widget _button(BuildContext context, VoidCallback onPressed) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: TextButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.install_mobile),
          label: const Text('Install', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      );

  void _shareMenuHelp(BuildContext context) => showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.ios_share),
          title: const Text('Add MOCGB to your home screen'),
          content: const Text('Tap the Share button in Safari, then Add to Home Screen.'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
      );
}
