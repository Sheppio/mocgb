// Home page behaviour: next event, and the nearest-meeting finder.
// Data comes from data/*.json for now; the backend can serve the same shapes later.

const $ = (id) => document.getElementById(id);

function el(tag, props = {}, ...children) {
  const node = Object.assign(document.createElement(tag), props);
  node.append(...children.filter((c) => c != null && c !== false));
  return node;
}

// Opens Apple Maps on iPhone/iPad and Google Maps elsewhere, with directions to the place
const isApple = /iPad|iPhone|iPod/.test(navigator.userAgent) ||
  (navigator.platform === "MacIntel" && navigator.maxTouchPoints > 1);
function mapsUrl(place) {
  const q = encodeURIComponent(place);
  return isApple ? `https://maps.apple.com/?daddr=${q}` : `https://www.google.com/maps/dir/?api=1&destination=${q}`;
}

const checkedFmt = new Intl.DateTimeFormat("en-GB", { day: "numeric", month: "short", year: "numeric" });
function showChecked(id, what, iso) {
  const node = $(id);
  if (node && iso) node.textContent = `${what} last checked against mocgb.net on ${checkedFmt.format(new Date(iso + "T12:00:00"))}.`;
}

/* ---------- Copy email address ---------- */

// Many phones have no mail app set up, so a mailto: link does nothing. Offer to copy the address instead.
const canCopy = !!navigator.clipboard?.writeText;
function copyButton(email) {
  if (!canCopy) return null;
  const button = el("button", { type: "button", className: "copy-button", textContent: "Copy" });
  button.setAttribute("aria-label", `Copy ${email}`);
  button.addEventListener("click", async () => {
    try {
      await navigator.clipboard.writeText(email);
      button.textContent = "Copied";
      button.dataset.copied = "";
      $("copy-status").textContent = `${email} copied`;
      setTimeout(() => { button.textContent = "Copy"; delete button.dataset.copied; }, 2500);
    } catch {
      $("copy-status").textContent = "Couldn't copy. Press and hold the address to copy it instead.";
    }
  });
  return button;
}

async function getJSON(url) {
  const res = await fetch(url);
  if (!res.ok) throw new Error(`${url}: ${res.status}`);
  return res.json();
}

/* ---------- Events ---------- */

const dayFmt = new Intl.DateTimeFormat("en-GB", { day: "numeric" });
const fullFmt = new Intl.DateTimeFormat("en-GB", { day: "numeric", month: "short", year: "numeric" });
const toDate = (iso) => new Date(iso + "T12:00:00");

function dateRange(start, end) {
  const s = toDate(start);
  if (!end || end === start) return fullFmt.format(s);
  const e = toDate(end);
  const sameMonth = s.getMonth() === e.getMonth() && s.getFullYear() === e.getFullYear();
  return sameMonth ? `${dayFmt.format(s)}–${fullFmt.format(e)}` : `${fullFmt.format(s)} – ${fullFmt.format(e)}`;
}

function eventTime(e) {
  return el("time", { dateTime: e.start, textContent: dateRange(e.start, e.end) });
}

