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
    // Whether the menu is open, set by shell.qml. A hidden bar hides an open
    // menu, so `visible` is false then while this stays true.
    property bool open: false
    // Whether this window has the keyboard. shell.qml uses it to notice a
    // click away.
    readonly property bool hasKeyboard: menuPanel.windowActive

    signal closeRequested()
    // Escape was pressed in the menu. shell.qml closes it through the same
    // path as closeRequested().
    signal escapePressed()

    readonly property var actions: [
        {
            id: "lock",
            label: "Lock",
            glyph: "",
            // Asks logind to lock. swayidle then starts swaylock. See ../lock.nix.
            command: [Theme.loginctlCommand, "lock-session"],
            confirm: false
        },
        {
            id: "logout",
            label: "Log out",
            glyph: "",
            // Ends the niri session and returns to the login screen.
            command: [Theme.niriCommand, "msg", "action", "quit", "--skip-confirmation"]
        },
        {
            id: "reboot",
            label: "Restart",
            glyph: "",
            command: [Theme.systemctlCommand, "reboot"]
        },
        {
            id: "poweroff",
            label: "Shut down",
            glyph: "",
            command: [Theme.systemctlCommand, "poweroff"]
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

    // Forget a half-finished choice when the menu closes. Hiding the
    // bar keeps it, and the 3 second timer still ends it.
    onOpenChanged: {
        if (!open)
            armedAction = "";
    }

    // The window is the panel plus Theme.glowReach of space on the left, top,
    // and bottom for the glow around it. On the right it reaches the screen
    // edge and the panel keeps Theme.outerMargin from it, so the glow has
    // room there too.
    implicitWidth: Theme.glowReach + menuPanel.width + Theme.outerMargin
    implicitHeight: menuPanel.height + Theme.glowReach * 2
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    // The menu can take the keyboard, for Escape. This is on-demand focus:
    // niri gives the menu the keyboard when it appears, so Escape works
    // without a click first. It keeps the keyboard until a click on another
    // window, which shell.qml treats as a click away.
    focusable: true

    anchors {
        top: true
        right: true
    }

    // The panel's top is at Theme.menuTop, like the other menus under the
    // bar. The window starts Theme.glowReach above that, to fit the glow.
    margins {
        top: Theme.menuTop - Theme.glowReach
    }

    // Asks niri to blur what is behind the panel, for a frosted glass look.
    // Theme.panel is see-through, so the blur shows. Only this region is
    // blurred, so the glow space around the panel stays clear.
    BackgroundEffect.blurRegion: Region {
        item: menuPanel
    }

    // Only the panel takes clicks. Clicks on the glow around it go through
    // to the windows below.
    mask: Region {
        item: menuPanel
    }

    Timer {
        id: disarmTimer

        interval: 3000
        onTriggered: root.armedAction = ""
    }

    PanelGlow {
        target: menuPanel
    }

    Rectangle {
        id: menuPanel

        x: Theme.glowReach
        y: Theme.glowReach
        width: Theme.scaled(200)
        height: column.implicitHeight + 16
        color: Theme.panel

        // Whether the window has the keyboard. The attached `Window` must be
        // read from an item, which tells it its window.
        readonly property bool windowActive: Window.active

        // A Shortcut works wherever the keyboard focus is in the window.
        Shortcut {
            sequence: "Escape"
            enabled: root.visible
            onActivated: root.escapePressed()
        }

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
