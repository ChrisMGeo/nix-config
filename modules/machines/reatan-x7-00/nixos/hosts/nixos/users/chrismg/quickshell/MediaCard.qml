pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

DraggablePanel {
    id: root

    property var player: null
    property bool settingsOpen: false

    signal closeRequested()

    minimumPanelWidth: Theme.scaled(340)
    minimumPanelHeight: Theme.scaled(240)
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.panel
        border.color: Theme.outline
        border.width: Theme.outlineWidth

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
                    radius: 7
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
                    buttonRadius: 0
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
                    buttonRadius: 0
                    restingColor: Theme.subtleButton
                    tooltip: "Previous"
                    onClicked: root.player.previous()
                }

                IconButton {
                    enabled: root.player !== null && root.player.canSeek
                    glyph: "-10"
                    buttonRadius: 0
                    restingColor: Theme.subtleButton
                    tooltip: "Back 10 seconds"
                    onClicked: root.player.seek(-10)
                }

                IconButton {
                    buttonSize: Theme.scaled(44)
                    buttonRadius: 0
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
                    buttonRadius: 0
                    restingColor: Theme.subtleButton
                    tooltip: "Forward 10 seconds"
                    onClicked: root.player.seek(10)
                }

                IconButton {
                    enabled: root.player !== null && root.player.canGoNext
                    glyph: "\uf051"
                    glyphFontFamily: Theme.iconFontFamily
                    buttonRadius: 0
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

                    Repeater {
                        model: AudioSpectrum.mediaValues

                        Item {
                            id: waveformBar

                            required property real modelData

                            width: (waveform.width - waveform.spacing * (Theme.mediaSpectrumBars - 1)) / Theme.mediaSpectrumBars
                            height: waveform.height

                            Rectangle {
                                anchors.bottom: parent.bottom
                                width: parent.width
                                height: Math.max(4, waveformBar.modelData * parent.height)
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
