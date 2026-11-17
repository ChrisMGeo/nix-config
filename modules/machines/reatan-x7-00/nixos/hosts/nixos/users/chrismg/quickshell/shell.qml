pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

ShellRoot {
    id: root

    // Whether the bar and its open popup are on screen. While false, nothing
    // shows. While true with no popup open, the bar stays on screen until it
    // is hidden again. A tap of Mod, Escape, and a click away change it. It never
    // opens, closes, or resets a popup, so a hidden popup comes back exactly
    // as it was.
    property bool barVisible: false
    // The bar's popups: the settings drawer, the power menu, and the tray
    // drop-down. They share one place, so only one is open at a time, named
    // here: "settings", "power", "tray", or "" for none. The volume mixer
    // belongs to the drawer and closes with it.
    property string openMenu: ""
    property bool mixerVisible: false
    readonly property bool settingsVisible: openMenu === "settings"
    readonly property bool powerMenuVisible: openMenu === "power"
    readonly property bool trayVisible: openMenu === "tray"
    // The now-playing window. It is a separate window, not a popup of the bar,
    // so the bar's visibility does not change it.
    property bool mediaVisible: false
    // Whether the activity monitor window is open, and the measure it shows:
    // "cpu", "memory", "gpu", or "vram". It is a separate window too.
    property bool activityVisible: false
    property string activityMetric: "cpu"
    // Whether the clock window is open. It opens when the bar starts. Mod+T in
    // niri.nix opens and closes it.
    property bool clockVisible: true
    // True while niri's overview, Mod+O, is open.
    property bool overviewOpen: false
    // The monitor whose workspace just changed. Its bar shows for a moment.
    property string barPeekOutput: ""
    property var targetScreen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    property var workspaceRecords: []
    property var windowRecords: []
    readonly property var activePlayer: Mpris.players.values.find(player => player.isPlaying)
        ?? Mpris.players.values[0]
        ?? null
    readonly property bool mediaPlaying: activePlayer !== null && activePlayer.isPlaying
    // True while the bar or one of its popups, on any monitor, has the
    // keyboard. `instances` lists what Variants below made, one per monitor.
    readonly property bool barHasKeyboard: perScreen.instances.some(screenShell => screenShell.hasKeyboard)

    // Asks the bar on one monitor to take the keyboard. See takeKeyboard() in
    // TopBar.qml.
    signal barKeyboardWanted(var screen)

    onMediaPlayingChanged: {
        if (!mediaPlaying)
            mediaVisible = false;
    }

    // The volume mixer belongs to the drawer, so it closes whenever the drawer
    // does, however the drawer was closed.
    onOpenMenuChanged: {
        if (openMenu !== "settings")
            mixerVisible = false;
    }

    // The bar or a popup had the keyboard and lost it. That happens when a
    // click lands on any other window, so after a short wait, in case the
    // keyboard is only moving between the bar's own windows, it counts as a
    // click away.
    onBarHasKeyboardChanged: {
        if (!barHasKeyboard)
            keyboardLeft.restart();
    }

    // niri numbers workspaces separately on each monitor, starting at 1, and
    // reports the monitor's connector name, such as "DP-1", as `output`. Each bar
    // passes its own screen name, so it shows only that monitor's workspaces.
    function workspacesOn(outputName) {
        const numbers = [...new Set(workspaceRecords
            .filter(workspace => workspace.output === outputName)
            .map(workspace => workspace.idx)
            .filter(number => number > 0))]
            .sort((left, right) => left - right);
        return numbers.length > 0 ? numbers : [1, 2, 3, 4];
    }

    function activeWorkspaceOn(outputName) {
        // `is_active` marks the workspace shown on its monitor, focused or not.
        const active = workspaceRecords.find(workspace => workspace.output === outputName && workspace.is_active);
        return active ? active.idx : 1;
    }

    function occupiedWorkspacesOn(outputName) {
        const occupied = {};

        for (const window of windowRecords) {
            const workspace = workspaceRecords.find(candidate => candidate.id === window.workspace_id);
            if (workspace && workspace.output === outputName)
                occupied[String(workspace.idx)] = true;
        }

        return occupied;
    }

    // Whether the bar on one monitor is shown. The overview and a workspace
    // change show it for a while without changing `barVisible`.
    function barShownOn(outputName) {
        return barVisible
            || overviewOpen
            || (barPeek.running && barPeekOutput === outputName);
    }

    function showOn(target) {
        if (target)
            targetScreen = target;
    }

    // The bar is about to move niri's focus itself: a popup that had the
    // keyboard closes, so niri gives it back to the window behind, or the bar
    // switches workspace or opens a window. The next window focus change that
    // niri reports within `timeout` milliseconds is that move, not a click
    // away. Only that one change is skipped, so a real click right after
    // still hides the bar. A tap of Mod and opening a popup do not call this,
    // because they only take the keyboard, which niri reports as no window
    // focused, and the bar ignores that.
    function expectFocusMove(timeout) {
        focusMoveExpected.interval = timeout;
        focusMoveExpected.restart();
    }

    // A click landed outside the bar and its popups. The bar and its popups
    // hide, and stay open, for the next tap of Mod.
    function clickedAway() {
        if (barVisible)
            barVisible = false;
    }

    // Opens one of the bar's popups, which closes the one open before, or
    // closes it when it is already on screen there. Opening one while the bar
    // is hidden shows everything again.
    function toggleMenu(name, target) {
        // Replacing a popup that had the keyboard hands it back to the window
        // behind for a moment, before the new popup takes it.
        if (openMenu !== "" && openMenu !== name && barHasKeyboard)
            expectFocusMove(300);
        if (openMenu === name && barVisible && targetScreen === target) {
            closeMenu(name);
            return;
        }

        showOn(target);
        openMenu = name;
        barVisible = true;
        // The drawer and the power menu are windows of their own, which take
        // the keyboard when they appear. The tray drop-down lives in the
        // bar's window, so the bar takes the keyboard for it.
        if (name === "tray")
            barKeyboardWanted(targetScreen);
    }

    // Closes one popup. Its close button, Escape, and toggling it from the
    // bar all end here. When the popup had the keyboard, the bar takes it, so
    // the next Escape still reaches the bar.
    function closeMenu(name) {
        if (openMenu !== name)
            return;

        const hadKeyboard = barHasKeyboard;
        // A popup with the keyboard hands it back to the window behind as it
        // closes, before the bar takes it.
        if (hadKeyboard)
            expectFocusMove(300);
        openMenu = "";
        if (hadKeyboard)
            barKeyboardWanted(targetScreen);
    }

    // Escape, when the bar or a popup has the keyboard. It closes the newest
    // popup: the volume mixer before the drawer it belongs to. With no popup
    // open, it hides the bar.
    function escapePressed() {
        if (mixerVisible)
            mixerVisible = false;
        else if (openMenu !== "")
            closeMenu(openMenu);
        else
            barVisible = false;
    }

    // The toggle key, Mod tapped on its own. It shows the bar and its open
    // popup, or hides them. Neither opens nor closes a popup. Showing the
    // bar takes the keyboard, so niri counts no window as focused. A click
    // on any window, even the one that had the keyboard before, then makes
    // niri report a focus change, which hides the bar. The drawer and the
    // power menu take the keyboard themselves when they appear, so the bar
    // only takes it when neither is open.
    function toggleBar() {
        barVisible = !barVisible;
        if (barVisible && openMenu !== "settings" && openMenu !== "power")
            barKeyboardWanted(targetScreen);
    }

    function toggleMedia(target) {
        if (!mediaPlaying)
            return;

        showOn(target);
        mediaVisible = !mediaVisible;
    }

    // Clicking a gauge opens the activity monitor on that measure. Clicking
    // another gauge while it is open switches the measure, and clicking the
    // gauge of the measure it already shows closes it. An empty `metric`, from
    // the keyboard shortcut, opens or closes it as it was.
    function toggleActivity(metric) {
        if (activityVisible && (metric === "" || metric === activityMetric)) {
            activityVisible = false;
            return;
        }

        if (metric !== "")
            activityMetric = metric;
        activityVisible = true;
    }

    function activateWorkspace(outputName, number) {
        // focus-workspace acts on the focused monitor, so focus the bar's monitor
        // first. The names and niri's path are passed as arguments, not pasted
        // into the shell text.
        Quickshell.execDetached([
            "sh", "-c",
            '"$1" msg action focus-monitor "$2" && "$1" msg action focus-workspace "$3"',
            "sh", Theme.niriCommand, outputName, String(number)
        ]);
    }

    // Applies one event from `niri msg -j event-stream` to the workspace and
    // window lists. The bars read those lists through workspacesOn() and the
    // other per-monitor functions above. Events the bar does not use, such as
    // keyboard layout changes, are ignored.
    function handleNiriEvent(event) {
        if (event.WorkspacesChanged) {
            // The full list. niri sends it first, and again when workspaces are
            // added, removed, or moved to another monitor.
            workspaceRecords = event.WorkspacesChanged.workspaces;
        } else if (event.WorkspaceActivated) {
            // A workspace became the visible one on its monitor. If `focused` is
            // true, it also has the keyboard focus now.
            const activated = workspaceRecords.find(workspace => workspace.id === event.WorkspaceActivated.id);
            if (!activated)
                return;

            const focused = event.WorkspaceActivated.focused;
            workspaceRecords = workspaceRecords.map(workspace => Object.assign({}, workspace, {
                is_active: workspace.output === activated.output
                    ? workspace.id === activated.id
                    : workspace.is_active,
                is_focused: focused ? workspace.id === activated.id : workspace.is_focused
            }));

            // Show that monitor's bar for a moment, so you can see where you are.
            barPeekOutput = activated.output;
            barPeek.restart();
        } else if (event.OverviewOpenedOrClosed) {
            // niri sends the current state first, then every change.
            overviewOpen = event.OverviewOpenedOrClosed.is_open;
        } else if (event.WindowsChanged) {
            // The full window list, sent first.
            windowRecords = event.WindowsChanged.windows;
        } else if (event.WindowOpenedOrChanged) {
            // A new window, or a change to one, such as moving it to another
            // workspace. Replace the old record with the new one.
            const window = event.WindowOpenedOrChanged.window;
            windowRecords = windowRecords.filter(candidate => candidate.id !== window.id).concat([window]);
        } else if (event.WindowClosed) {
            windowRecords = windowRecords.filter(candidate => candidate.id !== event.WindowClosed.id);
        } else if (event.WindowFocusChanged) {
            // Another window got the keyboard, by a click or by a key. That is
            // a click away. An `id` of null means no window has it, which
            // happens when the bar or a popup itself takes the keyboard, so it
            // is not one. A move the bar itself expects is skipped once. See
            // expectFocusMove().
            if (event.WindowFocusChanged.id === null)
                return;
            if (focusMoveExpected.running) {
                focusMoveExpected.stop();
                focusMoveSettling.restart();
            } else {
                clickedAway();
            }
        }
    }

    // One long-running connection to niri. niri prints the current state, then
    // one JSON line for every change, so the bar updates as soon as something
    // happens instead of asking every second.
    Process {
        id: niriEvents

        running: !niriRestart.running
        command: [Theme.niriCommand, "msg", "-j", "event-stream"]
        // If the stream ends, for example after niri restarts, wait a second
        // and connect again. The new stream starts with the full state.
        onExited: niriRestart.restart()

        stdout: SplitParser {
            onRead: line => {
                try {
                    root.handleNiriEvent(JSON.parse(line));
                } catch (error) {
                    console.warn("Could not parse niri event:", error);
                }
            }
        }
    }

    Timer {
        id: niriRestart

        interval: 1000
    }

    // How long the bar stays after a workspace change, in milliseconds.
    Timer {
        id: barPeek

        interval: 1500
    }

    // See expectFocusMove(). Its interval is set there.
    Timer {
        id: focusMoveExpected
    }

    // Runs for a moment after the expected focus move arrived. The bar's
    // windows may report losing the keyboard a little after niri reports the
    // move, and that loss is part of the same move.
    Timer {
        id: focusMoveSettling

        interval: 400
    }

    // See onBarHasKeyboardChanged above.
    Timer {
        id: keyboardLeft

        interval: 250
        onTriggered: {
            if (!root.barHasKeyboard && !focusMoveExpected.running && !focusMoveSettling.running)
                root.clickedAway();
        }
    }

    // `quickshell ipc -c chrismg call bar toggle` runs toggle() below. niri.nix
    // binds it to a tap of Mod.
    IpcHandler {
        target: "bar"

        function toggle(): void {
            root.toggleBar();
        }
    }

    IpcHandler {
        target: "shell"

        function toggleSettings(): void {
            root.toggleMenu("settings", root.targetScreen);
        }

        function toggleMedia(): void {
            root.toggleMedia(root.targetScreen);
        }

        function togglePowerMenu(): void {
            root.toggleMenu("power", root.targetScreen);
        }

        // niri.nix binds this to Ctrl+Shift+Escape.
        function toggleActivity(): void {
            root.toggleActivity("");
        }

        // niri.nix binds this to Mod+T.
        function toggleClock(): void {
            root.clockVisible = !root.clockVisible;
        }
    }

    // The clock and the now-playing windows. Like the activity monitor, each
    // is one normal window, not one per monitor, and niri opens it on the
    // focused monitor. The now-playing window exists only while it is open
    // and something plays.
    LazyLoader {
        active: root.clockVisible

        ClockCard {
            onCloseRequested: root.clockVisible = false
        }
    }

    LazyLoader {
        active: root.mediaVisible && root.mediaPlaying

        MediaCard {
            player: root.activePlayer
            onCloseRequested: root.mediaVisible = false
        }
    }

    // The activity monitor. LazyLoader creates the window when `active` turns
    // true and destroys it when it turns false, so it reads processes only
    // while open. It is one window, not one per monitor. niri opens it on the
    // focused monitor.
    LazyLoader {
        active: root.activityVisible

        ActivityMonitor {
            metric: root.activityMetric
            onMetricSelected: metric => root.activityMetric = metric
            onCloseRequested: root.activityVisible = false
        }
    }

    Variants {
        id: perScreen

        model: Quickshell.screens

        Scope {
            id: screenShell

            required property var modelData
            // Whether the bar or a popup on this monitor has the keyboard.
            readonly property bool hasKeyboard: topBar.hasKeyboard || drawer.hasKeyboard || powerMenu.hasKeyboard
            // Popups show only while the bar is visible. Hidden, they stay
            // open, with everything in them kept.
            readonly property bool popupsShown: root.barVisible
                && root.targetScreen === screenShell.modelData

            TopBar {
                id: topBar

                screen: screenShell.modelData
                // `name` is the screen's connector name, such as "DP-1".
                shown: root.barShownOn(screenShell.modelData.name)
                // Never while hidden, so a hidden bar holds no keyboard.
                keyboardAllowed: root.barVisible
                workspaces: root.workspacesOn(screenShell.modelData.name)
                activeWorkspace: root.activeWorkspaceOn(screenShell.modelData.name)
                occupiedWorkspaces: root.occupiedWorkspacesOn(screenShell.modelData.name)
                player: root.activePlayer
                trayOpen: root.trayVisible && root.targetScreen === screenShell.modelData
                popupsHidden: !screenShell.popupsShown
                onEscapePressed: root.escapePressed()
                // Switching workspace and opening a window move niri's focus.
                // They are the bar's own actions, not a click away.
                onWorkspaceRequested: number => {
                    root.expectFocusMove(1000);
                    root.activateWorkspace(screenShell.modelData.name, number);
                }
                onSettingsRequested: root.toggleMenu("settings", screenShell.modelData)
                onPowerRequested: root.toggleMenu("power", screenShell.modelData)
                onTrayRequested: root.toggleMenu("tray", screenShell.modelData)
                onTrayCloseRequested: root.closeMenu("tray")
                onMediaRequested: {
                    root.expectFocusMove(1500);
                    root.toggleMedia(screenShell.modelData);
                }
                onActivityRequested: metric => {
                    root.expectFocusMove(1500);
                    root.toggleActivity(metric);
                }
            }

            Connections {
                target: root

                function onBarKeyboardWanted(screen) {
                    if (screen === screenShell.modelData)
                        topBar.takeKeyboard();
                }
            }

            // `open` is whether the drawer is open on this monitor, and
            // `visible` whether it is on screen. Its scans follow `open`, so
            // hiding it is not closing it.
            SettingsDrawer {
                id: drawer

                screen: screenShell.modelData
                open: root.settingsVisible && root.targetScreen === screenShell.modelData
                visible: open && screenShell.popupsShown
                mixerOpen: root.mixerVisible
                onCloseRequested: root.closeMenu("settings")
                onEscapePressed: root.escapePressed()
                onMixerOpenRequested: wanted => {
                    root.mixerVisible = wanted;
                }
            }

            PowerMenu {
                id: powerMenu

                screen: screenShell.modelData
                open: root.powerMenuVisible && root.targetScreen === screenShell.modelData
                visible: open && screenShell.popupsShown
                onCloseRequested: root.closeMenu("power")
                onEscapePressed: root.escapePressed()
            }
        }
    }
}
