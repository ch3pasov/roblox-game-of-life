# Roblox metadata automation

This project can export and update Roblox experience metadata through Roblox Open Cloud.

## One-time setup

1. Open Creator Dashboard and create an Open Cloud API key.
2. Give the key access to experience `10205453994`.
3. Add these permissions where available:
   - `universe:read`
   - `universe:write`
   - `universe.place:write`
   - `universe-places:write`
   - `asset:read`
   - `asset:write`
   - `developer-product:read`
   - `developer-product:write`
   - `universe-datastores.objects:read`
4. Copy `.env.example` to `.env`.
5. Put the key into `.env` as `ROBLOX_API_KEY=...`.

Do not commit `.env`.

## Export current settings

```sh
node scripts/roblox-metadata.mjs export
```

The export is written to `metadata/exported/<timestamp>/`. This command only reads data.

## Update metadata

Edit `metadata/roblox-metadata.json`, then run:

```sh
node scripts/roblox-metadata.mjs apply
```

The apply command exports a backup first, then updates only fields that are filled in:

- `displayName`
- `description`
- `iconPath`
- `thumbnails`

For display name and description, set `placeId` to the root place ID. If it is empty, run export first and look in the exported places file.

Example thumbnail entry:

```json
{
  "path": "metadata/assets/thumbnail-1.png",
  "altText": "Conway's Game of Life grid in Roblox"
}
```

## Publish place

Build only:

```sh
node scripts/roblox-publish.mjs build
```

Build and publish:

```sh
node scripts/roblox-publish.mjs deploy
```

## Developer product

Check the donation product:

```sh
node scripts/roblox-donation-product.mjs get
```

Create or repair the donation product settings:

```sh
node scripts/roblox-donation-product.mjs ensure
```

Shared Roblox Open Cloud helpers live in `scripts/lib/roblox-open-cloud.mjs`.

## GitHub Actions

The repository includes `.github/workflows/roblox-deploy.yml`.

The workflow runs on pull requests and pushes to `main`, and it can also be started manually. On every run it:

- installs Rojo;
- checks the Node.js scripts;
- runs `rojo sourcemap`;
- builds `build/game-of-life.rbxl`;
- uploads the place file as an artifact.

On a manually dispatched run, if the repository secret `ROBLOX_API_KEY` is present, it also:

- applies Roblox metadata;
- ensures donation products;
- publishes the built place.

Create the secret in GitHub:

`Settings -> Secrets and variables -> Actions -> New repository secret`

Use the same key permissions listed above.

## Donation total

Read the current donation total from DataStore:

```sh
node scripts/roblox-donation-total.mjs
```

This command needs the `universe-datastores.objects:read` Open Cloud scope.
