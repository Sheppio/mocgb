// MOCGB app: the members' hub. Same content as the website (events, area meetings, contacts,
// joining and club links), laid out as an app with a tab bar along the bottom.
import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'club_data.dart';
import 'device_menu.dart';
import 'install.dart';
import 'pages/contact.dart';
import 'pages/events.dart';
import 'pages/home.dart';
import 'pages/meetings.dart';
import 'pages/more.dart';
import 'ui.dart';

Future<void> main() async {
  // Lets the app be shown as other phones and tablets (see device_menu.dart). device_preview only
  // simulates in debug and profile builds, so production (a release build) is unaffected.
  final binding = DevicePreview.enable();
  // Keep the splash screen (pubspec.yaml) up until the events have loaded, for at most 3 seconds
  FlutterNativeSplash.preserve(widgetsBinding: binding);
  await restoreDevice();
  final data = ClubData();
  Future.any([data.firstLoad, Future.delayed(const Duration(seconds: 3))]).whenComplete(FlutterNativeSplash.remove);
  runApp(MocgbApp(data: data));
}

class MocgbApp extends StatelessWidget {
  const MocgbApp({super.key, required this.data});
  final ClubData data;

  @override
  Widget build(BuildContext context) => ClubScope(
        data: data,
        child: ListenableBuilder(
          listenable: data,
          builder: (context, _) => MaterialApp(
            title: 'MOCGB',
            debugShowCheckedModeBanner: false,
            theme: clubTheme(Brightness.light),
            darkTheme: clubTheme(Brightness.dark),
            themeMode: data.themeMode,
            home: const AppShell(),
          ),
        ),
      );
}

const _tabs = [
  (Icons.home_outlined, Icons.home, 'Home'),
  (Icons.event_outlined, Icons.event, 'Events'),
  (Icons.place_outlined, Icons.place, 'Meetings'),
  (Icons.mail_outline, Icons.mail, 'Contact'),
  (Icons.menu, Icons.menu, 'More'),
];

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tab = 0;

  /// Tabs that have been opened. Each is built the first time it's shown, not at startup, so the
  /// app doesn't spend its first seconds on screens (and event pictures) nobody has looked at yet.
  final _opened = {0};

  void _goTo(int tab) => setState(() {
        _tab = tab;
        _opened.add(tab);
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(mainAxisSize: MainAxisSize.min, spacing: 10, children: [
          const TailLights(height: 22),
          Text('MOCGB', style: display(context, 26)),
        ]),
        actions: const [InstallButton(), DeviceMenu()],
      ),
      // Each tab keeps its place (scroll position, postcode search) while you look at another.
      // SafeArea keeps content clear of notches and camera holes when a phone is on its side.
      body: SafeArea(top: false, bottom: false, child: IndexedStack(index: _tab, children: [
        for (final (i, page) in [
          HomePage(goTo: _goTo),
          const EventsPage(),
          const MeetingsPage(),
          const ContactPage(),
          const MorePage(),
        ].indexed)
          _opened.contains(i) ? page : const SizedBox.shrink(),
      ])),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: _goTo,
        destinations: [
          for (final (icon, selected, label) in _tabs)
            NavigationDestination(icon: Icon(icon), selectedIcon: Icon(selected), label: label),
        ],
      ),
    );
  }
}
