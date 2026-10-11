import QtQuick

Item {
    id: root

    property var levels: AudioSpectrum.values
    property var player: null
    readonly property bool active: player !== null && player.isPlaying
    property real reveal: active ? 1 : 0
    readonly property string sourceText: {
        if (!player)
            return "No active media";

        const title = player.trackTitle || player.identity || "Unknown source";
        const artist = player.trackArtist || "";
        return artist.length > 0 ? `${title} · ${artist}` : title;
    }

    signal clicked()

    implicitWidth: Theme.scaled(300) * reveal
    implicitHeight: Theme.scaled(30)
    visible: reveal > 0
    enabled: active
    clip: true

    Behavior on reveal {
        NumberAnimation {
            duration: 240
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        anchors.right: parent.right
        width: Theme.scaled(300)
        height: parent.height
        opacity: root.reveal
        scale: 0.85 + 0.15 * root.reveal
        transformOrigin: Item.Right
        radius: Theme.radius - 5
        color: Theme.panelOverlay
        border.color: Theme.outlineTranslucent
        border.width: Theme.compactOutlineWidth

        IconButton {
            id: playbackButton

            anchors {
                left: parent.left
                leftMargin: 4
                verticalCenter: parent.verticalCenter
            }
            buttonSize: Theme.scaled(26)
            restingColor: Theme.panelOverlay
            glyphSize: Theme.topBarIconSize
            enabled: root.player !== null && root.player.canTogglePlaying
            hoverBackground: false
            glyph: root.player && root.player.isPlaying ? "\uf04c" : "\uf04b"
            glyphFontFamily: Theme.iconFontFamily
            onClicked: root.player.togglePlaying()
        }

        Item {
            id: visualizerPane

            anchors {
                left: playbackButton.right
                leftMargin: 4
                right: parent.right
                rightMargin: Theme.compactOutlineWidth
                top: parent.top
                topMargin: Theme.compactOutlineWidth
                bottom: parent.bottom
                bottomMargin: Theme.compactOutlineWidth
            }
            clip: true

            Row {
                id: spectrum

                anchors {
                    fill: parent
                    margins: 4
                }
                spacing: 2

                Repeater {
                    model: root.levels

                    Rectangle {
                        required property real modelData

                        anchors.verticalCenter: parent.verticalCenter
                        width: (parent.width - parent.spacing * (Theme.spectrumBars - 1)) / Theme.spectrumBars
                        height: Math.max(2, modelData * parent.height)
                        color: Theme.accent

                        Behavior on height {
                            NumberAnimation { duration: 45 }
                        }
                    }
                }
            }

            Rectangle {
                anchors.fill: parent
                color: Theme.panelOverlay
            }

            Item {
                id: sourceViewport

                anchors {
                    left: parent.left
                    leftMargin: 8
                    right: parent.right
                    rightMargin: 8
                    verticalCenter: parent.verticalCenter
                }
                height: sourceLabel.implicitHeight
                clip: true

                UiText {
                    id: sourceLabel

                    anchors.verticalCenter: parent.verticalCenter
                    text: root.sourceText
                    color: Theme.text
                    font.pixelSize: Theme.scaled(11)
                    font.weight: Font.Medium
                    x: sourceLabel.implicitWidth > sourceViewport.width ? sourceViewport.width : 0
                }

                SequentialAnimation {
                    id: sourceMarquee

                    running: root.active && sourceLabel.implicitWidth > sourceViewport.width
                    loops: Animation.Infinite

                    PauseAnimation { duration: 400 }
                    NumberAnimation {
                        target: sourceLabel
                        property: "x"
                        from: sourceViewport.width
                        to: -sourceLabel.implicitWidth
                        duration: Math.max(4500, (sourceViewport.width + sourceLabel.implicitWidth) * 32)
                        easing.type: Easing.Linear
                    }
                    PauseAnimation { duration: 500 }
                }
            }

            MouseArea {
                id: visualizerMouse

                anchors.fill: parent
                onClicked: root.clicked()
            }
        }
    }
}
