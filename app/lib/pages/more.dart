// More tab: members' area, club links, appearance, privacy and about.
import 'package:flutter/material.dart';

import '../club_data.dart';
import '../data.dart';
import '../ui.dart';

const _links = [
  (Icons.forum_outlined, 'Forum', 'Ask questions and talk Mustangs with members', 'https://forum.mocgb.net'),
  (Icons.help_outline, 'FAQs', 'Registering imports, DVLA records and rejoining', 'https://www.mocgb.net/index.php/need-help'),
  (Icons.facebook, 'Facebook', "The club's main page", 'https://www.facebook.com/MOCGB'),
  (Icons.sell_outlined, 'For Sale & Wanted', 'Buy and sell cars and parts on Facebook',
      'https://www.facebook.com/groups/MOCGB.ForSaleWanted'),
  (Icons.photo_camera_outlined, 'Instagram', '@mustangownersclub_of_gb', 'https://www.instagram.com/mustangownersclub_of_gb/'),
  (Icons.public, 'mocgb.net', "The club's main website", 'https://www.mocgb.net'),
];

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final club = ClubScope.of(context);
    final chrome = Club.of(context).chrome;
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const StripesHeader(title: 'More'),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 12, children: [
            const SectionTitle("Members' area", size: 28),
            const Text('Members log in through the Membership Portal on mocgb.net, where you can manage your membership.'),
            FilledButton(
              onPressed: () => open('https://www.mocgb.net/index.php/component/users/?view=login&Itemid=872'),
              child: const Text('Log in to the Membership Portal'),
            ),
            const SizedBox(height: 16),
            const SectionTitle('Club links', size: 28),
            Card(
              child: Column(children: [
                for (final (i, (icon, title, about, url)) in _links.indexed) ...[
                  if (i > 0) const Divider(),
                  ListTile(
                    leading: Icon(icon),
                    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(about),
                    trailing: const Icon(Icons.open_in_new, size: 18),
                    onTap: () => open(url),
                  ),
                ],
              ]),
            ),
            const SizedBox(height: 16),
            const SectionTitle('Appearance', size: 28),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.brightness_auto)),
                ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode)),
                ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode)),
              ],
              selected: {club.themeMode},
              onSelectionChanged: (s) => club.setThemeMode(s.first),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacy', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('No cookies, advertising or tracking'),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () => open(siteUrl.resolve('privacy.html')),
              ),
            ),
            const SizedBox(height: 8),
            Row(spacing: 10, children: [
              const TailLights(height: 18),
              Expanded(
                child: Text('Mustang Owners Club of Great Britain. Not affiliated with Ford Motor Company.',
                    style: TextStyle(fontSize: 13, color: chrome)),
              ),
            ]),
          ]),
        ),
      ],
    );
  }
}
