import QtQuick
import Quickshell

// The clock: a small window with the time and the date. shell.qml opens it
// when the bar starts.
//
// It is a normal window, not a panel, like the activity monitor. niri places
// it, focuses it, moves it with Mod and a drag, and closes it with Mod+Q.
// niri.nix makes it float and blurs what is behind it.
FloatingWindow {
    id: root

    signal closeRequested()

    // niri.nix matches this title to make the window float.
    title: "Clock"
    implicitWidth: Theme.clockWidth
    implicitHeight: Theme.clockHeight
    minimumSize: Qt.size(Theme.scaled(240), Theme.scaled(132))
    // The Rectangle below draws the see-through background.
    color: "transparent"

    // Closing the window from niri, such as with Mod+Q, hides it. Tell
    // shell.qml, so Mod+T opens it again.
    onVisibleChanged: {
        if (!visible)
            closeRequested();
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.panel

        Column {
            anchors.centerIn: parent
            spacing: 10

            UiText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(clock.date, "HH:mm:ss")
                font.pixelSize: Theme.scaled(50)
                font.weight: Font.Light
                font.letterSpacing: 2
            }

            UiText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(clock.date, "ddd, MMM d yyyy")
                color: Theme.textMuted
                font.pixelSize: Theme.scaled(17)
                font.letterSpacing: 1
            }
        }
    }
}
