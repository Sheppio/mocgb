// Club data, read from the website's JSON files so the app and the site always agree.
// On the web the app is served at /app/ next to the site, so it reads the files from the same host
// (production or a Preview). Phone builds read them from the live site.
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

final Uri siteUrl = kIsWeb ? Uri.base.resolve('/') : Uri.parse('https://mocgb.helloshep.com/');

class ClubEvent {
  ClubEvent({
    required this.title,
    required this.start,
    required this.end,
    required this.location,
    required this.url,
    this.logo,
    this.note,
  });

  factory ClubEvent.fromJson(Map<String, dynamic> j) => ClubEvent(
        title: j['title'] as String,
        start: DateTime.parse(j['start'] as String),
        end: DateTime.parse((j['end'] ?? j['start']) as String),
        location: j['location'] as String,
        url: j['url'] as String,
        logo: j['logo'] as String?,
        note: j['note'] as String?,
      );

  final String title;
  final DateTime start;
  final DateTime end;
  final String location;
  final String url;
  final String? logo;
  final String? note;

  Uri? get logoUrl => logo == null ? null : siteUrl.resolve(logo!);
}

class Area {
  Area({
    required this.name,
    this.venue,
    this.postcode,
    this.when,
    this.email,
    this.facebook,
  });

  factory Area.fromJson(Map<String, dynamic> j) => Area(
        name: j['name'] as String,
        venue: j['venue'] as String?,
        postcode: j['postcode'] as String?,
        when: j['when'] as String?,
        email: j['email'] as String?,
        facebook: j['facebook'] as String?,
      );

  final String name;
  final String? venue;
  final String? postcode;
  final String? when;
  final String? email;
  final String? facebook;
}

Future<Map<String, dynamic>> _getJson(String path) async {
  final res = await http.get(siteUrl.resolve(path));
  if (res.statusCode != 200) throw Exception('Could not load $path (${res.statusCode})');
  return jsonDecode(res.body) as Map<String, dynamic>;
}

/// Events that haven't finished yet, soonest first.
Future<List<ClubEvent>> loadEvents() async {
  final json = await _getJson('data/events.json');
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return (json['events'] as List)
      .map((e) => ClubEvent.fromJson(e as Map<String, dynamic>))
      .where((e) => !e.end.isBefore(today))
      .toList()
    ..sort((a, b) => a.start.compareTo(b.start));
}

Future<List<Area>> loadAreas() async {
  final json = await _getJson('data/areas.json');
  return (json['areas'] as List).map((a) => Area.fromJson(a as Map<String, dynamic>)).toList();
}
