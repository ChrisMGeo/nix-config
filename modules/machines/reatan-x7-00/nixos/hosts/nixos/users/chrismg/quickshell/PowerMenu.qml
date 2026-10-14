pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// The menu under the bar's power button: lock, log out, restart, and shut down.
// Lock acts on the first click. The others ask for a second click within a few
// seconds, so one stray click does nothing.
PanelWindow {
    id: root

    // The action waiting for its second click, or "" when none is.
    property string armedAction: ""

    signal closeRequested()

    readonly property var actions: [
        {
            id: "lock",
            label: "Lock",
            glyph: "",
            // Asks logind to lock. swayidle then starts swaylock. See ../lock.nix.
            command: ["loginctl", "lock-session"],
            confirm: false
        },
        {
            id: "logout",
            label: "Log out",
            glyph: "",
            // Ends the niri session and returns to the login screen.
            command: ["niri", "msg", "action", "quit", "--skip-confirmation"]
        },
        {
            id: "reboot",
            label: "Restart",
            glyph: "",
            command: ["systemctl", "reboot"]
        },
        {
            id: "poweroff",
            label: "Shut down",
            glyph: "",
            command: ["systemctl", "poweroff"]
        }
    ]

    function activate(action) {
        // `confirm: false` skips the second click. Every other action needs it.
        if (action.confirm !== false && armedAction !== action.id) {
            armedAction = action.id;
            disarmTimer.restart();
            return;
        }

        armedAction = "";
        root.closeRequested();
        Quickshell.execDetached(action.command);
    }

    // Forget a half-finished choice when the menu closes.
    onVisibleChanged: {
        if (!visible)
            armedAction = "";
    }

    implicitWidth: Theme.scaled(200)
    implicitHeight: column.implicitHeight + 16
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        right: true
    }

    margins {
        top: Theme.barHeight + Theme.outerMargin * 2
        right: Theme.outerMargin
    }

    // Asks niri to blur what is behind the whole window, with the same rounded
    // corners as the panel, for a frosted glass look. Theme.panel is
    // see-through, so the blur shows. Only this region is blurred.
    BackgroundEffect.blurRegion: Region {
        width: root.width
        height: root.height
        radius: Theme.radius
    }

    Timer {
        id: disarmTimer

        interval: 3000
        onTriggered: root.armedAction = ""
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.panel
        border.color: Theme.outline
        border.width: Theme.compactOutlineWidth

        ColumnLayout {
            id: column

            anchors {
                fill: parent
                margins: 8
            }
            spacing: 4

            Repeater {
                model: root.actions

                Rectangle {
                    id: actionRow

                    required property var modelData
                    readonly property bool armed: root.armedAction === modelData.id

                    Layout.fillWidth: true
                    Layout.preferredHeight: Theme.scaled(34)
                    radius: Theme.radius - 4
                    color: armed
                        ? Theme.accent
                        : actionMouse.containsMouse ? Theme.surfaceHover : "transparent"

                    RowLayout {
                        anchors {
                            fill: parent
                            leftMargin: 10
                            rightMargin: 10
                        }
                        spacing: 10

                        UiText {
                            Layout.preferredWidth: Theme.scaled(16)
                            horizontalAlignment: Text.AlignHCenter
                            text: actionRow.modelData.glyph
                            color: actionRow.armed ? Theme.accentText : Theme.text
                            font.family: Theme.iconFontFamily
                            font.pixelSize: Theme.topBarIconSize
                        }

                        UiText {
                            Layout.fillWidth: true
                            text: actionRow.armed ? `Click again to ${actionRow.modelData.label.toLowerCase()}` : actionRow.modelData.label
                            color: actionRow.armed ? Theme.accentText : Theme.text
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: actionMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.activate(actionRow.modelData)
                    }
                }
            }
        }
    }
}