// Safe to call again: it rebuilds the section, and a failed refresh leaves what's already shown.
async function loadEvents({ refresh = false } = {}) {
  const box = $("next-event");
  const list = $("more-events");
  // Today in the visitor's own time zone (toISOString would give the UTC date, a day behind after midnight in summer)
  const now = new Date();
  const today = [now.getFullYear(), now.getMonth() + 1, now.getDate()].map((n) => String(n).padStart(2, "0")).join("-");
  let events = [];
  try {
    const data = await getJSON("/data/events.json");
    showChecked("events-checked", "Event details", data.checked);
    events = data.events
      .filter((e) => (e.end || e.start) >= today)
      .sort((a, b) => a.start.localeCompare(b.start));
  } catch (err) {
    console.error(err);
    if (!refresh) box.replaceChildren(el("p", { className: "empty", textContent: "Events couldn't be loaded. See the full list on mocgb.net." }));
    return;
  }

  list.hidden = true;
  $("more-events-title").hidden = true;
  if (!events.length) {
    box.replaceChildren(el("p", { className: "empty", textContent: "No events are listed right now. Check mocgb.net for new dates." }));
    return;
  }

  const [next, ...rest] = events;
  box.replaceChildren(
    el("img", { src: next.logo, alt: "", loading: "eager", className: "next-event-img" }),
    el("div", { className: "next-event-body" },
      eventTime(next),
      el("h3", { textContent: next.title }),
      el("p", { className: "event-location", textContent: next.location }),
      next.note && el("p", { className: "event-note", textContent: next.note }),
      el("div", { className: "event-actions" },
        el("a", { className: "button", href: next.url, textContent: "Event details" }),
        el("a", { className: "text-link", href: `/calendar/${next.id}.ics`, textContent: "Add to calendar" }),
        next.map && el("a", { className: "text-link", href: mapsUrl(next.map), textContent: "Directions" })
      )
    )
  );

  if (rest.length) {
    list.replaceChildren(...rest.map((e) =>
      el("li", { className: "event" },
        el("img", { src: e.logo, alt: "", width: 64, height: 64, loading: "lazy" }),
        el("div", {},
          el("h4", {}, el("a", { href: e.url, textContent: e.title })),
          el("p", { className: "event-location", textContent: e.location })
        ),
        eventTime(e),
        el("p", { className: "event-links" },
          el("a", { className: "text-link", href: `/calendar/${e.id}.ics`, textContent: "Add to calendar" }),
          e.map && el("a", { className: "text-link", href: mapsUrl(e.map), textContent: "Directions" })
        )
      )
    ));
    list.hidden = false;
    $("more-events-title").hidden = false;
  }
}

/* ---------- Area meetings ---------- */

let areas = [];
let lastSearch = null;   // { lat, lng, label } of the most recent nearest-meeting search

function miles(lat1, lng1, lat2, lng2) {
  const r = (d) => (d * Math.PI) / 180;
  const a = Math.sin(r(lat2 - lat1) / 2) ** 2 +
    Math.cos(r(lat1)) * Math.cos(r(lat2)) * Math.sin(r(lng2 - lng1) / 2) ** 2;
  return 3958.8 * 2 * Math.asin(Math.sqrt(a));
}

function areaItem(a, distance) {
  const where = a.venue
    ? (a.postcode ? `${a.venue}, ${a.postcode}` : a.venue)
    : "Venue not listed. Ask the area contact.";
  return el("li", { className: "area" },
    el("div", { className: "area-head" },
      el("h3", { textContent: a.name }),
      distance != null && el("span", { className: "distance", textContent: `${Math.round(distance)} miles` })
    ),
    el("p", { className: "area-where", textContent: where }),
    a.when && el("p", { className: "area-when", textContent: a.when }),
    el("p", { className: "area-links" },
      a.postcode && el("a", { href: mapsUrl(`${a.venue}, ${a.postcode}`), textContent: "Directions" }),
      el("a", { href: `mailto:${a.email}`, textContent: `Email ${a.contact}` }),
      copyButton(a.email),
      el("a", { href: a.facebook, textContent: "Facebook group" })
    )
  );
}

function showNearest(lat, lng, label, { scroll = true } = {}) {
  lastSearch = { lat, lng, label };
  if (!areas.length) {
    $("finder-status").textContent = "Meetings aren't loaded yet. Try again in a moment, or see the list on mocgb.net.";
    return;
  }
  const ranked = areas
    .filter((a) => a.lat != null)
    .map((a) => ({ a, d: miles(lat, lng, a.lat, a.lng) }))
    .sort((x, y) => x.d - y.d)
    .slice(0, 3);
  const list = $("nearest-areas");
  list.replaceChildren(...ranked.map(({ a, d }) => areaItem(a, a.approx ? null : d)));
  list.hidden = false;
  $("finder-status").textContent = `Closest areas to ${label}. Distances are in a straight line, not by road.`;
  if (scroll) list.scrollIntoView({ behavior: matchMedia("(prefers-reduced-motion: reduce)").matches ? "auto" : "smooth", block: "nearest" });
}

