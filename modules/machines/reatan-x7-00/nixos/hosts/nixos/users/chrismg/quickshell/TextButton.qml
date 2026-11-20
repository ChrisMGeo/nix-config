import QtQuick

// A small square button with a word on it, such as "Join" or "Connect".
// `primary` fills it with the accent color for the main action in a row.
// The login screen uses this file too, with a larger size.
Rectangle {
    id: root

    property string text
    property bool primary: false
    // The size of the word, the height of the button, and the space left and
    // right of the word.
    property int labelSize: Theme.scaled(11)
    property int buttonHeight: Theme.scaled(26)
    property int sidePadding: Theme.scaled(10)

    signal clicked()

    implicitWidth: label.implicitWidth + 2 * sidePadding
    implicitHeight: buttonHeight
    opacity: enabled ? 1 : 0.4
    color: primary
        ? Theme.accent
        : buttonMouse.containsMouse ? Theme.surfaceHover : Theme.subtleButton

    UiText {
        id: label

        anchors.centerIn: parent
        text: root.text
        color: root.primary ? Theme.accentText : Theme.text
        font.pixelSize: root.labelSize
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
