import QtQuick

// A small rounded button with a word on it, such as "Join" or "Connect".
// `primary` fills it with the accent color for the main action in a row.
Rectangle {
    id: root

    property string text
    property bool primary: false

    signal clicked()

    implicitWidth: label.implicitWidth + Theme.scaled(20)
    implicitHeight: Theme.scaled(26)
    radius: Theme.radius - 5
    opacity: enabled ? 1 : 0.4
    color: primary
        ? Theme.accent
        : buttonMouse.containsMouse ? Theme.surfaceHover : Theme.subtleButton

    UiText {
        id: label

        anchors.centerIn: parent
        text: root.text
        color: root.primary ? Theme.accentText : Theme.text
        font.pixelSize: Theme.scaled(11)
        font.weight: Font.DemiBold
    }

    MouseArea {
        id: buttonMouse

        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
