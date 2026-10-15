pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire

// The list of audio outputs in the Sound section of the settings drawer, such
// as speakers, HDMI, and Bluetooth headphones. Clicking one makes it the
// default output, and WirePlumber moves the playing sound to it.
Column {
    id: root

    // Every output device. Streams, such as a browser tab playing sound, are
    // PipeWire nodes too, so they are left out. The default output comes first.
    readonly property var outputs: Pipewire.nodes.values
        .filter(node => node.isSink && !node.isStream && node.audio !== null)
        .sort((a, b) => (b === Pipewire.defaultAudioSink) - (a === Pipewire.defaultAudioSink)
            || label(a).localeCompare(label(b)))

    bottomPadding: 8

    // The name to show for a node. `description` is the readable one, such as
    // "Bose QC Headphones". The others are fallbacks.
    function label(node) {
        return node?.description || node?.nickname || node?.name || "";
    }

    UiText {
        x: 12
        text: "OUTPUT"
        color: Theme.textMuted
        font.pixelSize: Theme.scaled(10)
        font.weight: Font.DemiBold
        font.letterSpacing: 1
        bottomPadding: 4
    }

    Repeater {
        // ScriptModel keeps each row when the order changes.
        model: ScriptModel {
            values: root.outputs
        }

        Rectangle {
            id: outputRow

            required property var modelData
            // `?.` reads a property only when the node is there. An output that
            // goes away, such as headphones that disconnect, is deleted a moment
            // before its row.
            readonly property var node: modelData
            readonly property bool current: node !== null && node === Pipewire.defaultAudioSink

            x: 6
            width: root.width - 12
            height: Theme.scaled(34)
            radius: Theme.radius - 5
            color: outputMouse.containsMouse ? Theme.subtleButton : "transparent"

            MouseArea {
                id: outputMouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: outputRow.current ? Qt.ArrowCursor : Qt.PointingHandCursor
                // Saves the choice, so WirePlumber picks this output again
                // when it comes back, such as when the headphones reconnect.
                onClicked: Pipewire.preferredDefaultAudioSink = outputRow.node
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 10

                // A filled circle marks the current output, like a radio button.
                UiText {
                    Layout.preferredWidth: Theme.scaled(14)
                    text: outputRow.current ? "" : ""
                    color: outputRow.current ? Theme.accent : Theme.textMuted
                    font.family: Theme.iconFontFamily
                    font.pixelSize: Theme.scaled(11)
                    font.weight: outputRow.current ? Font.Black : Font.Normal
                    opacity: outputRow.current ? 1 : 0.5
                    horizontalAlignment: Text.AlignHCenter
                }

                UiText {
                    Layout.fillWidth: true
                    text: root.label(outputRow.node)
                    color: outputRow.current ? Theme.accent : Theme.text
                    font.weight: outputRow.current ? Font.DemiBold : Font.Normal
                    elide: Text.ElideRight
                }
            }
        }
    }
}
