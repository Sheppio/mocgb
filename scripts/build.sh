#!/bin/sh
# Builds the Flutter app for the web into website/app/, served at /app/ next to the HTML site.
# Uses flutter from the PATH if there is one; otherwise (as on Workers Builds) it clones the pinned
# Flutter version into .cache/flutter first. Keep FLUTTER_VERSION in step with the local Flutter.
set -e
cd "$(dirname "$0")/.."
FLUTTER_VERSION=3.47.7

if command -v flutter >/dev/null 2>&1; then
  FLUTTER=flutter
else
  SDK=.cache/flutter
  if [ "$(cat .cache/flutter-version 2>/dev/null)" != "$FLUTTER_VERSION" ]; then
    rm -rf "$SDK"
    git clone --quiet --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$SDK"
    echo "$FLUTTER_VERSION" > .cache/flutter-version
  fi
  FLUTTER="$PWD/$SDK/bin/flutter"
  "$FLUTTER" config --no-analytics >/dev/null
fi

rm -rf website/app
cd app
"$FLUTTER" --version
"$FLUTTER" pub get
# Production is a release build. Everything else (local, dev and branch Previews) is a profile build,
# so the device_preview menu works there. Workers Builds sets WORKERS_CI_BRANCH.
if [ "$WORKERS_CI_BRANCH" = prod ]; then MODE=--release; else MODE=--profile; fi
"$FLUTTER" build web $MODE --base-href /app/ --output ../website/app
echo "Wrote website/app"
