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
    // Set by shell.qml: true while the toggle key, the overview, a workspace
    // change, or an open drawer asks for the bar.
    property bool shown: false
    // Whether the tray drop-down is open. The tray button toggles it.
    property bool trayOpen: false
    // Whether the bar is on screen. Hovering the top edge, or the bar itself,
    // also keeps it there, and so does an open tray drop-down.
    readonly property bool revealed: shown || trayOpen || hover.hovered || hideDelay.running
    // Space between a panel's outline and its contents, in pixels.
    readonly property int sectionPadding: 6

    signal workspaceRequested(int number)
    signal settingsRequested()
    signal powerRequested()
    signal mediaRequested()

    // The bar floats over windows instead of pushing them down. Ignore reserves
    // no space and lets the window reach the very top edge of the screen, where
    // the mouse can touch it. Setting exclusiveZone would undo this.
    implicitHeight: Theme.barTopGap + Theme.barHeight
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        left: true
        right: true
    }

    margins {
        left: Theme.outerMargin
        right: Theme.outerMargin
    }

    // The parts of the window that take the mouse. Clicks anywhere else go
    // through to the windows below. While hidden, only a 2 pixel strip along
    // the top edge does. While shown, the gap above the bar and the two panels
    // do too.
    mask: Region {
        x: 0
        y: 0
        width: root.width
        height: root.revealed ? Theme.barTopGap : 2

        Region {
            x: workspacePanel.x
            y: Theme.barTopGap
            width: root.revealed ? workspacePanel.width : 0
            height: Theme.barHeight
        }

        Region {
            x: statusPanel.x
            y: Theme.barTopGap
            width: root.revealed ? statusPanel.width : 0
            height: Theme.barHeight
        }
    }

    // Asks niri to blur what is behind each of the two panels, with their
    // rounded corners, for a frosted glass look. The gaps between panels stay
    // clear. Theme.panel is see-through, so the blur shows. `slide.y` moves
    // the blur with the panels while they slide in and out. A child Region adds
    // its area to the one above it, and the empty top Region adds nothing.
    BackgroundEffect.blurRegion: Region {
        Region {
            x: workspacePanel.x
            y: Theme.barTopGap + slide.y
            width: workspacePanel.width
            height: Theme.barHeight
            radius: Theme.radius
        }

        Region {
            x: statusPanel.x
            y: Theme.barTopGap + slide.y
            width: statusPanel.width
            height: Theme.barHeight
            radius: Theme.radius
        }
    }

    // Tracks whether the mouse is over the window's mask.
    Item {
        anchors.fill: parent

        HoverHandler {
            id: hover

            // When the mouse leaves, wait a moment before hiding, so moving
            // across the gaps between panels does not make the bar flicker.
            onHoveredChanged: {
                if (!hovered)
                    hideDelay.restart();
            }
        }
    }

    Timer {
        id: hideDelay

        interval: 400
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
        visible: root.trayOpen
        onCloseRequested: root.trayOpen = false
    }

    // The bar is drawn as two separate panels with empty space between them:
    // the workspaces on the left, and the visualizer, clock, tray, gauges, and
    // buttons on the right. They share this one window, so menus open in the
    // same place as before.
    Item {
        id: bar

        x: 0
        y: Theme.barTopGap
        width: parent.width
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

        // The left panel: the workspace buttons of this monitor.
        Rectangle {
            id: workspacePanel

            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
            }
            width: workspaceRow.implicitWidth + root.sectionPadding * 2
            radius: Theme.radius
            color: Theme.panel
            border.color: Theme.outline
            border.width: Theme.outlineWidth

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
                        radius: 7
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
                            radius: 2
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
            radius: Theme.radius
            color: Theme.panel
            border.color: Theme.outline
            border.width: Theme.outlineWidth

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
                    glyph: root.trayOpen ? "" : ""
                    glyphFontFamily: Theme.iconFontFamily
                    glyphSize: Theme.topBarIconSize
                    highlighted: root.trayOpen
                    tooltip: "Tray"
                    onClicked: root.trayOpen = !root.trayOpen
                }

                UsageGauge {
                    Layout.alignment: Qt.AlignVCenter
                    iconGlyph: "\uf2db"
                    label: "CPU"
                    value: SystemUsage.cpu
                }

                UsageGauge {
                    Layout.alignment: Qt.AlignVCenter
                    iconGlyph: "\uf538"
                    label: "RAM"
                    value: SystemUsage.memory
                    valueText: SystemUsage.memoryText(SystemUsage.memoryUsed, SystemUsage.memoryTotal)
                }

                UsageGauge {
                    Layout.alignment: Qt.AlignVCenter
                    visible: SystemUsage.gpuAvailable
                    iconGlyph: "\ue163"
                    label: "GPU"
                    value: SystemUsage.gpu
                }

                UsageGauge {
                    Layout.alignment: Qt.AlignVCenter
                    visible: SystemUsage.vramAvailable
                    iconGlyph: "\uf538"
                    label: "VRAM"
                    value: SystemUsage.vram
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
