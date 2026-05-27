# Future Features

## Done locally, needs Roblox/manual verification

- Disable social runtime UI: default Roblox chat and default voice setup are disabled from the client script.
- Fix field movement in Move mode: mouse drag now pans the board.
- Make Draw the default mode at game start.
- Prevent overlay controls from painting cells underneath them in Draw mode.

## Needs platform/API verification

- Confirm Roblox dashboard settings after CI deploy:
  - Voice Chat should be disabled.
  - Camera should be disabled if Roblox Open Cloud exposes a supported field for it.
  - Server size should be 2.
