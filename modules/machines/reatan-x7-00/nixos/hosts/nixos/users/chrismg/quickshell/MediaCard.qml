pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

// The now-playing window: the cover, title, and artist of the playing track,
// playback buttons, and moving bars from the audio. The media button in the
// bar opens it while something plays. shell.qml creates it while it is open
// and destroys it when it closes or the music stops.
//
// It is a normal window, not a panel, like the activity monitor. niri places
// it, focuses it, moves it with Mod and a drag, and closes it with Mod+Q.
// niri.nix makes it float and blurs what is behind it.
FloatingWindow {
    id: root

    property var player: null

    signal closeRequested()

    // niri.nix matches this title to make the window float.
    title: "Now playing"
    implicitWidth: Theme.mediaWidth
    implicitHeight: Theme.mediaHeight
    minimumSize: Qt.size(Theme.scaled(340), Theme.scaled(240))
    // The Rectangle below draws the see-through background.
    color: "transparent"

    // Closing the window from niri, such as with Mod+Q, hides it. Tell
    // shell.qml, so the media button opens it again.
    onVisibleChanged: {
        if (!visible)
            closeRequested();
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.panel

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                ClippingRectangle {
                    Layout.preferredWidth: 64
                    Layout.preferredHeight: 64
                    color: Theme.surfaceRaised

                    Image {
                        anchors.fill: parent
                        source: root.player ? root.player.trackArtUrl : ""
                        fillMode: Image.PreserveAspectCrop
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    UiText {
                        text: "NOW PLAYING"
                        color: Theme.accent
                        font.pixelSize: Theme.scaled(10)
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1
                    }

                    UiText {
                        Layout.fillWidth: true
                        text: root.player ? root.player.trackTitle || "Unknown title" : ""
                        font.pixelSize: Theme.scaled(15)
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    UiText {
                        Layout.fillWidth: true
                        text: root.player ? root.player.trackArtist || root.player.identity : ""
                        color: Theme.textMuted
                        font.pixelSize: Theme.scaled(12)
                        elide: Text.ElideRight
                    }
                }

                IconButton {
                    glyph: "\uf00d"
                    glyphFontFamily: Theme.iconFontFamily
                    tooltip: "Hide media"
                    onClicked: root.closeRequested()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Theme.outline
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 12

                IconButton {
                    enabled: root.player !== null && root.player.canGoPrevious
                    glyph: "\uf048"
                    glyphFontFamily: Theme.iconFontFamily
                    restingColor: Theme.subtleButton
                    tooltip: "Previous"
                    onClicked: root.player.previous()
                }

                IconButton {
                    enabled: root.player !== null && root.player.canSeek
                    glyph: "-10"
                    restingColor: Theme.subtleButton
                    tooltip: "Back 10 seconds"
                    onClicked: root.player.seek(-10)
                }

                IconButton {
                    buttonSize: Theme.scaled(44)
                    highlighted: true
                    enabled: root.player !== null && root.player.canTogglePlaying
                    glyph: root.player && root.player.isPlaying ? "\uf04c" : "\uf04b"
                    glyphFontFamily: Theme.iconFontFamily
                    tooltip: root.player && root.player.isPlaying ? "Pause" : "Play"
                    onClicked: root.player.togglePlaying()
                }

                IconButton {
                    enabled: root.player !== null && root.player.canSeek
                    glyph: "+10"
                    restingColor: Theme.subtleButton
                    tooltip: "Forward 10 seconds"
                    onClicked: root.player.seek(10)
                }

                IconButton {
                    enabled: root.player !== null && root.player.canGoNext
                    glyph: "\uf051"
                    glyphFontFamily: Theme.iconFontFamily
                    restingColor: Theme.subtleButton
                    tooltip: "Next"
                    onClicked: root.player.next()
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.player !== null && root.player.isPlaying

                Row {
                    id: waveform

                    anchors.fill: parent
                    spacing: 4

                    // A fixed number of bars, each reading its own entry of
                    // AudioSpectrum.mediaValues by index. That list is replaced
                    // on every cava frame, so using it as the model would
                    // rebuild every bar each frame. See AudioVisualizer.qml.
                    Repeater {
                        model: Theme.mediaSpectrumBars

                        Item {
                            id: waveformBar

                            required property int index
                            readonly property real level: AudioSpectrum.mediaValues[index] ?? 0

                            width: (waveform.width - waveform.spacing * (Theme.mediaSpectrumBars - 1)) / Theme.mediaSpectrumBars
                            height: waveform.height

                            Rectangle {
                                anchors.bottom: parent.bottom
                                width: parent.width
                                height: Math.max(4, waveformBar.level * parent.height)
                                color: Theme.accent

                                Behavior on height {
                                    NumberAnimation { duration: 45 }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
