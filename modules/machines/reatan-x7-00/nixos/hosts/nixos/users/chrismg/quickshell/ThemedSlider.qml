import QtQuick
import QtQuick.Controls

// A slider drawn in the Stylix theme colors instead of the default Qt style,
// whose blue ignores the theme. The filled part and the knob use the accent
// color, and the empty part uses the raised surface color. A disabled slider
// is dimmed.
Slider {
    id: root

    opacity: enabled ? 1 : 0.4
    implicitHeight: Theme.scaled(20)

    // The track: a thin rounded bar across the middle of the slider.
    background: Rectangle {
        x: root.leftPadding
        y: root.topPadding + (root.availableHeight - height) / 2
        width: root.availableWidth
        height: Theme.scaled(4)
        radius: height / 2
        color: Theme.surfaceRaised

        // The filled part, from the left end to the knob.
        Rectangle {
            width: root.visualPosition * parent.width
            height: parent.height
            radius: parent.radius
            color: Theme.accent
        }
    }

    // The knob. It grows a little while hovered or dragged, so it is clear
    // that it can be moved.
    handle: Rectangle {
        readonly property int size: Theme.scaled(root.pressed || root.hovered ? 14 : 12)

        x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
        y: root.topPadding + (root.availableHeight - height) / 2
        width: size
        height: size
        radius: size / 2
        color: Theme.accent
        border.width: Theme.compactOutlineWidth
        border.color: Theme.panelSolid

        Behavior on width {
            NumberAnimation { duration: 80 }
        }
    }
}
