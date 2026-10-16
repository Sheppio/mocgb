// Club data, read from the website's JSON files so the app and the site always agree.
// On the web the app is served at /app/ next to the site, so it reads the files from the same host
// (production or a Preview). Phone builds read them from the live site.
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

final Uri siteUrl = kIsWeb ? Uri.base.resolve('/') : Uri.parse('https://mocgb.helloshep.com/');

class ClubEvent {
  ClubEvent({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    required this.location,
    required this.url,
    this.logo,
    this.note,
    this.map,
  });

  factory ClubEvent.fromJson(Map<String, dynamic> j) => ClubEvent(
        id: j['id'] as String,
        title: j['title'] as String,
        start: DateTime.parse(j['start'] as String),
        end: DateTime.parse((j['end'] ?? j['start']) as String),
        location: j['location'] as String,
        url: j['url'] as String,
        logo: j['logo'] as String?,
        note: j['note'] as String?,
        map: j['map'] as String?,
      );

  final String id;
  final String title;
  final DateTime start;
  final DateTime end;
  final String location;
  final String url;
  final String? logo;
  final String? note;

  /// Address for directions, when the event has one.
  final String? map;

  Uri? get logoUrl => logo == null ? null : siteUrl.resolve(logo!);

  /// The site's calendar file for this event (`website/calendar/<id>.ics`).
  Uri get calendarUrl => siteUrl.resolve('calendar/$id.ics');
}

class Area {
  Area({
    required this.name,
    this.contact,
    this.email,
    this.facebook,
    this.venue,
    this.postcode,
    this.when,
    this.lat,
    this.lng,
    this.approx = false,
  });

  factory Area.fromJson(Map<String, dynamic> j) => Area(
        name: j['name'] as String,
        contact: j['contact'] as String?,
        email: j['email'] as String?,
        facebook: j['facebook'] as String?,
        venue: j['venue'] as String?,
        postcode: j['postcode'] as String?,
        when: j['when'] as String?,
        lat: (j['lat'] as num?)?.toDouble(),
        lng: (j['lng'] as num?)?.toDouble(),
        approx: j['approx'] == true,
      );

  final String name;
  final String? contact;
  final String? email;
  final String? facebook;
  final String? venue;
  final String? postcode;
  final String? when;
  final double? lat;
  final double? lng;

  /// The position is only roughly where the area meets, so no distance is shown for it.
  final bool approx;

  String get where => switch ((venue, postcode)) {
        (null, _) => 'Venue not listed. Ask the area contact.',
        (final v?, null) => v,
        (final v?, final p?) => '$v, $p',
      };
}

/// A list from the site, with the date it was last checked against mocgb.net.
class Checked<T> {
  Checked(this.items, this.checked);
  final List<T> items;
  final DateTime? checked;
}

Future<Map<String, dynamic>> _getJson(String path) async {
  final res = await http.get(siteUrl.resolve(path));
  if (res.statusCode != 200) throw Exception('Could not load $path (${res.statusCode})');
  return jsonDecode(res.body) as Map<String, dynamic>;
}

DateTime? _checked(Map<String, dynamic> json) =>
    json['checked'] == null ? null : DateTime.parse(json['checked'] as String);

/// Events that haven't finished yet, soonest first.
Future<Checked<ClubEvent>> loadEvents() async {
  final json = await _getJson('data/events.json');
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final events = (json['events'] as List)
      .map((e) => ClubEvent.fromJson(e as Map<String, dynamic>))
      .where((e) => !e.end.isBefore(today))
      .toList()
    ..sort((a, b) => a.start.compareTo(b.start));
  return Checked(events, _checked(json));
}

Future<Checked<Area>> loadAreas() async {
  final json = await _getJson('data/areas.json');
  final areas = (json['areas'] as List).map((a) => Area.fromJson(a as Map<String, dynamic>)).toList();
  return Checked(areas, _checked(json));
}

/// Straight-line distance in miles.
double miles(double lat1, double lng1, double lat2, double lng2) {
  double r(double d) => d * pi / 180;
  final a = pow(sin(r(lat2 - lat1) / 2), 2) +
      cos(r(lat1)) * cos(r(lat2)) * pow(sin(r(lng2 - lng1) / 2), 2);
  return 3958.8 * 2 * asin(sqrt(a));
}

class Place {
  Place(this.lat, this.lng, this.label);
  final double lat;
  final double lng;
  final String label;
}

/// Thrown with a message to show the member.
class LookupError implements Exception {
  LookupError(this.message);
  final String message;
}

/// Finds a UK postcode, or just its first part (like MK45), with postcodes.io. Same rules as the site.
Future<Place> lookupPostcode(String raw) async {
  final pc = raw.trim().replaceAll(RegExp(r'\s+'), ' ').toUpperCase();
  if (pc.isEmpty) throw LookupError('Enter a postcode, or just the first part like MK45.');
  // postcodes.io has no usable coordinates for the Crown Dependencies, so place them directly
  const islands = {'JE': (49.19, -2.11), 'GY': (49.45, -2.54), 'IM': (54.15, -4.48)};
  if (RegExp(r'^(JE|GY|IM)\d').hasMatch(pc)) {
    final (lat, lng) = islands[pc.substring(0, 2)]!;
    return Place(lat, lng, pc);
  }
  bool inUK(Map<String, dynamic>? r) {
    final lat = (r?['latitude'] as num?)?.toDouble();
    final lng = (r?['longitude'] as num?)?.toDouble();
    return lat != null && lng != null && lat >= 49 && lat <= 61 && lng >= -9 && lng <= 2;
  }

  // Full postcode first, then the outward part on its own
  for (final path in [
    'postcodes/${Uri.encodeComponent(pc)}',
    'outcodes/${Uri.encodeComponent(pc.split(' ').first)}',
  ]) {
    final res = await http.get(Uri.parse('https://api.postcodes.io/$path'));
    if (res.statusCode == 200) {
      final result = (jsonDecode(res.body) as Map<String, dynamic>)['result'] as Map<String, dynamic>?;
      if (inUK(result)) {
        return Place((result!['latitude'] as num).toDouble(), (result['longitude'] as num).toDouble(), pc);
      }
    }
  }
  throw LookupError("We couldn't find $pc. Check it and try again.");
}
