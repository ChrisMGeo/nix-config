# chrismg/quickshell

The QML files for the Quickshell bar of the user `chrismg`. These files are not Nix modules, so the loader does not read them. `../quickshell.nix` copies this folder to `~/.config/quickshell/chrismg` and adds a generated `Theme.qml`.

## Files

| File | What it does |
| --- | --- |
| `shell.qml` | The entry point. Follows niri workspaces and windows through `niri msg -j event-stream`, and tracks the media player and widget positions. Places every panel, with one bar per monitor that shows only that monitor's workspaces. Decides when each bar shows: while pinned with Mod+B through the `bar` IPC target, while the niri overview is open, for 1.5 seconds after a workspace change on that monitor, and while the settings drawer or power menu is open. |
| `qmldir` | Lists the components in this folder and marks the singletons. |
| `TopBar.qml` | The bar at the top of the screen, drawn as two separate panels: the workspaces on the left, and on the right the audio visualizer, the time, the tray button, the system usage gauges, and the settings and power buttons. The tray button shows even when no program has a tray icon. It floats over windows without taking space, and stays hidden until shown. Touching the top edge of the screen with the mouse shows it. |
| `TrayMenu.qml` | The drop-down under the bar's tray button, with one row per tray icon, or "No tray icons" when there are none. Left click activates a program, middle click runs its second action, and right click opens its own menu. |
| `PowerMenu.qml` | The menu under the power button: lock, log out, restart, and shut down. Lock acts at once. The others need a second click within 3 seconds. |
| `SettingsDrawer.qml` | The drawer that opens from the bar: network, Bluetooth, audio, and power. |
| `WifiNetworks.qml` | The open Wi-Fi section of the settings drawer. Lists the networks in range and joins one on click. Asks for a password, or for a username and password on enterprise networks, under the row of a new secured network. Has buttons to rescan, disconnect, and forget a saved network, and shows why a join failed. |
| `BluetoothDevices.qml` | The open Bluetooth section of the settings drawer. Lists paired devices with Connect and Disconnect buttons. Scan lists nearby devices, and Pair pairs, trusts, and connects one. Scanning stops after a minute or when the drawer closes. |
| `SettingsSection.qml` | One expandable row in the settings drawer. |
| `Capabilities.qml` | Singleton. Checks whether power-profiles-daemon is running. |
| `SystemUsage.qml` | Singleton. Reads CPU, memory, and GPU use from the script in `../quickshell.nix`. |
| `UsageGauge.qml` | One gauge in the bar, such as CPU or RAM. |
| `AudioSpectrum.qml` | Singleton. Runs cava and reads the bar heights. |
| `cava.conf` | Settings for cava: PipeWire input and raw output for `AudioSpectrum.qml` to read. `@bars@` is filled in by `../quickshell.nix`. |
| `AudioVisualizer.qml` | Draws the audio bars. |
| `ClockCard.qml` | The clock widget on the desktop. |
| `MediaCard.qml` | The now-playing widget, shown while media plays. |
| `DraggablePanel.qml` | A desktop widget that you can drag. Saves its position. |
| `IconButton.qml` | A round button with one icon. |
| `TextButton.qml` | A small rounded button with a word on it, such as "Join". |
| `UiText.qml` | Text in the theme font and color. |

## Rules

- `Theme.qml` is generated. Change colors, sizes, and fonts in `../quickshell.nix`, not here.
- Change the number of visualizer bars with `spectrumBars` in `../quickshell.nix`. It fills in both `cava.conf` and `Theme.qml`.
- Quickshell comes from nixpkgs-unstable, because 0.3.0 crashes when a Wi-Fi access point disappears. See `programs.quickshell.package` in `../quickshell.nix`.
- `Theme.showBattery` is true only when `machine.formFactor` is "laptop". Hide any laptop-only control behind it.
- When you add a QML file, list it in `qmldir` too.
- `Theme.panel` is see-through. A new window that draws it needs a `BackgroundEffect.blurRegion` that covers the panel with the same corner radius, or it looks dim instead of frosted. The blur shows only where that region is.
- The bar supports niri only. It reads workspaces and windows with `niri msg` and has no code for other compositors.

## Keeping this file current

When you change the files in this folder, update this file in the same change. If you add a subdirectory, give it an AGENTS.md and link it under Subdirectories. If you remove one, delete its AGENTS.md and its link. The full rules are in the root `AGENTS.md`.
