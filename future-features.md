# Future Features

## Done

- ~~Disable social runtime UI: default Roblox chat and default voice setup are disabled from the client script.~~
- ~~Fix field movement in Move mode: mouse drag now pans the board.~~
- ~~Make Draw the default mode at game start.~~
- ~~Prevent overlay controls from painting cells underneath them in Draw mode.~~
- ~~Confirm Roblox CI deploy publishes the place.~~ Verified by GitHub Actions run `26531308161`; Roblox published version `23`.
- ~~Confirm root place server size is 2.~~ Verified by GitHub Actions run `26531308161`; `Apply Roblox metadata` reported `Updated root place settings.`

## Needs Roblox dashboard/API access

- Disable Voice Chat at the universe level through CI. Current GitHub Actions secret `ROBLOX_API_KEY` can publish the place and update root place settings, but Roblox rejected universe settings with `PERMISSION_DENIED`: the key is missing `universe:write`. Add `universe:write` to the Roblox Open Cloud API key, update the GitHub secret, then rerun `Roblox Deploy`.
- Disable Camera in Creator Dashboard manually. The project tracks the desired value as `experienceSettings.dashboardOnly.cameraEnabled: false`, but the current Open Cloud sync does not support applying this field.
