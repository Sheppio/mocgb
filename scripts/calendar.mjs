// Writes website/calendar/<id>.ics for every event in website/data/events.json, for "Add to calendar".
// Run after editing events: npm run calendar
import fs from "node:fs";

const root = new URL("..", import.meta.url).pathname;
const { events } = JSON.parse(fs.readFileSync(`${root}website/data/events.json`, "utf8"));
const outDir = `${root}website/calendar`;
fs.rmSync(outDir, { recursive: true, force: true });
fs.mkdirSync(outDir, { recursive: true });

const ymd = (iso) => iso.replaceAll("-", "");
const dayAfter = (iso) => {
  const d = new Date(iso + "T12:00:00Z");
  d.setUTCDate(d.getUTCDate() + 1);
  return d.toISOString().slice(0, 10);
};
// RFC 5545 text escaping, and folding of lines longer than 75 octets
const esc = (s) => String(s).replace(/\\/g, "\\\\").replace(/;/g, "\\;").replace(/,/g, "\\,").replace(/\n/g, "\\n");
const fold = (line) => {
  const out = [];
  let rest = Buffer.from(line, "utf8");
  while (rest.length > 75) {
    let cut = 75;
    while ((rest[cut] & 0xc0) === 0x80) cut--; // don't split a UTF-8 character
    out.push(rest.subarray(0, cut).toString("utf8"));
    rest = Buffer.concat([Buffer.from(" "), rest.subarray(cut)]);
  }
  out.push(rest.toString("utf8"));
  return out.join("\r\n");
};

const stamp = new Date().toISOString().replace(/[-:]/g, "").replace(/\.\d+Z$/, "Z");
for (const e of events) {
  const description = [e.note, `Details: ${e.url}`].filter(Boolean).join("\n");
  const lines = [
    "BEGIN:VCALENDAR",
    "VERSION:2.0",
    "PRODID:-//MOCGB//Events//EN",
    "CALSCALE:GREGORIAN",
    "METHOD:PUBLISH",
    "BEGIN:VEVENT",
    `UID:${e.id}@mocgb.helloshep.com`,
    `DTSTAMP:${stamp}`,
    // All-day event: DTEND is the day after the last day
    `DTSTART;VALUE=DATE:${ymd(e.start)}`,
    `DTEND;VALUE=DATE:${ymd(dayAfter(e.end || e.start))}`,
    `SUMMARY:${esc(e.title)}`,
    `LOCATION:${esc(e.map || e.location)}`,
    `DESCRIPTION:${esc(description)}`,
    `URL:${e.url}`,
    "END:VEVENT",
    "END:VCALENDAR",
  ];
  fs.writeFileSync(`${outDir}/${e.id}.ics`, lines.map(fold).join("\r\n") + "\r\n");
}
console.log(`Wrote ${events.length} calendar files to website/calendar/`);
