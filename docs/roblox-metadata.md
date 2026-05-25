# Roblox metadata automation

This project can export and update Roblox experience metadata through Roblox Open Cloud.

## One-time setup

1. Open Creator Dashboard and create an Open Cloud API key.
2. Give the key access to experience `10205453994`.
3. Add these permissions where available:
   - `universe:read`
   - `universe.place:write`
   - `universe-places:write`
   - `asset:read`
   - `asset:write`
   - `developer-product:read`
   - `developer-product:write`
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
