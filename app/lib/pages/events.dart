// Events tab: every upcoming event, with details, calendar and directions.
import 'package:flutter/material.dart';

import '../club_data.dart';
import '../data.dart';
import '../ui.dart';

class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final club = ClubScope.of(context);
    final events = club.events;
    return RefreshIndicator(
      onRefresh: club.load,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const StripesHeader(title: 'Events', child: Text('Shows, club stands and the national show.')),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 16, children: [
              if (events == null && club.eventsFailed)
                const Text("Events couldn't be loaded. See the full list on mocgb.net.")
              else if (events == null)
                const Center(child: CircularProgressIndicator())
              else if (events.items.isEmpty)
                const Text('No events are listed right now. Check mocgb.net for new dates.')
              else
                for (final e in events.items) EventCard(e),
              OutlinedButton(
                onPressed: () => open('https://www.mocgb.net/index.php/the-club/events'),
                child: const Text('See all events on mocgb.net'),
              ),
              CheckedNote('Event details', events?.checked),
            ]),
          ),
        ],
      ),
    );
  }
}

/// An event with its picture, dates, place, note and links.
class EventCard extends StatelessWidget {
  const EventCard(this.event, {super.key});
  final ClubEvent event;

  @override
  Widget build(BuildContext context) {
    final logo = event.logoUrl;
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (logo != null)
          ColoredBox(
            color: Colors.white, // behind event logos, which are mostly drawn on white
            // Shown whole: some are photos, some are square club logos
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: Image.network(logo.toString(),
                  width: double.infinity, fit: BoxFit.contain, errorBuilder: (_, _, _) => const SizedBox()),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 6, children: [
            Text(dateRange(event.start, event.end),
                style: TextStyle(color: Club.of(context).accent, fontWeight: FontWeight.w700)),
            Text(event.title, style: display(context, 26)),
            Text(event.location, style: TextStyle(color: Club.of(context).chrome)),
            if (event.note != null) Text(event.note!, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 6),
            Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
              FilledButton(onPressed: () => open(event.url), child: const Text('Event details')),
              TextButton.icon(
                onPressed: () => open(event.calendarUrl),
                icon: const Icon(Icons.event_available),
                label: const Text('Add to calendar'),
              ),
              if (event.map != null)
                TextButton.icon(
                  onPressed: () => open(mapsUrl(event.map!)),
                  icon: const Icon(Icons.directions),
                  label: const Text('Directions'),
                ),
            ]),
          ]),
        ),
      ]),
    );
  }
}
