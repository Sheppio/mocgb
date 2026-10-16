# MOCGB app

The Flutter app: the members' hub (next event, area meetings, contacts, joining, club links), with the same content as the website. It reads the site's `data/events.json` and `data/areas.json`, so the two always agree.

The web build is served at `/app/` next to the HTML site: https://mocgb.helloshep.com/app/ and https://dev.mocgb.helloshep.com/app/. See [docs/deploying.md](../docs/deploying.md).

## Running it

- Web, as hosted: `npm run build && npm start` in the repo root, then open http://localhost:8765/app/
- With the real headers (WebAssembly multi-threading): `npm run build && npx wrangler dev`, then http://localhost:8787/app/
- While developing: `flutter run -d chrome` in `app/` (data loads only when the site's files are on the same host, so the web build above is the better check).
- Phones: `flutter run` with a simulator or device connected. Phone builds read data from https://mocgb.helloshep.com.

## Look

Five tabs along the bottom: Home, Events, Meetings, Contact, More. Colours, the Archivo font (`assets/fonts`), tail lights and racing stripes come from the website. The splash screen and app icons are generated from `assets/icon/` by `dart run flutter_native_splash:create` and `dart run flutter_launcher_icons` (settings in `pubspec.yaml`).

## Installing the web app

The web app installs on its own, as "MOCGB App" (`web/manifest.json`: id and scope `/app/`), separately from the HTML site. The **Install** button in the top bar appears when the browser offers to install (Chrome, Edge, Android). On iPhone and iPad it explains Share → Add to Home Screen. It's hidden once the app is installed. `web/index.html` catches the browser's offer before Flutter starts, and `lib/install_web.dart` uses it. The icon and splash generators also edit `web/index.html` and `web/manifest.json`, so check those after running them.

## Trying other devices

[device_preview](https://pub.dev/packages/device_preview) is built in. The phone icon in the app bar shows the app as another phone or tablet (in its frame), in landscape, or with 200% text. It works in debug and profile builds: locally and on the dev and branch Previews. Production is a release build, so the menu never appears there.
