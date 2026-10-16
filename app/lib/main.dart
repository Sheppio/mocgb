// MOCGB app: the members' hub. Same content as the website (events, area meetings, contacts,
// joining and club links), laid out as an app with a tab bar along the bottom.
import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
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

  /// Whether the top bar is showing. It slides away as you scroll down a page, to give the content
  /// more room, and comes back as soon as you scroll up (or switch tab).
  bool _barShown = true;

  void _goTo(int tab) => setState(() {
        _tab = tab;
        _opened.add(tab);
        _barShown = true;
      });

  bool _onScroll(UserScrollNotification n) {
    if (n.depth != 0 || n.metrics.axis != Axis.vertical || n.direction == ScrollDirection.idle) return false;
    final show = n.direction == ScrollDirection.forward;
    if (show != _barShown) setState(() => _barShown = show);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // The bar sits in the body rather than Scaffold.appBar so it can fold away. The status bar strip
    // above it stays, in the bar's colour, so the phone's clock and battery always have a background.
    final bar = Material(
      color: theme.appBarTheme.backgroundColor,
      child: SafeArea(
        bottom: false,
        child: ClipRect(
          child: AnimatedAlign(
            alignment: Alignment.bottomCenter,
            heightFactor: _barShown ? 1 : 0,
            duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: AppBar(
              primary: false,
              titleSpacing: 16,
              title: Row(mainAxisSize: MainAxisSize.min, spacing: 10, children: [
                const TailLights(height: 22),
                Text('MOCGB', style: display(context, 26)),
              ]),
              actions: const [InstallButton(), DeviceMenu()],
            ),
          ),
        ),
      ),
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: theme.appBarTheme.systemOverlayStyle!,
      child: Scaffold(
        body: Column(children: [
          bar,
          Expanded(
            // Each tab keeps its place (scroll position, postcode search) while you look at another.
            // SafeArea keeps content clear of notches and camera holes when a phone is on its side.
            child: NotificationListener<UserScrollNotification>(
              onNotification: _onScroll,
              child: SafeArea(top: false, bottom: false, child: IndexedStack(index: _tab, children: [
                for (final (i, page) in [
                  HomePage(goTo: _goTo),
                  const EventsPage(),
                  const MeetingsPage(),
                  const ContactPage(),
                  const MorePage(),
                ].indexed)
                  _opened.contains(i) ? page : const SizedBox.shrink(),
              ])),
            ),
          ),
        ]),
        // A hairline along the top of the tab bar, like the one under the top bar
        bottomNavigationBar: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant))),
          child: NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: _goTo,
            destinations: [
              for (final (icon, selected, label) in _tabs)
                NavigationDestination(icon: Icon(icon), selectedIcon: Icon(selected), label: label),
            ],
          ),
        ),
      ),
    );
  }
}
