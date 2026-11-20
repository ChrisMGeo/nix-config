import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

Item {
    id: root

    property url iconSource
    property string glyph: ""
    property string glyphFontFamily: Theme.fontFamily
    property int iconSize: Theme.scaled(17)
    property int glyphSize: Theme.scaled(root.glyph.length > 2 ? 10 : 16)
    // A short label that shows under the button after the mouse rests on it.
    // Leave it empty for no label.
    property string tooltip
    property int buttonSize: Theme.scaled(28)
    property bool highlighted: false
    property bool hoverBackground: true
    property color restingColor: "transparent"
    property int acceptedButtons: Qt.LeftButton
    // Whether the mouse rests on a button that has a label. The label waits
    // half a second, so it does not flash while the mouse passes over the
    // button. A click hides it until the mouse leaves.
    readonly property bool tooltipWanted: buttonMouse.containsMouse && !buttonMouse.pressed && tooltip.length > 0
    property bool tooltipShown: false

    signal clicked(var mouse)

    onTooltipWantedChanged: if (!tooltipWanted) tooltipShown = false

    implicitWidth: buttonSize
    implicitHeight: buttonSize

    Rectangle {
        anchors.fill: parent
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
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: root.acceptedButtons
        onClicked: mouse => root.clicked(mouse)
    }

    // Shows the label once the mouse has rested for half a second.
    Timer {
        interval: 500
        running: root.tooltipWanted && !root.tooltipShown
        onTriggered: root.tooltipShown = true
    }

    // The label, in its own small window under the button, like the gauge
    // tooltips in UsageGauge.qml.
    PopupWindow {
        id: tooltipWindow

        anchor.item: root
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom
        anchor.margins.bottom: -Theme.scaled(6)
        visible: root.visible && root.tooltipShown
        color: "transparent"
        // Never 0 wide or high, even for a moment. See AGENTS.md.
        implicitWidth: Math.max(1, tooltipText.implicitWidth + Theme.scaled(16))
        implicitHeight: Math.max(1, tooltipText.implicitHeight + Theme.scaled(10))

        // Blurs what is behind the label, for a frosted glass look. See
        // Theme.panel.
        BackgroundEffect.blurRegion: Region {
            width: tooltipWindow.width
            height: tooltipWindow.height
        }

        Rectangle {
            anchors.fill: parent
            color: Theme.panel

            UiText {
                id: tooltipText

                anchors.centerIn: parent
                text: root.tooltip
                font.pixelSize: Theme.scaled(11)
            }
        }
    }
}
