// MOCGB app: the members' hub. Same content as the website: next event, area meetings,
// contacts, joining and club links, mostly pointing at mocgb.net.
import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'data.dart';
import 'device_menu.dart';

void main() {
  // Lets the app be shown as other phones and tablets (see device_menu.dart). device_preview only
  // simulates in debug and profile builds, so production (a release build) is unaffected.
  DevicePreview.enable();
  runApp(const MocgbApp());
}

// Colours from the website (website/styles.css)
const guardsmanBlue = Color(0xFF1B2A4E);
const candyappleRed = Color(0xFFB3121B);
const wimbledonWhite = Color(0xFFF1F2EF);

class MocgbApp extends StatelessWidget {
  const MocgbApp({super.key});

  @override
  Widget build(BuildContext context) {
    ThemeData theme(Brightness b) => ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: guardsmanBlue,
            primary: b == Brightness.light ? guardsmanBlue : const Color(0xFFB8C8EC),
            secondary: candyappleRed,
            brightness: b,
          ),
          scaffoldBackgroundColor: b == Brightness.light ? wimbledonWhite : const Color(0xFF0F1526),
        );
    return MaterialApp(
      title: 'MOCGB',
      debugShowCheckedModeBanner: false,
      theme: theme(Brightness.light),
      darkTheme: theme(Brightness.dark),
      home: const HubPage(),
    );
  }
}

Future<void> open(String url) => launchUrl(Uri.parse(url));

class HubPage extends StatefulWidget {
  const HubPage({super.key});

  @override
  State<HubPage> createState() => _HubPageState();
}

class _HubPageState extends State<HubPage> {
  late final Future<List<ClubEvent>> _events = loadEvents();
  late final Future<List<Area>> _areas = loadAreas();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MOCGB'),
        actions: const [DeviceMenu()],
        backgroundColor: guardsmanBlue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Mustang Owners Club of Great Britain',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          const Text('Run by volunteers for more than 2,500 members. Owners and fans of every '
              'Mustang, from 1964 to today, are welcome.'),
          const _Heading('Next event'),
          FutureBuilder(
            future: _events,
            builder: (context, snap) => _loaded(snap, (events) =>
                events.isEmpty ? const Text('No events announced yet.') : EventCard(events.first)),
          ),
          const _Heading('Area meetings'),
          FutureBuilder(
            future: _areas,
            builder: (context, snap) => _loaded(snap, (areas) => Card(
                  child: Column(children: [for (final a in areas) AreaTile(a)]),
                )),
          ),
          const _Heading('Contact the club'),
          Card(
            child: Column(children: [
              for (final (role, about, email) in _contacts)
                ListTile(
                  title: Text(role),
                  subtitle: Text('$about\n$email'),
                  isThreeLine: true,
                  onTap: () => open('mailto:$email'),
                ),
            ]),
          ),
          const _Heading('Join the club'),
          const Text('Full membership or digital membership. Returning members can skip the joining fee.'),
          const SizedBox(height: 12),
          Wrap(spacing: 12, runSpacing: 8, children: [
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: candyappleRed),
              onPressed: () => open('https://www.mocgb.net/index.php/memberships'),
              child: const Text('Join the MOCGB'),
            ),
            OutlinedButton(
              onPressed: () => open('https://www.mocgb.net/index.php/memberships/online/sign-up'),
              child: const Text('Digital membership'),
            ),
          ]),
          const _Heading('Club links'),
          Card(
            child: Column(children: [
              for (final (title, about, url) in _links)
                ListTile(
                  title: Text(title),
                  subtitle: Text(about),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => open(url),
                ),
            ]),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _loaded<T>(AsyncSnapshot<T> snap, Widget Function(T) done) {
    if (snap.hasError) return const Text('Couldn\'t load this. Check your connection and try again.');
    if (!snap.hasData) return const Center(child: CircularProgressIndicator());
    return done(snap.data as T);
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 28, bottom: 8),
        child: Text(text,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      );
}

class EventCard extends StatelessWidget {
  const EventCard(this.event, {super.key});
  final ClubEvent event;

  @override
  Widget build(BuildContext context) {
    final logo = event.logoUrl;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => open(event.url),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (logo != null)
              Container(
                color: Colors.white,
                height: 120,
                width: double.infinity,
                child: Image.network(logo.toString(),
                    fit: BoxFit.contain, errorBuilder: (_, _, _) => const SizedBox()),
              ),
            const SizedBox(height: 12),
            Text(_dates(event.start, event.end),
                style: const TextStyle(color: candyappleRed, fontWeight: FontWeight.bold)),
            Text(event.title, style: Theme.of(context).textTheme.titleMedium),
            Text(event.location),
            if (event.note != null) ...[const SizedBox(height: 8), Text(event.note!)],
          ]),
        ),
      ),
    );
  }
}

class AreaTile extends StatelessWidget {
  const AreaTile(this.area, {super.key});
  final Area area;

  @override
  Widget build(BuildContext context) => ExpansionTile(
        title: Text(area.name),
        subtitle: area.when == null ? null : Text(area.when!),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(switch ((area.venue, area.postcode)) {
            (null, _) => 'Venue not listed. Ask the area contact.',
            (final v?, null) => v,
            (final v?, final p?) => '$v, $p',
          }),
          Wrap(spacing: 8, children: [
            if (area.postcode != null)
              TextButton(
                onPressed: () => open('https://www.google.com/maps/search/?api=1&query='
                    '${Uri.encodeComponent('${area.venue}, ${area.postcode}')}'),
                child: const Text('Directions'),
              ),
            if (area.email != null)
              TextButton(onPressed: () => open('mailto:${area.email}'), child: const Text('Email')),
            if (area.facebook != null)
              TextButton(onPressed: () => open(area.facebook!), child: const Text('Facebook')),
          ]),
        ],
      );
}

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String _dates(DateTime start, DateTime end) {
  String d(DateTime t) => '${t.day} ${_months[t.month - 1]} ${t.year}';
  if (start == end) return d(start);
  if (start.year == end.year && start.month == end.month) return '${start.day}–${d(end)}';
  return '${d(start)} – ${d(end)}';
}

const _contacts = [
  ('Membership secretary', 'Joining, renewals and membership cards', 'membership@mocgb.net'),
  ('Age-related plates', 'Dating letters and DVLA registration for imported Mustangs', 'age@mocgb.net'),
  ('Events secretary', 'Shows, club stands and booking', 'events@mocgb.net'),
  ('Concours secretary', 'Judging at the national show', 'judging@mocgb.net'),
  ('Magazine editor', 'Stories and photos for the club magazine', 'editor@mocgb.net'),
  ('Chairman', 'Club matters', 'chairman@mocgb.net'),
  ('General enquiries', 'Anything else', 'info@mocgb.net'),
];

const _links = [
  ('Forum', 'Ask questions and talk Mustangs with members', 'https://forum.mocgb.net'),
  ('FAQs', 'Registering imports, DVLA records and rejoining', 'https://www.mocgb.net/index.php/need-help'),
  ('Facebook', 'The club\'s main page', 'https://www.facebook.com/MOCGB'),
  ('For Sale & Wanted', 'Facebook group for cars and parts', 'https://www.facebook.com/groups/MOCGB.ForSaleWanted'),
  ('Instagram', 'Photos from shows and meetings', 'https://www.instagram.com/mustangownersclub_of_gb/'),
  ('mocgb.net', 'The club\'s main website', 'https://www.mocgb.net'),
];
