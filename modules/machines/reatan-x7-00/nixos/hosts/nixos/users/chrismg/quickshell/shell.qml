pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

ShellRoot {
    id: root

    property bool settingsVisible: false
    property bool mediaVisible: false
    property bool powerMenuVisible: false
    // Whether the activity monitor window is open, and the measure it shows:
    // "cpu", "memory", "gpu", or "vram".
    property bool activityVisible: false
    property string activityMetric: "cpu"
    // The bar floats over windows and hides until something shows it. See
    // barShownOn() below. Hovering the top edge of a screen also shows it, which
    // TopBar.qml handles by itself.
    // True after the toggle key, Mod+B in niri.nix, until it is pressed again.
    property bool barPinned: false
    // True while niri's overview, Mod+O, is open.
    property bool overviewOpen: false
    // The monitor whose workspace just changed. Its bar shows for a moment.
    property string barPeekOutput: ""
    property var targetScreen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    property var workspaceRecords: []
    property var windowRecords: []
    property real clockLeft: widgetPositions.clockLeft
    property real clockTop: widgetPositions.clockTop
    property real clockWidth: widgetPositions.clockWidth
    property real clockHeight: widgetPositions.clockHeight
    property real mediaLeft: widgetPositions.mediaLeft
    property real mediaTop: widgetPositions.mediaTop
    property real mediaWidth: widgetPositions.mediaWidth
    property real mediaHeight: widgetPositions.mediaHeight
    readonly property var activePlayer: Mpris.players.values.find(player => player.isPlaying)
        ?? Mpris.players.values[0]
        ?? null
    readonly property bool mediaPlaying: activePlayer !== null && activePlayer.isPlaying

    onMediaPlayingChanged: {
        if (!mediaPlaying)
            mediaVisible = false;
    }

    FileView {
        path: Quickshell.statePath("widget-positions.json")
        printErrors: false
        onAdapterUpdated: writeAdapter()

        JsonAdapter {
            id: widgetPositions

            property real clockLeft: Theme.clockLeft
            property real clockTop: Theme.clockTop
            property real clockWidth: Theme.clockWidth
            property real clockHeight: Theme.clockHeight
            property real mediaLeft: Theme.mediaLeft
            property real mediaTop: Theme.mediaTop
            property real mediaWidth: Theme.mediaWidth
            property real mediaHeight: Theme.mediaHeight
        }
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

    // Whether the bar on one monitor is shown, apart from hovering. The settings
    // drawer and the power menu keep it shown while they are open, because they
    // open from its buttons.
    function barShownOn(outputName) {
        return barPinned
            || overviewOpen
            || (barPeek.running && barPeekOutput === outputName)
            || settingsVisible
            || powerMenuVisible;
    }

    function showOn(target) {
        if (target)
            targetScreen = target;
    }

    // The settings drawer and the power menu open in the same corner, so opening
    // one closes the other.
    function toggleSettings(target) {
        showOn(target);
        settingsVisible = !settingsVisible;
        if (settingsVisible)
            powerMenuVisible = false;
    }

    function togglePowerMenu(target) {
        showOn(target);
        powerMenuVisible = !powerMenuVisible;
        if (powerMenuVisible)
            settingsVisible = false;
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
        // first. The names are passed as arguments, not pasted into the shell text.
        Quickshell.execDetached([
            "sh", "-c",
            'niri msg action focus-monitor "$1" && niri msg action focus-workspace "$2"',
            "sh", outputName, String(number)
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
        }
    }

    // One long-running connection to niri. niri prints the current state, then
    // one JSON line for every change, so the bar updates as soon as something
    // happens instead of asking every second.
    Process {
        id: niriEvents

        running: !niriRestart.running
        command: ["niri", "msg", "-j", "event-stream"]
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

    // `quickshell ipc -c chrismg call bar toggle` runs toggle() below. niri.nix
    // binds it to Mod+B.
    IpcHandler {
        target: "bar"

        function toggle(): void {
            root.barPinned = !root.barPinned;
        }
    }

    IpcHandler {
        target: "shell"

        function toggleSettings(): void {
            root.toggleSettings(root.targetScreen);
        }

        function toggleMedia(): void {
            root.toggleMedia(root.targetScreen);
        }

        function togglePowerMenu(): void {
            root.togglePowerMenu(root.targetScreen);
        }

        // niri.nix binds this to Ctrl+Shift+Escape.
        function toggleActivity(): void {
            root.toggleActivity("");
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
        model: Quickshell.screens

        Scope {
            id: screenShell

            required property var modelData

            TopBar {
                screen: screenShell.modelData
                // `name` is the screen's connector name, such as "DP-1".
                shown: root.barShownOn(screenShell.modelData.name)
                workspaces: root.workspacesOn(screenShell.modelData.name)
                activeWorkspace: root.activeWorkspaceOn(screenShell.modelData.name)
                occupiedWorkspaces: root.occupiedWorkspacesOn(screenShell.modelData.name)
                player: root.activePlayer
                onWorkspaceRequested: number => root.activateWorkspace(screenShell.modelData.name, number)
                onSettingsRequested: root.toggleSettings(screenShell.modelData)
                onPowerRequested: root.togglePowerMenu(screenShell.modelData)
                onMediaRequested: root.toggleMedia(screenShell.modelData)
                onActivityRequested: metric => root.toggleActivity(metric)
            }

            ClockCard {
                screen: screenShell.modelData
                positionLeft: root.clockLeft
                positionTop: root.clockTop
                panelWidth: root.clockWidth
                panelHeight: root.clockHeight
                onPositionRequested: (left, top) => {
                    widgetPositions.clockLeft = left;
                    widgetPositions.clockTop = top;
                }
                onSizeRequested: (width, height) => {
                    widgetPositions.clockWidth = width;
                    widgetPositions.clockHeight = height;
                }
            }

            MediaCard {
                screen: screenShell.modelData
                visible: root.mediaVisible
                    && root.mediaPlaying
                    && root.targetScreen === screenShell.modelData
                player: root.activePlayer
                settingsOpen: root.settingsVisible
                positionLeft: root.mediaLeft
                positionTop: root.mediaTop
                panelWidth: root.mediaWidth
                panelHeight: root.mediaHeight
                onPositionRequested: (left, top) => {
                    widgetPositions.mediaLeft = left;
                    widgetPositions.mediaTop = top;
                }
                onSizeRequested: (width, height) => {
                    widgetPositions.mediaWidth = width;
                    widgetPositions.mediaHeight = height;
                }
                onCloseRequested: root.mediaVisible = false
            }

            SettingsDrawer {
                screen: screenShell.modelData
                visible: root.settingsVisible && root.targetScreen === screenShell.modelData
                onCloseRequested: root.settingsVisible = false
            }

            PowerMenu {
                screen: screenShell.modelData
                visible: root.powerMenuVisible && root.targetScreen === screenShell.modelData
                onCloseRequested: root.powerMenuVisible = false
            }
        }
    }
}
