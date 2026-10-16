import QtQuick
import QtQuick.Controls

// An on and off switch drawn in the Stylix theme colors instead of the default
// Qt style, whose blue ignores the theme. It matches ThemedSlider.qml. When
// on, the track uses the accent color and the knob sits on the right in the
// background color. When off, the track is the raised surface color with an
// outline and the knob sits on the left in the muted text color. A disabled
// switch is dimmed.
Switch {
    id: root

    opacity: enabled ? 1 : 0.4

    // The switch is exactly the size of its track. The Qt style works out the
    // width from the label, and these switches have none, so without this the
    // switch is only as wide as its padding and the track spills past the
    // edge of the row.
    padding: 0
    spacing: 0
    implicitWidth: indicator.implicitWidth
    implicitHeight: indicator.implicitHeight

    // The track: a rounded pill.
    indicator: Rectangle {
        x: 0
        y: (root.height - height) / 2
        implicitWidth: Theme.scaled(34)
        implicitHeight: Theme.scaled(18)
        radius: height / 2
        color: root.checked ? Theme.accent : Theme.surfaceRaised
        border.width: Theme.compactOutlineWidth
        border.color: root.checked ? Theme.accent : Theme.outline

        Behavior on color {
            ColorAnimation { duration: 120 }
        }

        // The knob. It slides between the two ends of the track.
        Rectangle {
            readonly property int inset: Theme.scaled(3)

            x: root.checked ? parent.width - width - inset : inset
            anchors.verticalCenter: parent.verticalCenter
            width: parent.height - inset * 2
            height: width
            radius: width / 2
            color: root.checked ? Theme.accentText : Theme.textMuted

            Behavior on x {
                NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
            }
        }
    }

    // The switches here have no label, so there is no text to draw.
    contentItem: Item {}
}
