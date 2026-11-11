pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

// The volume mixer: a popup beside the settings drawer, opened from the Sound
// section, with a volume slider and a mute button for each program. Programs
// whose volume was set here stay listed after they stop playing, so their
// volume can be changed before they play again. AppVolumes.qml remembers the
// volumes.
PopupWindow {
    id: root

    // The settings drawer, which the popup sits beside.
    property var parentWindow

    signal closeRequested()

    // Opens to the left of the drawer's panel, lined up with its top. The
    // anchor is the panel's left edge, Theme.glowReach above its top, where
    // the drawer's window starts. `gravity` makes the popup grow left and down
    // from there, so this panel's top also sits Theme.glowReach down.
    anchor.window: parentWindow
    anchor.rect.x: parentWindow ? parentWindow.panel.x : 0
    anchor.rect.y: 0
    anchor.rect.width: 1
    anchor.rect.height: 1
    anchor.edges: Edges.Top | Edges.Left
    anchor.gravity: Edges.Bottom | Edges.Left
    color: "transparent"
    // The window is the panel plus Theme.glowReach on the left, top, and
    // bottom for the glow around it, and a gap on the right. The gap is the
    // transparent strip between this panel and the drawer's.
    implicitWidth: Theme.glowReach + Theme.drawerWidth + Theme.gap
    implicitHeight: panel.height + Theme.glowReach * 2

    // Blurs what is behind the panel, for a frosted glass look. See
    // Theme.panel. The gap and the glow space are left out.
    BackgroundEffect.blurRegion: Region {
        item: panel
    }

    // Only the panel takes clicks.
    mask: Region {
        item: panel
    }

    PanelGlow {
        target: panel
    }

    Rectangle {
        id: panel

        x: Theme.glowReach
        y: Theme.glowReach
        width: Theme.drawerWidth
        // As tall as the rows need, but no taller than the drawer's panel.
        // Wayland stops the whole bar with an error if a popup has no height,
        // which can happen for a moment while the drawer is still being sized,
        // so it is never shorter than 120 pixels.
        height: Math.max(Theme.scaled(120),
            Math.min(column.implicitHeight + 24, parentWindow ? parentWindow.panel.height : Theme.scaled(500)))
        color: Theme.panel

        ColumnLayout {
            id: column

            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            RowLayout {
                Layout.fillWidth: true

                UiText {
                    Layout.fillWidth: true
                    text: "Volume mixer"
                    color: Theme.accent
                    font.pixelSize: Theme.scaled(16)
                    font.weight: Font.DemiBold
                }

                IconButton {
                    glyph: ""
                    glyphFontFamily: Theme.iconFontFamily
                    tooltip: "Close volume mixer"
                    onClicked: root.closeRequested()
                }
            }

            // Shown in place of the rows while no program has played sound.
            UiText {
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.scaled(40)
                visible: AppVolumes.appKeys.length === 0
                text: "No programs are playing sound"
                color: Theme.textMuted
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: rows.implicitHeight
                visible: AppVolumes.appKeys.length > 0
                contentHeight: rows.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: rows

                    width: parent.width
                    spacing: 4

                    Repeater {
                        // The model is the list of program names. ScriptModel
                        // keeps a row while its name stays in the list, so a
                        // slider is not rebuilt in the middle of a drag.
                        model: ScriptModel {
                            values: AppVolumes.appKeys
                        }

                        Item {
                            id: appRow

                            required property string modelData
                            readonly property string key: modelData
                            readonly property var nodes: AppVolumes.nodesFor(key)
                            readonly property var entry: AppVolumes.saved[key] ?? null
                            readonly property bool running: nodes.length > 0
                            // A program with several streams shows the volume
                            // of the first one. Moving the slider sets them all.
                            readonly property real volume: running
                                ? nodes[0].audio.volume
                                : entry ? entry.volume : 1
                            readonly property bool muted: running
                                ? nodes[0].audio.muted
                                : entry ? entry.muted : false
                            readonly property string iconName: running
                                ? AppVolumes.iconOf(nodes[0]) || (entry ? entry.icon : "")
                                : entry ? entry.icon : ""
                            // What is playing, such as a video title, or that
                            // the program is not playing now.
                            readonly property string detail: running
                                ? nodes[0].properties["media.name"] || "Playing"
                                : "Not playing"

                            width: rows.width
                            height: Theme.scaled(58)

                            // `true` as the second argument returns an empty
                            // path when the theme has no such icon, so the
                            // fallback glyph shows instead.
                            readonly property string iconPath: iconName !== ""
                                ? Quickshell.iconPath(iconName.toLowerCase(), true)
                                : ""

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 4
                                anchors.rightMargin: 4
                                spacing: 8

                                Item {
                                    Layout.preferredWidth: Theme.scaled(28)
                                    Layout.preferredHeight: Theme.scaled(28)
                                    // Absent programs are dimmed.
                                    opacity: appRow.running ? 1 : 0.5

                                    IconImage {
                                        anchors.fill: parent
                                        visible: appRow.iconPath !== ""
                                        source: appRow.iconPath
                                    }

                                    UiText {
                                        anchors.centerIn: parent
                                        visible: appRow.iconPath === ""
                                        // A music note.
                                        text: ""
                                        color: Theme.textMuted
                                        font.family: Theme.iconFontFamily
                                        font.pixelSize: Theme.scaled(14)
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0

                                    RowLayout {
                                        Layout.fillWidth: true

                                        UiText {
                                            Layout.fillWidth: true
                                            text: appRow.key
                                            color: appRow.running ? Theme.text : Theme.textMuted
                                            font.weight: Font.DemiBold
                                            elide: Text.ElideRight
                                        }

                                        UiText {
                                            text: appRow.muted ? "Muted" : `${Math.round(appRow.volume * 100)}%`
                                            color: Theme.textMuted
                                            font.pixelSize: Theme.scaled(11)
                                        }
                                    }

                                    UiText {
                                        Layout.fillWidth: true
                                        text: appRow.detail
                                        color: Theme.textMuted
                                        font.pixelSize: Theme.scaled(10)
                                        elide: Text.ElideRight
                                    }

                                    ThemedSlider {
                                        Layout.fillWidth: true
                                        from: 0
                                        to: 1
                                        value: appRow.volume
                                        onMoved: AppVolumes.setVolume(appRow.key, value)
                                    }
                                }

                                IconButton {
                                    glyph: appRow.muted ? "" : ""
                                    glyphFontFamily: Theme.iconFontFamily
                                    tooltip: "Toggle mute"
                                    onClicked: AppVolumes.setMuted(appRow.key, !appRow.muted)
                                }

                                // Forgets a program that is not playing, which
                                // removes its row.
                                IconButton {
                                    visible: !appRow.running
                                    glyph: ""
                                    glyphFontFamily: Theme.iconFontFamily
                                    tooltip: "Forget this program"
                                    onClicked: AppVolumes.forget(appRow.key)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
