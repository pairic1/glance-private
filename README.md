# glance-private

Static images for Glance private apps.

| App | Private-app URL | Width | Refresh |
|---|---|---|---|
| Arcade basketball (`arcade-basketball.png`) | `http://glance-private.pairic-labs.workers.dev/` | 64 | 1 hour |
| Deep Freeze 250 Club (`deep-freeze/`) | `http://glance-private.pairic-labs.workers.dev/deep-freeze` | 64 | 1 minute |

**Deep Freeze has two frames** — the snowflake-with-medal and the member list —
and the Worker alternates them by clock time, one per panel refresh. The
rotation window must *equal* the panel's refresh: at the default it is one
minute. For any other refresh, add it in seconds, e.g. a 5-minute refresh is
`/deep-freeze?every=300`. (A refresh twice the window lands every fetch on the
same frame forever.) `?frame=1` / `?frame=2` pin a frame for checking.

## Why there is a Worker

Glance panels fetch private-app images over **plain `http` only**, and don't
follow redirects. GitHub's raw URLs — like every CDN and `pages.dev` — answer
plain http with a 301 to https, so the panel gets nothing. `cloudflare/` is a
tiny Worker on `workers.dev`, which *does* answer plain http; it relays the PNG
from this repo, so it never needs redeploying when the image changes.

Redeploy only if the Worker itself changes:

```bash
cd cloudflare && npx wrangler deploy
```

Rendered from `arcade-basketball-high-score` in the Glance Developer Network
catalog (submitted as glance-led-dev/glance-dev-network#617) — same `app.star`,
so it is pixel-identical to the catalog version.

Adding a Deep Freeze member: append them to `members` in
`deep-freeze/manifest.yaml`, then `deep-freeze/update.sh`.

When an arcade record falls:

```bash
./update.sh "NAME" SCORE
```

It re-renders and pushes; the Worker serves the new image within ~10 minutes
(5 min at GitHub's CDN, 5 at the Worker's edge cache), and the panel shows it
on its next refresh after that.

Needs `../glance-dev-network` checked out beside this folder with its `.venv`.
