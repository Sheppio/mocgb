// Home tab: the club, the next event, a way to the nearest meeting, and joining.
import 'package:flutter/material.dart';

import '../club_data.dart';
import '../ui.dart';
import 'events.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.goTo});

  /// Switches to another tab (see the tabs in main.dart).
  final void Function(int tab) goTo;

  @override
  Widget build(BuildContext context) {
    final club = ClubScope.of(context);
    final events = club.events;
    return RefreshIndicator(
      onRefresh: club.load,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const StripesHeader(
            lights: true,
            title: 'Mustang Owners Club of Great Britain',
            child: Text(
              'Run by volunteers for more than 2,500 members. Owners and fans of every Mustang, '
              'from 1964 to today, are welcome.',
              style: TextStyle(fontSize: 17, height: 1.4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const SectionTitle('Next event'),
              if (events == null && club.eventsFailed)
                const Text("Events couldn't be loaded. See the full list on mocgb.net.")
              else if (events == null)
                const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
              else if (events.items.isEmpty)
                const Text('No events are listed right now. Check mocgb.net for new dates.')
              else
                EventCard(events.items.first),
              if ((events?.items.length ?? 0) > 1)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => goTo(1),
                    icon: const Icon(Icons.arrow_forward),
                    label: Text('Also coming up: ${events!.items.length - 1} more'),
                  ),
                ),
              const SizedBox(height: 20),
              Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
                  leading: Icon(Icons.place, color: Club.of(context).accent, size: 32),
                  title: Text('Find your nearest meeting', style: display(context, 24)),
                  subtitle: const Text('Area groups meet every month across the country.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => goTo(2),
                ),
              ),
              const SizedBox(height: 28),
            ]),
          ),
          const JoinBand(),
        ],
      ),
    );
  }
}

/// The blue "Join the club" band, as on the site.
class JoinBand extends StatelessWidget {
  const JoinBand({super.key});

  @override
  Widget build(BuildContext context) => Container(
        color: guardsmanBlue,
        padding: const EdgeInsets.fromLTRB(16, 28, 16, 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 12, children: [
          Text('Join the club', style: display(context, 34).copyWith(color: Colors.white)),
          const Text('Full membership or digital membership. Returning members can skip the joining fee.',
              style: TextStyle(color: Color(0xFFC5CBD8), fontSize: 16, height: 1.4)),
          const SizedBox(height: 4),
          FilledButton(
            onPressed: () => open('https://www.mocgb.net/index.php/memberships'),
            child: const Text('Join the MOCGB'),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFFAAB3C7)),
            ),
            onPressed: () => open('https://www.mocgb.net/index.php/memberships/online/sign-up'),
            child: const Text('Digital membership'),
          ),
        ]),
      );
}
