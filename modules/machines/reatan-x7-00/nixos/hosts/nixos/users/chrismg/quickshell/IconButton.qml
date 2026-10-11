import QtQuick
import Quickshell.Widgets

Item {
    id: root

    property url iconSource
    property string glyph: ""
    property string glyphFontFamily: Theme.fontFamily
    property int iconSize: Theme.scaled(17)
    property int glyphSize: Theme.scaled(root.glyph.length > 2 ? 10 : 16)
    property string tooltip
    property int buttonSize: Theme.scaled(28)
    property int buttonRadius: Theme.radius - 5
    property bool highlighted: false
    property bool hoverBackground: true
    property color restingColor: "transparent"
    property int acceptedButtons: Qt.LeftButton

    signal clicked(var mouse)

    implicitWidth: buttonSize
    implicitHeight: buttonSize

    Rectangle {
        anchors.fill: parent
        radius: root.buttonRadius
        color: root.highlighted
            ? Theme.accent
            : root.hoverBackground && buttonMouse.containsMouse ? Theme.surfaceHover : root.restingColor

        IconImage {
            id: icon

            anchors.centerIn: parent
            width: root.iconSize
            height: root.iconSize
            source: root.iconSource
            opacity: root.enabled ? 1 : 0.35
            visible: root.iconSource.toString().length > 0 && status !== Image.Error
        }

        UiText {
            anchors.centerIn: parent
            visible: !icon.visible
            text: root.glyph
            color: root.highlighted ? Theme.accentText : Theme.text
            opacity: root.enabled ? 1 : 0.35
            font.family: root.glyphFontFamily
            font.pixelSize: root.glyphSize
            font.weight: Font.DemiBold
        }
    }

    MouseArea {
        id: buttonMouse

        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        acceptedButtons: root.acceptedButtons
        onClicked: mouse => root.clicked(mouse)

    }
}
