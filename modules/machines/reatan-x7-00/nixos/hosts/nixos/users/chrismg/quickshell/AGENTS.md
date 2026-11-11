# chrismg/quickshell

The QML files for the Quickshell bar of the user `chrismg`. These files are not Nix modules, so the loader does not read them. `../quickshell.nix` copies this folder to `~/.config/quickshell/chrismg` and adds a generated `Theme.qml`.

## Files

| File | What it does |
| --- | --- |
| `shell.qml` | The entry point. Follows niri workspaces and windows through `niri msg -j event-stream`, and tracks the media player. Places every panel, with one bar per monitor that shows only that monitor's workspaces. Opens and closes the activity monitor, from the gauges or from Ctrl+Shift+Escape through the `shell` IPC target, the clock window, with Mod+T through the same target, and the now-playing window. Decides when each bar shows: while pinned with Mod+B through the `bar` IPC target, while the niri overview is open, for 1.5 seconds after a workspace change on that monitor, and while the settings drawer or power menu is open. |
| `qmldir` | Lists the components in this folder and marks the singletons. |
| `TopBar.qml` | The bar at the top of the screen, drawn as two separate panels: the workspaces on the left, and on the right the audio visualizer, the time, the tray button, the system usage gauges, and the settings and power buttons. The tray button shows even when no program has a tray icon. It floats over windows without taking space, and stays hidden until shown. Touching the top edge of the screen with the mouse shows it. |
| `TrayMenu.qml` | The drop-down under the bar's tray button, with one row per tray icon, or "No tray icons" when there are none. Left click activates a program, middle click runs its second action, and right click opens its own menu. |
| `PowerMenu.qml` | The menu under the power button: lock, log out, restart, and shut down. Lock acts at once. The others need a second click within 3 seconds. |
| `SettingsDrawer.qml` | The drawer that opens from the bar: network, Bluetooth, audio, and power. The Wi-Fi row shows the name of the network it is on, and the Ethernet section shows the link speed. The Sound section has a button that opens the volume mixer beside the drawer. |
| `AudioOutputs.qml` | The list of audio outputs in the Sound section of the settings drawer. Monitor speakers are named after the monitor, not the graphics card. Clicking one makes it the default output and moves the playing sound to it. |
| `VolumeMixer.qml` | The volume mixer popup to the left of the settings drawer, opened from its Sound section. Has a volume slider and a mute button per program. Programs whose volume was set in it stay listed, dimmed, after they stop playing, with a button to forget them. |
| `AppVolumes.qml` | Singleton. Lists the programs playing sound for the volume mixer, sets their volume on all their streams, and remembers each volume set in the mixer in `app-volumes.json` in Quickshell's state folder. Sets the remembered volume on every new stream of that program, and keeps it current when the program changes its own volume. |
| `WifiNetworks.qml` | The open Wi-Fi section of the settings drawer. Lists the networks in range and joins one on click. Asks for a password, or for a username, server domain, and password on enterprise networks, under the row of a new secured network. The server domain is required so the join can check the server's certificate. Has buttons to rescan, disconnect, and forget a saved network, and shows why a join failed. |
| `BluetoothDevices.qml` | The open Bluetooth section of the settings drawer. Lists paired devices with Connect and Disconnect buttons. Scan lists nearby devices, and Pair pairs, trusts, and connects one. Scanning stops after a minute or when the drawer closes. Scan and Pair start the pairing agent with systemctl, and it stops when no scan or pairing needs it. |
| `SettingsSection.qml` | One expandable row in the settings drawer. |
| `Capabilities.qml` | Singleton. Checks whether power-profiles-daemon is running, once when the bar starts and again each time the settings drawer opens. |
| `SystemUsage.qml` | Singleton. Reads CPU, memory, and GPU use from the script in `../quickshell.nix`, and keeps the last two minutes of each for the activity monitor's charts. |
| `UsageGauge.qml` | One gauge in the bar, such as CPU or RAM. Clicking it opens the activity monitor. |
| `ActivityMonitor.qml` | The activity monitor window. Shows CPU, RAM, GPU, and VRAM use as tiles with small charts. A GPU or VRAM tile that this computer cannot read stays in the row, dimmed, with "n/a" and a note that it needs an AMD card. It also shows a large chart and details for the chosen one, a bar per CPU core, and a table of programs with their CPU, memory, GPU, and VRAM use. Clicking a column title sorts by it: largest first, then smallest first, then in the order the programs started. Reads processes from the script in `../quickshell.nix` only while open. |
| `UsageChart.qml` | A line chart of percentages with a faded fill, used by the activity monitor. |
| `AudioSpectrum.qml` | Singleton. Runs cava and reads the bar heights. If cava stops, it starts it again, and waits twice as long after each failure in a row, up to 30 seconds. |
| `cava.conf` | Settings for cava: PipeWire input and raw output for `AudioSpectrum.qml` to read. `@bars@` is filled in by `../quickshell.nix`. |
| `AudioVisualizer.qml` | Draws the audio bars. |
| `ClockCard.qml` | The clock window, with the time and the date. Opens when the bar starts. Mod+T opens and closes it. |
| `MediaCard.qml` | The now-playing window, opened from the media button in the bar while media plays. Closes when the music stops. |
| `PanelGlow.qml` | A soft light glow around a panel, the same as niri's glow around the focused window. Placed before a panel with `target` set to it. Draws only outside the panel, so the see-through panel does not look lighter. Used by the bar's two panels, the settings drawer, the volume mixer, the power menu, and the tray drop-down. |
| `glow.frag` | The shader `PanelGlow.qml` runs, with niri's glow math. `../quickshell.nix` compiles it to `glow.frag.qsb`, which Qt 6 reads. |
| `IconButton.qml` | A round button with one icon. Its `tooltip` text shows in a small label under it after the mouse rests on it for half a second. |
| `TextButton.qml` | A small rounded button with a word on it, such as "Join". Its word size, height, and side space can be set. |
| `ThemedSlider.qml` | A slider in the theme colors. Use it instead of the plain `Slider`, whose default style is blue. |
| `ThemedSwitch.qml` | An on and off switch in the theme colors, used for Wi-Fi and Bluetooth. Use it instead of the plain `Switch`, whose default style is blue. |
| `ThemedTextField.qml` | A text box in the theme colors, used for the Wi-Fi password form. Use it instead of the plain `TextField`, whose default style is blue. |
| `UiText.qml` | Text in the theme font and color. |

