pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    property var workspaces: [1, 2, 3, 4]
    property int activeWorkspace: 1
    property var occupiedWorkspaces: ({})
    property var player: null
    // Set by shell.qml: true while the bar is visible, or while the overview
    // or a workspace change on this monitor shows it.
    property bool shown: false
    // Set by shell.qml: false while the bar is hidden, so a hidden bar never
    // holds the keyboard.
    property bool keyboardAllowed: false
    // Whether the tray drop-down is open. Set by shell.qml, which the tray
    // button asks to open or close it.
    property bool trayOpen: false
    // True while the bar's popups are not on screen, because the bar is
    // hidden. The drop-down stays open but does not show.
    property bool popupsHidden: false
    // Whether the drop-down is open and on screen.
    readonly property bool trayShown: trayOpen && !popupsHidden
    // Whether the bar is on screen.
    readonly property bool revealed: shown || trayShown
    // Whether the bar has the keyboard, in its own window or in the keyboard
    // holder below. shell.qml uses it to notice a click away.
    readonly property bool hasKeyboard: keyProbe.windowActive || keyboardHolder.windowActive
    // Space between a panel's edge and its contents, in pixels.
    readonly property int sectionPadding: 6
    // True while the keyboard holder below is on screen. See takeKeyboard().
    property bool holdingKeyboard: false

    signal workspaceRequested(int number)
    signal settingsRequested()
    signal powerRequested()
    // The tray button was clicked.
    signal trayRequested()
    // The drop-down asks to close, after a program was activated.
    signal trayCloseRequested()
    signal mediaRequested()
    // A usage gauge was clicked. `metric` is "cpu", "memory", "gpu", or "vram".
    signal activityRequested(string metric)
    // Escape was pressed while the bar had the keyboard. shell.qml decides
    // what it closes or hides.
    signal escapePressed()

    // Gives the bar the keyboard without a click. niri gives on-demand focus
    // only to a window that just appeared or was clicked, and the bar is
    // already on screen. So the keyboard holder below appears, and niri gives
    // it the keyboard. Used when a tap of Mod shows the bar, when the tray drop-down
    // opens, and when a popup that had the keyboard closes.
    function takeKeyboard() {
        if (keyboardAllowed)
            holdingKeyboard = true;
    }

    // The holder goes away once the bar hides, or once a click elsewhere took
    // the keyboard from it.
    onKeyboardAllowedChanged: {
        if (!keyboardAllowed)
            holdingKeyboard = false;
    }

    // The bar floats over windows instead of pushing them down. Ignore reserves
    // no space and lets the window start at the very top edge of the screen.
    // Setting exclusiveZone would undo this.
    // The window is Theme.glowReach taller than the bar and spans the whole
    // screen width, so the glow around the panels has room below and beside
    // them. The panels keep Theme.outerMargin from the screen's sides, inside
    // the window. The mask below keeps the extra space from taking clicks.
    implicitHeight: Theme.barTopGap + Theme.barHeight + Theme.glowReach
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    // On-demand focus: a click on the bar gives it the keyboard, so Escape
    // reaches it. See takeKeyboard() for the other ways it gets the keyboard.
    // None while hidden, which also gives the keyboard back when the bar hides.
    WlrLayershell.keyboardFocus: keyboardAllowed ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    // Holds the keyboard for the bar. A window of 1 by 1 pixels in the top
    // right corner that draws nothing and takes no clicks, so it can neither
    // be seen nor catch a click. It appears only when takeKeyboard() asks,
    // and niri gives it the keyboard as it appears, through on-demand focus.
    // Its keys count as the bar's: Escape goes to shell.qml.
    PanelWindow {
        id: keyboardHolder

        readonly property bool windowActive: holderProbe.windowActive

        screen: root.screen
        visible: root.holdingKeyboard
        implicitWidth: 1
        implicitHeight: 1
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        focusable: true

        anchors {
            top: true
            right: true
        }

        // No part of it takes clicks.
        mask: Region {}

        Item {
            id: holderProbe

            readonly property bool windowActive: Window.active

            // A click elsewhere took the keyboard, so the holder is done.
            onWindowActiveChanged: {
                if (!windowActive)
                    root.holdingKeyboard = false;
            }

            // Qt matches Shortcuts by the item they sit in, and treats this
            // one as part of the bar's window too. Two enabled Escape
            // Shortcuts there cancel each other, so only one is on at a time.
            Shortcut {
                sequence: "Escape"
                enabled: root.holdingKeyboard
                onActivated: root.escapePressed()
            }
        }
    }

    anchors {
        top: true
        left: true
        right: true
    }

    // The parts of the window that take the mouse. Clicks anywhere else go
    // through to the windows below. While hidden, no part does, so the mouse
    // at the top edge shows nothing. While shown, the gap above the bar and
    // the two panels do. `bar.x` turns a panel's place inside the bar into
    // its place in the window.
    mask: Region {
        x: bar.x
        y: 0
        width: bar.width
        height: root.revealed ? Theme.barTopGap : 0

        Region {
            x: bar.x + workspacePanel.x
            y: Theme.barTopGap
            width: root.revealed ? workspacePanel.width : 0
            height: Theme.barHeight
        }

        Region {
            x: bar.x + statusPanel.x
            y: Theme.barTopGap
            width: root.revealed ? statusPanel.width : 0
            height: Theme.barHeight
        }
    }

    // Asks niri to blur what is behind each of the two panels, for a frosted
    // glass look. The gaps between panels stay clear. Theme.panel is
    // see-through, so the blur shows. `slide.y` moves the blur with the panels
    // while they slide in and out. A child Region adds its area to the one
    // above it, and the empty top Region adds nothing.
    BackgroundEffect.blurRegion: Region {
        Region {
            x: bar.x + workspacePanel.x
            y: Theme.barTopGap + slide.y
            width: workspacePanel.width
            height: Theme.barHeight
        }

        Region {
            x: bar.x + statusPanel.x
            y: Theme.barTopGap + slide.y
            width: statusPanel.width
            height: Theme.barHeight
        }
    }

    // Tracks whether the window has the keyboard, and holds the Escape key.
    // A Shortcut and the attached `Window` must sit in an item, which tells
    // them their window.
    Item {
        id: keyProbe

        readonly property bool windowActive: Window.active

        anchors.fill: parent

        // A Shortcut works wherever the keyboard focus is inside the window.
        Shortcut {
            sequence: "Escape"
            enabled: root.keyboardAllowed && !root.holdingKeyboard
            onActivated: root.escapePressed()
        }
    }

    // The time for the clock in the right panel. Minutes are enough, so it
    // updates once a minute.
    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    // The drop-down under the tray button.
    TrayMenu {
        anchorItem: trayButton
        // The button's top, from the top of the screen: the bar's place in
        // the window, the row's place in the right panel, and the button's
        // place in the row. The slide is left out, because the drop-down
        // only shows once the bar is in place.
        anchorItemTop: bar.y + statusPanel.y + statusRow.y + trayButton.y
        // Showing the bar again can show the drop-down while the bar is still
        // sliding in. The drop-down takes its place from the button when it
        // opens, so it waits until the slide ends, or it would stay over the
        // bar.
        visible: root.trayShown && slide.y === 0
        onCloseRequested: root.trayCloseRequested()
    }

    // The bar is drawn as two separate panels with empty space between them:
    // the workspaces on the left, and the visualizer, clock, tray, gauges, and
    // buttons on the right. They share this one window, so menus open in the
    // same place as before.
    Item {
        id: bar

        x: Theme.outerMargin
        y: Theme.barTopGap
        width: parent.width - Theme.outerMargin * 2
        height: Theme.barHeight
        opacity: root.revealed ? 1 : 0

        // Slides the panels up off the screen while hidden. A transform moves
        // what is drawn without moving the panels themselves, so the mask above
        // keeps the panels' resting place.
        transform: Translate {
            id: slide

            y: root.revealed ? 0 : -(Theme.barTopGap + Theme.barHeight)

            Behavior on y {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }
        }

        Behavior on opacity {
            NumberAnimation { duration: 180 }
        }

        // The glow around each panel. They come first, so they are drawn
        // underneath the panels, and they slide and fade with them.
        PanelGlow {
            target: workspacePanel
        }

        PanelGlow {
            target: statusPanel
        }

        // The left panel: the workspace buttons of this monitor.
        Rectangle {
            id: workspacePanel

            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
            }
            width: workspaceRow.implicitWidth + root.sectionPadding * 2
            color: Theme.panel

            Row {
                id: workspaceRow

                anchors.centerIn: parent
                spacing: 4

                Repeater {
                    model: root.workspaces

                    Rectangle {
                        id: workspaceButton

                        required property int modelData

                        width: Theme.scaled(32)
                        height: Theme.scaled(32)
                        radius: Theme.radius - 5
                        color: modelData === root.activeWorkspace
                            ? Theme.accent
                            : workspaceMouse.containsMouse ? Theme.surfaceHover : Theme.surface

                        UiText {
                            id: workspaceNumber

                            anchors.centerIn: parent
                            text: workspaceButton.modelData
                            color: workspaceButton.modelData === root.activeWorkspace
                                ? Theme.accentText
                                : Theme.textMuted
                            font.pixelSize: Theme.scaled(12)
                            font.weight: Font.DemiBold
                        }

                        Rectangle {
                            anchors {
                                horizontalCenter: parent.horizontalCenter
                                top: workspaceNumber.bottom
                            }
                            width: 4
                            height: 4
                            // Half the width, so the dot is always a circle.
                            radius: width / 2
                            visible: root.occupiedWorkspaces[String(workspaceButton.modelData)] === true
                            color: workspaceButton.modelData === root.activeWorkspace
                                ? Theme.accentText
                                : Theme.accent
                        }

                        MouseArea {
                            id: workspaceMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.workspaceRequested(workspaceButton.modelData)
                        }
                    }
                }
            }
        }

        // The right panel: the audio visualizer, the clock, the tray button,
        // the usage gauges, and the settings and power buttons.
        Rectangle {
            id: statusPanel

            anchors {
                right: parent.right
                top: parent.top
                bottom: parent.bottom
            }
            width: statusRow.implicitWidth + root.sectionPadding * 2
            color: Theme.panel

            RowLayout {
                id: statusRow

                anchors {
                    right: parent.right
                    rightMargin: root.sectionPadding
                    verticalCenter: parent.verticalCenter
                }
                spacing: 2

                AudioVisualizer {
                    Layout.alignment: Qt.AlignVCenter
                    player: root.player
                    onClicked: root.mediaRequested()
                }

                // The current time, such as 14:05.
                UiText {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: 6
                    Layout.rightMargin: 6
                    text: Qt.formatDateTime(clock.date, "HH:mm")
                    font.pixelSize: Theme.scaled(12)
                    font.weight: Font.DemiBold
                }

                // Opens the drop-down with every tray icon. It shows even when
                // no program has a tray icon, and the drop-down then says so.
                IconButton {
                    id: trayButton

                    Layout.alignment: Qt.AlignVCenter
                    // A chevron that points up while the drop-down is open.
                    glyph: root.trayShown ? "" : ""
                    glyphFontFamily: Theme.iconFontFamily
                    glyphSize: Theme.topBarIconSize
                    highlighted: root.trayShown
                    tooltip: "Tray"
                    onClicked: root.trayRequested()
                }

                // The usage gauges. Clicking one opens the activity monitor
                // with that measure chosen.
                UsageGauge {
                    Layout.alignment: Qt.AlignVCenter
                    iconGlyph: "\uf2db"
                    label: "CPU"
                    value: SystemUsage.cpu
                    onClicked: root.activityRequested("cpu")
                }

                UsageGauge {
                    Layout.alignment: Qt.AlignVCenter
                    iconGlyph: "\uf538"
                    label: "RAM"
                    value: SystemUsage.memory
                    onClicked: root.activityRequested("memory")
                    valueText: SystemUsage.memoryText(SystemUsage.memoryUsed, SystemUsage.memoryTotal)
                }

                UsageGauge {
                    Layout.alignment: Qt.AlignVCenter
                    visible: SystemUsage.gpuAvailable
                    iconGlyph: "\ue163"
                    label: "GPU"
                    value: SystemUsage.gpu
                    onClicked: root.activityRequested("gpu")
                }

                UsageGauge {
                    Layout.alignment: Qt.AlignVCenter
                    visible: SystemUsage.vramAvailable
                    iconGlyph: "\uf538"
                    label: "VRAM"
                    value: SystemUsage.vram
                    onClicked: root.activityRequested("vram")
                    valueText: SystemUsage.memoryText(SystemUsage.vramUsed, SystemUsage.vramTotal)
                }

                IconButton {
                    glyph: "\uf013"
                    glyphFontFamily: Theme.iconFontFamily
                    glyphSize: Theme.topBarIconSize
                    tooltip: "Settings"
                    onClicked: root.settingsRequested()
                }

                IconButton {
                    glyph: "\uf011"
                    glyphFontFamily: Theme.iconFontFamily
                    glyphSize: Theme.topBarIconSize
                    tooltip: "Power"
                    onClicked: root.powerRequested()
                }
            }
        }
    }
}
