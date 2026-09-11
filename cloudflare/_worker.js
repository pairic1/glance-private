// Glance private app: serve the arcade basketball board over plain HTTP.
//
// Glance panels fetch private-app images over http only, and every host tried
// answers plain http with a 301 to https, which the panel does not follow:
// raw.githubusercontent.com, jsDelivr, Statically, githack -- and pages.dev,
// even with a _worker.js, because Pages upgrades to https at the edge before
// the worker runs. A plain Worker on workers.dev does not, so it answers the
// panel's http request itself and relays the PNG from GitHub.
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
