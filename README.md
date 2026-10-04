# Life Grid

[![Roblox Build](https://github.com/ch3pasov/roblox-game-of-life/actions/workflows/roblox-deploy.yml/badge.svg)](https://github.com/ch3pasov/roblox-game-of-life/actions/workflows/roblox-deploy.yml)

A touch-first Conway's Game of Life built as a Roblox experience.

[Play Life Grid on Roblox](https://www.roblox.com/games/125341913379113/Life-Grid) · [View the build workflow](https://github.com/ch3pasov/roblox-game-of-life/actions/workflows/roblox-deploy.yml)

Life Grid turns a 64×64 cellular automaton into a mobile-friendly Roblox interface. Players can draw directly on the board, pan and zoom, place classic patterns, and watch each generation evolve.

## Features

- Start, pause, or advance the simulation one generation at a time.
- Clear the board, randomize it, or cycle through classic starting patterns.
- Switch between slow, normal, and fast simulation speeds.
- Pan and zoom a large scrolling board with mouse or touch controls.
- Use a portrait-first layout on phones, with responsive desktop support.
- Automatically select the English or Russian interface from the Roblox locale.
- Process optional Robux donations with Developer Products and show shared progress from DataStore.

## How it is built

The simulation and interface live in one client-side Luau module. Server code validates donation receipts and stores the aggregate donation total. Rojo maps the source tree into a Roblox place, while Node.js scripts handle Open Cloud metadata, Developer Products, DataStore reads, and place publishing.

```text
src/ReplicatedFirst/       simulation and interface
src/ServerScriptService/   server bootstrap and receipt processing
metadata/                  desired Roblox experience settings
scripts/                   build, metadata, product, and deployment tools
default.project.json       Rojo project map
```

## Run in Roblox Studio

1. Open or create an empty place in Roblox Studio.
2. Start Rojo from this repository:

   ```sh
   rojo serve
   ```

3. Connect with the Rojo Studio plugin.
4. Press **Play**.

To build a place file without publishing it:

```sh
node scripts/roblox-publish.mjs build
```

## Deployment

The GitHub Actions workflow runs for pull requests and pushes to `main`. It checks the Node.js scripts, installs Rojo, validates the project map, builds a `.rbxl` place, and uploads it as an artifact.

CI uses the pinned Rojo 7.7.1 Linux x86_64 release. `scripts/install-rojo.sh`
checks the archive's fixed SHA-256 before extraction and adds it to the runner
path only after installation succeeds. Updating Rojo requires reviewing both the
release version and digest against the official `rojo-rbx/rojo` release.

Installer checks run offline with synthetic downloads and controlled command
stubs, without a Roblox API key:

```sh
node --test scripts/test-install-rojo.mjs
```

Deployment is deliberately manual: a manually dispatched workflow run can synchronize supported experience metadata and Developer Products, then publish through Roblox Open Cloud. Builds and checks do not need an API key.

Authenticated commands read `ROBLOX_API_KEY` from a local `.env` file or an optional GitHub Actions secret. Start from `.env.example`; `.env` itself is ignored and must not be committed.

```sh
node scripts/roblox-metadata.mjs export
node scripts/roblox-metadata.mjs apply
node scripts/roblox-donation-product.mjs ensure
node scripts/roblox-donation-total.mjs
node scripts/roblox-publish.mjs deploy
```

More details about the Open Cloud setup are in [`docs/roblox-metadata.md`](docs/roblox-metadata.md).
