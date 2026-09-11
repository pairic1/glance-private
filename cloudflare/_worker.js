// Glance private app: serve the arcade basketball board over plain HTTP.
//
// Glance panels fetch private-app images over http only, and GitHub -- like
// every static host tried, Cloudflare Pages' own static serving included --
// answers plain http with a 301 to https, which the panel does not follow.
// A Pages project with a _worker.js answers each request itself, http
// included, so this relays the PNG from GitHub instead of serving a file.
//
// That also means this never needs redeploying: updating the board is still
// ./update.sh -> git push, and the next fetch picks up the new image.
const SOURCE =
  "https://raw.githubusercontent.com/pairic1/glance-private/main/arcade-basketball.png";

export default {
  async fetch() {
    // Edge-cached for 5 minutes -- the panel refreshes hourly, so GitHub sees
    // a handful of requests a day and a brief GitHub hiccup is absorbed here.
    const upstream = await fetch(SOURCE, {
      cf: { cacheTtl: 300, cacheEverything: true },
    });
    if (!upstream.ok) {
      return new Response("upstream " + upstream.status, { status: 502 });
    }
    return new Response(upstream.body, {
      headers: {
        "content-type": "image/png",
        "cache-control": "public, max-age=300",
      },
    });
  },
};
