// Meetings tab: find the nearest area meetings by location or postcode, or browse them all.
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../club_data.dart';
import '../data.dart';
import '../ui.dart';

class MeetingsPage extends StatefulWidget {
  const MeetingsPage({super.key});

  @override
  State<MeetingsPage> createState() => _MeetingsPageState();
}

class _MeetingsPageState extends State<MeetingsPage> {
  final _postcode = TextEditingController();
  Place? _place;
  String _status = '';
  bool _busy = false;

  @override
  void dispose() {
    _postcode.dispose();
    super.dispose();
  }

  Future<void> _search(Future<Place> Function() find) async {
    setState(() => _busy = true);
    try {
      final place = await find();
      setState(() {
        _place = place;
        _status = 'Closest areas to ${place.label}. Distances are in a straight line, not by road.';
      });
    } on LookupError catch (e) {
      setState(() => _status = e.message);
    } catch (_) {
      setState(() => _status = "Postcode lookup isn't available right now. Try again, or browse all areas below.");
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<Place> _myLocation() async {
    setState(() => _status = 'Finding your location…');
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) throw Exception();
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low, timeLimit: Duration(seconds: 10)),
      );
      return Place(pos.latitude, pos.longitude, 'your location');
    } catch (_) {
      throw LookupError("Location isn't available. Enter a postcode instead.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final club = ClubScope.of(context);
    final areas = club.areas;
    final place = _place;
    final nearest = place == null || areas == null
        ? null
        : (areas.items
                .where((a) => a.lat != null && a.lng != null)
                .map((a) => (area: a, miles: miles(place.lat, place.lng, a.lat!, a.lng!)))
                .toList()
              ..sort((x, y) => x.miles.compareTo(y.miles)))
            .take(3);

    return RefreshIndicator(
      onRefresh: club.load,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          StripesHeader(
            title: 'Find your nearest meeting',
            titleSize: 40,
            child: const Text(
                'Area groups meet every month across the country. Use your location or enter a postcode to see the closest.'),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 12, children: [
              FilledButton.icon(
                onPressed: _busy ? null : () => _search(_myLocation),
                icon: const Icon(Icons.my_location),
                label: const Text('Use my location'),
              ),
              Row(spacing: 8, children: [
                Expanded(
                  child: TextField(
                    controller: _postcode,
                    textCapitalization: TextCapitalization.characters,
                    autocorrect: false,
                    autofillHints: const [AutofillHints.postalCode],
                    textInputAction: TextInputAction.search,
                    decoration: const InputDecoration(
                      labelText: 'Or enter a postcode',
                      hintText: 'e.g. MK45 5HB',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (v) => _search(() => lookupPostcode(v)),
                  ),
                ),
                OutlinedButton(
                  onPressed: _busy ? null : () => _search(() => lookupPostcode(_postcode.text)),
                  child: const Text('Find'),
                ),
              ]),
              if (_busy) const LinearProgressIndicator(),
              if (_status.isNotEmpty) Text(_status, style: const TextStyle(fontWeight: FontWeight.w600)),
              if (areas == null && club.areasFailed)
                const Text("Meetings couldn't be loaded. See the list on mocgb.net.")
              else if (areas == null)
                const Center(child: CircularProgressIndicator()),
              if (nearest != null)
                for (final n in nearest) AreaCard(n.area, miles: n.area.approx ? null : n.miles),
              if (areas != null) ...[
                const SizedBox(height: 8),
                Text('All areas', style: display(context, 28)),
                Card(
                  child: Column(children: [
                    for (final (i, a) in areas.items.indexed) ...[
                      if (i > 0) const Divider(),
                      AreaTile(a),
                    ],
                  ]),
                ),
              ],
              Text(
                'Meeting details come from the monthly meetings page on mocgb.net. '
                'Check there or with the area contact before you travel.',
                style: TextStyle(fontSize: 13, color: Club.of(context).chrome),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => open('https://www.mocgb.net/index.php/the-club/monthly-meeting'),
                  child: const Text('Monthly meetings on mocgb.net'),
                ),
              ),
              CheckedNote('Meeting details', areas?.checked),
            ]),
          ),
        ],
      ),
    );
  }
}

/// A nearby area, shown open, with its distance.
class AreaCard extends StatelessWidget {
  const AreaCard(this.area, {super.key, this.miles});
  final Area area;
  final double? miles;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(area.name, style: display(context, 24))),
              if (miles != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text('${miles!.round()} miles',
                      style: TextStyle(color: Club.of(context).accent, fontWeight: FontWeight.w700)),
                ),
            ]),
            const SizedBox(height: 6),
            _AreaDetails(area),
          ]),
        ),
      );
}

/// An area in the full list: tap to open its details.
class AreaTile extends StatelessWidget {
  const AreaTile(this.area, {super.key});
  final Area area;

  @override
  Widget build(BuildContext context) => ExpansionTile(
        shape: const Border(),
        title: Text(area.name, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: area.when == null ? null : Text(area.when!),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [_AreaDetails(area, showWhen: false)],
      );
}

class _AreaDetails extends StatelessWidget {
  const _AreaDetails(this.area, {this.showWhen = true});
  final Area area;
  final bool showWhen;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(area.where),
        if (area.contact != null) Text('Contact: ${area.contact}', style: TextStyle(color: Club.of(context).chrome)),
        if (showWhen && area.when != null)
          Text(area.when!, style: const TextStyle(fontWeight: FontWeight.w600)),
        // Icons only, to keep each area short; the tooltips name them (and are read out by screen readers)
        Row(children: [
          if (area.postcode != null)
            IconButton(
              onPressed: () => open(mapsUrl('${area.venue}, ${area.postcode}')),
              icon: const Icon(Icons.directions),
              tooltip: 'Directions to ${area.venue}',
            ),
          if (area.email != null) ...[
            IconButton(
              onPressed: () => open('mailto:${area.email}'),
              icon: const Icon(Icons.mail_outline),
              tooltip: area.contact == null ? 'Email ${area.name}' : 'Email ${area.contact}',
            ),
            CopyButton(area.email!),
          ],
          if (area.facebook != null)
            IconButton(
              onPressed: () => open(area.facebook!),
              icon: const Icon(Icons.facebook),
              tooltip: '${area.name} Facebook group',
            ),
        ]),
      ]);
}