## Rules

- `Theme.qml` is generated. Change colors, sizes, and fonts in `../quickshell.nix`, not here.
- Start a program by its store path from `Theme`, such as `Theme.niriCommand` or `Theme.systemctlCommand`, not by its bare name. Add a new one next to them in `../quickshell.nix`.
- Change the number of visualizer bars with `spectrumBars` in `../quickshell.nix`. It fills in both `cava.conf` and `Theme.qml`.
- Quickshell comes from nixpkgs-unstable, because 0.3.0 crashes when a Wi-Fi access point disappears. See `programs.quickshell.package` in `../quickshell.nix`.
- `Theme.showBattery` is true only when `machine.formFactor` is "laptop". Hide any laptop-only control behind it.
- When you add a QML file, list it in `qmldir` too.
- `Theme.panel` is see-through. A new window that draws it needs a `BackgroundEffect.blurRegion` that covers the panel, or it looks dim instead of frosted. The blur shows only where that region is.
- A new panel window gets the glow with a `PanelGlow` before its panel. Make the window `Theme.glowReach` larger than the panel on each side the glow shows, place the panel inside that space, and limit `mask` and `BackgroundEffect.blurRegion` to the panel, so the glow space neither takes clicks nor gets blurred. Tooltips have no glow.
- `ActivityMonitor.qml`, `ClockCard.qml`, and `MediaCard.qml` are normal windows, not panels, so the blur rule above does not apply to them. niri places, moves, and sizes them, so they do not save a position. A niri window rule in `../niri.nix` matches their titles, "Activity monitor", "Clock", and "Now playing", to make them float and blur them. Change both together.
- A `PopupWindow` must never have a width or height of 0, even for a moment. Wayland treats it as an error and closes the connection, which stops the whole bar. Give it a minimum size, as `VolumeMixer.qml` does.
- The bar supports niri only. It reads workspaces and windows with `niri msg` and has no code for other compositors.
- The login screen in `modules/machines/reatan-x7-00/nixos/greeter/` uses the generated `Theme.qml` too. `../quickshell.nix` shares it as `lib.quickshell.themeFile`. If you rename or remove a `Theme` property, check `greeter/shell.qml` as well.
- The login screen also uses `UiText.qml`, `TextButton.qml`, `IconButton.qml`, and `ThemedTextField.qml` as they are. `../quickshell.nix` shares this folder as `lib.quickshell.qmlDir`, and `greeter.nix` picks those four files. Before you rename or remove one of their properties, or make them use another file from this folder, check `greeter/shell.qml` and the `sharedQml` list in `greeter.nix`.

## Keeping this file current

When you change the files in this folder, update this file in the same change. If you add a subdirectory, give it an AGENTS.md and link it under Subdirectories. If you remove one, delete its AGENTS.md and its link. The full rules are in the root `AGENTS.md`.