async function lookupPostcode(raw) {
  const pc = raw.trim().replace(/\s+/g, " ").toUpperCase();
  if (!pc) throw new Error("Enter a postcode, or just the first part like MK45.");
  // postcodes.io has no usable coordinates for the Crown Dependencies, so place them directly
  const island = { JE: [49.19, -2.11], GY: [49.45, -2.54], IM: [54.15, -4.48] }[pc.slice(0, 2)];
  if (island && /^(JE|GY|IM)\d/.test(pc)) return { lat: island[0], lng: island[1], label: pc };
  const inUK = (r) => r?.latitude >= 49 && r.latitude <= 61 && r.longitude >= -9 && r.longitude <= 2;
  // Full postcode first, then the outward part (e.g. "MK45") on its own
  for (const path of [`postcodes/${encodeURIComponent(pc)}`, `outcodes/${encodeURIComponent(pc.split(" ")[0])}`]) {
    const res = await fetch(`https://api.postcodes.io/${path}`);
    if (res.ok) {
      const { result } = await res.json();
      if (inUK(result)) return { lat: result.latitude, lng: result.longitude, label: pc };
    }
  }
  throw new Error(`We couldn't find ${pc}. Check it and try again.`);
}

// Safe to call again: a refresh redraws the area lists, including any search already shown.
async function loadAreas({ refresh = false } = {}) {
  try {
    const data = await getJSON("/data/areas.json");
    showChecked("areas-checked", "Meeting details", data.checked);
    areas = data.areas;
  } catch (err) {
    console.error(err);
    if (!refresh) $("finder-status").textContent = "Meetings couldn't be loaded. See the list on mocgb.net.";
    return;
  }
  $("all-areas").replaceChildren(...areas.map((a) => areaItem(a)));
  if (refresh && lastSearch) showNearest(lastSearch.lat, lastSearch.lng, lastSearch.label, { scroll: false });
}

function setUpFinder() {
  const status = $("finder-status");
  const locBtn = $("use-location");
  if (!("geolocation" in navigator)) locBtn.hidden = true;

  locBtn.addEventListener("click", () => {
    status.textContent = "Finding your location…";
    navigator.geolocation.getCurrentPosition(
      (pos) => showNearest(pos.coords.latitude, pos.coords.longitude, "your location"),
      () => { status.textContent = "Location isn't available. Enter a postcode instead."; $("postcode").focus(); },
      { maximumAge: 600000, timeout: 10000 }
    );
  });

  $("postcode-form").addEventListener("submit", async (ev) => {
    ev.preventDefault();
    status.textContent = "Looking up postcode…";
    try {
      const { lat, lng, label } = await lookupPostcode($("postcode").value);
      showNearest(lat, lng, label);
    } catch (err) {
      status.textContent = err instanceof TypeError
        ? "Postcode lookup isn't available right now. Try again, or browse all areas below."
        : err.message;
    }
  });
}

/* ---------- Start, and refresh when reopened ---------- */

// An installed app can sit suspended in the background for days. When it comes back
// after a while, quietly fetch the latest events and meetings without reloading the page.
const REFRESH_AFTER = 30 * 60 * 1000;
let loadedAt = Date.now();

document.addEventListener("visibilitychange", () => {
  if (document.visibilityState !== "visible" || Date.now() - loadedAt < REFRESH_AFTER) return;
  loadedAt = Date.now();
  loadEvents({ refresh: true });
  loadAreas({ refresh: true });
});

document.querySelectorAll(".contacts li").forEach((li) => {
  const email = li.querySelector('a[href^="mailto:"]')?.getAttribute("href").slice(7);
  const button = email && copyButton(email);
  if (button) li.append(button);
});

setUpFinder();
loadEvents();
loadAreas();
