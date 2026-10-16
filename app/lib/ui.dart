// The app's look, taken from the website (website/styles.css): the 1965 Shelby GT350 palette,
// Archivo in its narrow heavy cut for headings, tail lights and Le Mans stripes.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

const guardsmanBlue = Color(0xFF1B2A4E);
const candyappleRed = Color(0xFFB3121B);
const tailLightRed = Color(0xFFD01C25);
const wimbledonWhite = Color(0xFFF1F2EF);

/// Site colours that Material's scheme has no slot for, in light and dark.
class Club extends ThemeExtension<Club> {
  const Club({required this.paper, required this.accent, required this.chrome, required this.stripe});

  final Color paper; // raised surfaces: header, hero, cards
  final Color accent; // red text: dates, distances
  final Color chrome; // secondary text
  final Color stripe; // hero racing stripes

  static const light =
      Club(paper: Color(0xFFFAFAF8), accent: candyappleRed, chrome: Color(0xFF5F687C), stripe: guardsmanBlue);
  static const dark =
      Club(paper: Color(0xFF161E33), accent: Color(0xFFFF7A7F), chrome: Color(0xFF9BA4B8), stripe: Color(0xFF34508F));

  static Club of(BuildContext context) => Theme.of(context).extension<Club>()!;

  @override
  Club copyWith() => this;

  @override
  Club lerp(Club? other, double t) => t < 0.5 || other == null ? this : other;
}

ThemeData clubTheme(Brightness b) {
  final light = b == Brightness.light;
  final club = light ? Club.light : Club.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: guardsmanBlue,
    brightness: b,
    primary: light ? guardsmanBlue : const Color(0xFFB8C8EC),
    onPrimary: light ? Colors.white : guardsmanBlue,
    secondary: light ? candyappleRed : const Color(0xFFC8202A),
    onSecondary: Colors.white,
    surface: light ? wimbledonWhite : const Color(0xFF0F1526),
    onSurface: light ? const Color(0xFF161B2C) : const Color(0xFFE6E9F0),
    surfaceContainerLow: club.paper,
    outlineVariant: light ? const Color(0xFFD6D9DF) : const Color(0xFF2A3552),
  );
  final base = ThemeData(colorScheme: scheme, fontFamily: 'Archivo', brightness: b);
  return base.copyWith(
    extensions: [club],
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: club.paper,
      foregroundColor: scheme.primary,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 1,
      shape: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      systemOverlayStyle: light ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: club.paper,
      indicatorColor: light ? const Color(0xFFDDE3F0) : const Color(0xFF26355C),
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
            fontFamily: 'Archivo',
            fontSize: 12,
            fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
          )),
    ),
    cardTheme: CardThemeData(
      color: club.paper,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: light ? candyappleRed : const Color(0xFFC8202A),
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 48),
        textStyle: const TextStyle(fontFamily: 'Archivo', fontWeight: FontWeight.w700, fontSize: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        textStyle: const TextStyle(fontFamily: 'Archivo', fontWeight: FontWeight.w700, fontSize: 16),
      ),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
  );
}

/// Archivo narrow and heavy, as the site uses for headings (font-variation "wdth" 62, weight 800).
TextStyle display(BuildContext context, double size) => TextStyle(
      fontFamily: 'Archivo',
      fontSize: size,
      height: 1.0,
      fontWeight: FontWeight.w800,
      fontVariations: const [FontVariation('wdth', 62), FontVariation('wght', 800)],
      color: Theme.of(context).colorScheme.primary,
    );

/// The three tail lights from the club's logo.
class TailLights extends StatelessWidget {
  const TailLights({super.key, this.height = 20});
  final double height;

  @override
  Widget build(BuildContext context) {
    final w = height * 58 / 196;
    // Each light has a lighter strip along its top edge, as in website/icons/icon.svg
    Widget bar() => ClipRRect(
          borderRadius: BorderRadius.circular(w / 10),
          child: SizedBox(
            width: w,
            height: height,
            child: Column(children: [
              Container(height: height * 14 / 196, color: const Color(0xFFEA3E45)),
              Expanded(child: Container(color: tailLightRed)),
            ]),
          ),
        );
    return Row(mainAxisSize: MainAxisSize.min, spacing: w / 3, children: [bar(), bar(), bar()]);
  }
}

/// A section heading in the display face.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.size = 34});
  final String text;
  final double size;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(text, style: display(context, size)),
      );
}

/// A page's top banner: the display title over the paper colour, with two Le Mans stripes at the right.
class StripesHeader extends StatelessWidget {
  const StripesHeader({super.key, required this.title, this.child, this.titleSize = 48, this.lights = false});
  final String title;
  final Widget? child;
  final double titleSize;
  final bool lights;

  @override
  Widget build(BuildContext context) {
    final club = Club.of(context);
    const stripe = 18.0, gap = 6.0, edge = 16.0;
    return Container(
      decoration: BoxDecoration(
        color: club.paper,
        border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
      ),
      child: Stack(children: [
        Positioned(top: 0, bottom: 0, right: edge, width: stripe, child: ColoredBox(color: club.stripe)),
        Positioned(top: 0, bottom: 0, right: edge + stripe + gap, width: stripe, child: ColoredBox(color: club.stripe)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, edge + stripe * 2 + gap + 20, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (lights) ...[const TailLights(height: 26), const SizedBox(height: 12)],
            Text(title, style: display(context, titleSize)),
            if (child != null) ...[const SizedBox(height: 14), child!],
          ]),
        ),
      ]),
    );
  }
}

/// The small "last checked" note under a list.
class CheckedNote extends StatelessWidget {
  const CheckedNote(this.what, this.date, {super.key});
  final String what;
  final DateTime? date;

  @override
  Widget build(BuildContext context) => date == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text('$what last checked against mocgb.net on ${fullDate(date!)}.',
              style: TextStyle(fontSize: 13, color: Club.of(context).chrome)),
        );
}

/// "Copy" for an email address: many phones have no mail app set up, so mailto: links do nothing.
class CopyButton extends StatelessWidget {
  const CopyButton(this.email, {super.key});
  final String email;

  @override
  Widget build(BuildContext context) => IconButton(
        icon: const Icon(Icons.copy_rounded, size: 20),
        tooltip: 'Copy $email',
        onPressed: () async {
          await Clipboard.setData(ClipboardData(text: email));
          if (context.mounted) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text('$email copied'), behavior: SnackBarBehavior.floating));
          }
        },
      );
}

/// Opens a link outside the app (browser, mail, maps or calendar).
Future<void> open(Object url) =>
    launchUrl(url is Uri ? url : Uri.parse(url as String), mode: LaunchMode.externalApplication);

bool get _isApple => defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS;

/// Directions to a place: Apple Maps on Apple devices, Google Maps elsewhere (as on the site).
Uri mapsUrl(String place) {
  final q = Uri.encodeComponent(place);
  return Uri.parse(_isApple ? 'https://maps.apple.com/?daddr=$q' : 'https://www.google.com/maps/dir/?api=1&destination=$q');
}

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String fullDate(DateTime t) => '${t.day} ${_months[t.month - 1]} ${t.year}';

String dateRange(DateTime start, DateTime end) {
  if (start == end) return fullDate(start);
  if (start.year == end.year && start.month == end.month) return '${start.day}–${fullDate(end)}';
  return '${fullDate(start)} – ${fullDate(end)}';
}
