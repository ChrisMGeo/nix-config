import QtQuick
import QtQuick.Controls

// A text box in the theme colors. Use it instead of the plain `TextField`,
// whose default style is blue. The Wi-Fi password form uses it, and so does
// the login screen, with a larger size.
TextField {
    id: root

    // The height of the box.
    property int boxHeight: Theme.scaled(30)

    color: Theme.text
    placeholderTextColor: Theme.textMuted
    selectionColor: Theme.accent
    selectedTextColor: Theme.accentText
    font.family: Theme.fontFamily
    font.pixelSize: Theme.scaled(12)
    leftPadding: 8
    rightPadding: 8

    background: Rectangle {
        implicitHeight: root.boxHeight
        color: Theme.subtleButton
        border.color: root.activeFocus ? Theme.accent : Theme.outlineTranslucent
        border.width: Theme.outlineWidth
    }
}
