# glance-private

Static images for Glance private apps.

| Image | Private-app URL | Width |
|---|---|---|
| `arcade-basketball.png` | `http://glance-private.pairic-labs.workers.dev/` | 64 |

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

When a record falls:

```bash
./update.sh "NAME" SCORE
```

It re-renders and pushes; the Worker serves the new image within ~10 minutes
(5 min at GitHub's CDN, 5 at the Worker's edge cache), and the panel shows it
on its next refresh after that.

Needs `../glance-dev-network` checked out beside this folder with its `.venv`.
