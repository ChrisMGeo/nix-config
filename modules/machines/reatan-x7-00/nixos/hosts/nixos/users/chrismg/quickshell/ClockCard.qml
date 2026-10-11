import QtQuick
import Quickshell
import Quickshell.Wayland

DraggablePanel {
    id: root

    minimumPanelWidth: Theme.scaled(240)
    minimumPanelHeight: Theme.scaled(132)
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Bottom

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.panel
        border.color: Theme.outline
        border.width: Theme.outlineWidth

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
