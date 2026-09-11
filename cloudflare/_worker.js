// Glance private apps: serve PNGs over plain HTTP.
//
// Glance panels fetch private-app images over http only, and every host tried
// answers plain http with a 301 to https, which the panel does not follow:
// raw.githubusercontent.com, jsDelivr, Statically, githack -- and pages.dev,
// even with a _worker.js, because Pages upgrades to https at the edge before
// the worker runs. A plain Worker on workers.dev does not, so it answers the
// panel's http request itself and relays the PNGs from GitHub.
//
// That also means this never needs redeploying when an image changes:
// re-render, git push, and the next fetch picks it up.

const RAW = "https://raw.githubusercontent.com/pairic1/glance-private/main/";

// Path -> frames. A private app is one image, so an app with more to say than
// fits in 64x32 gets several frames and rotates through them, one per panel
// refresh. "/" stays the arcade board: it is the URL that panel already has.
const APPS = {
  "/": ["arcade-basketball.png"],
  "/deep-freeze": ["deep-freeze/club.png", "deep-freeze/members.png"],
};

// Rotation is by the clock, not by counting requests: a Worker keeps no state
// between requests, and the panel fetches once per refresh anyway. The window
// has to EQUAL the panel's refresh -- if the refresh were two windows long,
// every fetch would land on the same frame forever. So ?every= carries the
// refresh in seconds, defaulting to one minute.
const DEFAULT_EVERY = 60;

export default {
  async fetch(request) {
    const url = new URL(request.url);
    const path = url.pathname.replace(/\/+$/, "") || "/";
    const frames = APPS[path];
    if (!frames) {
      return new Response("no such app", { status: 404 });
    }

    let i = 0;
    if (frames.length > 1) {
      const pinned = parseInt(url.searchParams.get("frame") || "", 10);
      if (pinned >= 1 && pinned <= frames.length) {
        i = pinned - 1; // ?frame=2 pins one frame, for checking a render
      } else {
        const every = Math.max(30, parseInt(url.searchParams.get("every") || "", 10) || DEFAULT_EVERY);
        i = Math.floor(Date.now() / 1000 / every) % frames.length;
      }
    }

    // Edge-cached for 5 minutes, so GitHub sees a handful of requests a day
    // and a brief GitHub hiccup is absorbed here.
    const upstream = await fetch(RAW + frames[i], {
      cf: { cacheTtl: 300, cacheEverything: true },
    });
    if (!upstream.ok) {
      return new Response("upstream " + upstream.status, { status: 502 });
    }
    return new Response(upstream.body, {
      headers: {
        "content-type": "image/png",
        // A rotating URL must not be cached on the way to the panel, or the
        // next refresh would get the same frame back.
        "cache-control": frames.length > 1 ? "no-store" : "public, max-age=300",
      },
    });
  },
};
