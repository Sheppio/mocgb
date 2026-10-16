// Service worker: makes the site installable and keeps the last-seen version available offline.
// Pages, styles, scripts and data are network-first, so members always get the latest when online.
// Images and fonts show the saved copy straight away and fetch the latest in the background for next time.
const CACHE = "mocgb-v5";
const CORE = [
  "/",
  "/styles.css",
  "/app.js",
  "/pwa.js",
  "/theme.js",
  "/data/events.json",
  "/data/areas.json",
  "/manifest.webmanifest",
  "/icons/icon-192.png",
  "/fonts/archivo-latin.woff2",
];

self.addEventListener("install", (event) => {
  event.waitUntil(caches.open(CACHE).then((cache) => cache.addAll(CORE)).then(() => self.skipWaiting()));
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener("fetch", (event) => {
  const { request } = event;
  const url = new URL(request.url);
  // Leave other sites (postcode lookup, fonts, mocgb.net) to the browser
  if (request.method !== "GET" || url.origin !== self.location.origin) return;
  // The Flutter app at /app/ handles its own loading and caching
  if (url.pathname.startsWith("/app/")) return;

  // Images and fonts: stale-while-revalidate
  if (request.destination === "image" || request.destination === "font") {
    const fresh = fetch(request).then((res) => store(request, res));
    event.waitUntil(fresh.catch(() => {}));
    event.respondWith(caches.match(request).then((hit) => hit || fresh));
    return;
  }

  event.respondWith(
    fetch(request)
      .then((res) => store(request, res))
      .catch(async () => (await caches.match(request)) ||
        (request.mode === "navigate" ? caches.match("/") : Response.error()))
  );
});

function store(request, res) {
  if (res.ok && !res.redirected) {
    const copy = res.clone();
    caches.open(CACHE).then((cache) => cache.put(request, copy));
  }
  return res;
}
