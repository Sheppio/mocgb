// What every tab shares: the events and meetings from the site, and the chosen theme.
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data.dart';

class ClubData extends ChangeNotifier {
  ClubData() {
    firstLoad = load();
    _loadTheme();
    // An app can sit in the background for days. When it comes back after a while, quietly fetch
    // the latest events and meetings (the site does the same).
    _lifecycle = AppLifecycleListener(onResume: () {
      if (DateTime.now().difference(_loadedAt) > const Duration(minutes: 30)) load();
    });
  }

  late final AppLifecycleListener _lifecycle;

  /// Finishes when the first load has succeeded or failed.
  late final Future<void> firstLoad;
  DateTime _loadedAt = DateTime.now();

  Checked<ClubEvent>? events;
  Checked<Area>? areas;
  bool eventsFailed = false;
  bool areasFailed = false;

  /// Loads (or reloads) both lists. A failed reload keeps what's already shown.
  Future<void> load() async {
    _loadedAt = DateTime.now();
    await Future.wait([
      loadEvents().then((v) {
        events = v;
        eventsFailed = false;
      }, onError: (_) { eventsFailed = events == null; }),
      loadAreas().then((v) {
        areas = v;
        areasFailed = false;
      }, onError: (_) { areasFailed = areas == null; }),
    ]);
    notifyListeners();
  }

  ThemeMode themeMode = ThemeMode.system;

  Future<void> _loadTheme() async {
    try {
      final saved = (await SharedPreferences.getInstance()).getString('theme');
      themeMode = ThemeMode.values.firstWhere((m) => m.name == saved, orElse: () => ThemeMode.system);
      notifyListeners();
    } catch (_) {
      // No saved choice (or storage unavailable): follow the device
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    notifyListeners();
    try {
      await (await SharedPreferences.getInstance()).setString('theme', mode.name);
    } catch (_) {}
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }
}

/// Gives the widgets below it the shared [ClubData], and rebuilds them when it changes.
class ClubScope extends InheritedNotifier<ClubData> {
  const ClubScope({super.key, required ClubData data, required super.child}) : super(notifier: data);

  static ClubData of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<ClubScope>()!.notifier!;
}
