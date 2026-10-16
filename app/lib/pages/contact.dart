// Contact tab: the right person to email for each kind of question.
import 'package:flutter/material.dart';

import '../ui.dart';

const _contacts = [
  ('Membership secretary', 'Joining, renewals and membership cards', 'membership@mocgb.net'),
  ('Age-related plates', 'Dating letters and DVLA registration for imported Mustangs', 'age@mocgb.net'),
  ('Events secretary', 'Shows, club stands and booking', 'events@mocgb.net'),
  ('Concours secretary', 'Judging at the national show', 'judging@mocgb.net'),
  ('Magazine editor', 'Stories and photos for the club magazine', 'editor@mocgb.net'),
  ('Chairman', 'Club matters', 'chairman@mocgb.net'),
  ('General enquiries', 'Anything else', 'info@mocgb.net'),
];

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const StripesHeader(title: 'Contact the club', child: Text('Email the right person directly.')),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 12, children: [
              Card(
                child: Column(children: [
                  for (final (i, (role, about, email)) in _contacts.indexed) ...[
                    if (i > 0) const Divider(),
                    ListTile(
                      contentPadding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
                      title: Text(role, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(about),
                        Text(email, style: TextStyle(color: Club.of(context).accent, fontWeight: FontWeight.w600)),
                      ]),
                      trailing: CopyButton(email),
                      onTap: () => open('mailto:$email'),
                    ),
                  ],
                ]),
              ),
              Text('Need a valuation or another committee member?', style: TextStyle(color: Club.of(context).chrome)),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => open('https://www.mocgb.net/index.php/the-club/mocgb-committee'),
                  child: const Text('See the committee page'),
                ),
              ),
            ]),
          ),
        ],
      );
}
