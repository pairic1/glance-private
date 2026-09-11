# glance-private

Static images for Glance private apps. The panel fetches each PNG straight from
its raw URL, so these files *are* the apps.

| Image | Private-app URL | Width |
|---|---|---|
| `arcade-basketball.png` | `https://raw.githubusercontent.com/pairic1/glance-private/main/arcade-basketball.png` | 64 |

Rendered from `arcade-basketball-high-score` in the Glance Developer Network
catalog (submitted as glance-led-dev/glance-dev-network#617) — same `app.star`,
so it is pixel-identical to the catalog version.

When a record falls:

```bash
./update.sh "NAME" SCORE
```

Needs `../glance-dev-network` checked out beside this folder with its `.venv`.
