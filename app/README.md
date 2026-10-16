# MOCGB app

The Flutter app: the members' hub (next event, area meetings, contacts, joining, club links), with the same content as the website. It reads the site's `data/events.json` and `data/areas.json`, so the two always agree.

The web build is served at `/app/` next to the HTML site: https://mocgb.helloshep.com/app/ and https://dev.mocgb.helloshep.com/app/. See [docs/deploying.md](../docs/deploying.md).

## Running it

- Web, as hosted: `npm run build && npm start` in the repo root, then open http://localhost:8765/app/
- While developing: `flutter run -d chrome` in `app/`. Data then comes from the live site, because the app isn't on the site's host.
- Phones: `flutter run` with a simulator or device connected. Phone builds read data from https://mocgb.helloshep.com.

## Trying other devices

[device_preview](https://pub.dev/packages/device_preview) is built in. The phone icon in the app bar shows the app as another phone or tablet (in its frame), in landscape, or with 200% text. It works in debug and profile builds: locally and on the dev and branch Previews. Production is a release build, so the menu never appears there.
