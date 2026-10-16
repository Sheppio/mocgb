// App-bar menu for trying the app on other devices (device_preview). Only shown when simulation is on:
// local and Preview builds (profile mode); production is a release build, where it never appears.
import 'package:device_preview/device_preview.dart';
import 'package:device_preview/presets.dart';
import 'package:flutter/material.dart';

const _devices = [
  DevicePresets.iPhoneSe3,
  DevicePresets.iPhone17,
  DevicePresets.iPhone17ProMax,
  DevicePresets.pixel10,
  DevicePresets.galaxyS25,
  DevicePresets.galaxyZFold8,
  DevicePresets.iPadMini,
  DevicePresets.iPadPro13M5,
];

class DeviceMenu extends StatelessWidget {
  const DeviceMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final c = DevicePreview.maybeController;
    if (c == null) return const SizedBox.shrink();
    return PopupMenuButton<Future<void> Function()>(
      icon: const Icon(Icons.devices),
      tooltip: 'Preview on another device',
      onSelected: (action) => action(),
      itemBuilder: (context) {
        final sim = c.simulationListenable.value;
        final landscape = sim?.orientation == Orientation.landscape;
        final bigText = (sim?.textScaleFactor ?? 1) > 1;
        return [
          for (final d in _devices)
            CheckedPopupMenuItem(
              checked: sim?.presetId == d.id,
              value: () => c.applyPreset(d, orientation: sim?.orientation ?? Orientation.portrait),
              child: Text(d.name),
            ),
          CheckedPopupMenuItem(checked: sim == null, value: c.reset, child: const Text('This screen')),
          const PopupMenuDivider(),
          CheckedPopupMenuItem(
            enabled: sim != null,
            checked: landscape,
            value: () => c.setOrientation(landscape ? Orientation.portrait : Orientation.landscape),
            child: const Text('Landscape'),
          ),
          CheckedPopupMenuItem(
            enabled: sim != null,
            checked: bigText,
            value: () => c.update((s) => s.copyWith(textScaleFactor: bigText ? 1.0 : 2.0)),
            child: const Text('Text 200%'),
          ),
        ];
      },
    );
  }
}
