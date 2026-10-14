pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray

PanelWindow {
    id: root

    property var workspaces: [1, 2, 3, 4]
    property int activeWorkspace: 1
    property var occupiedWorkspaces: ({})
    property var player: null

    signal workspaceRequested(int number)
    signal settingsRequested()
    signal powerRequested()
    signal mediaRequested()

    implicitHeight: Theme.barHeight
    color: "transparent"
    exclusiveZone: Theme.barHeight + Theme.barBottomGap

    anchors {
        top: true
        left: true
        right: true
    }

    margins {
        top: Theme.barTopGap
        left: Theme.outerMargin
        right: Theme.outerMargin
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.panel
        border.color: Theme.outline
        border.width: Theme.outlineWidth

        Row {
            anchors {
                left: parent.left
                leftMargin: 6
                verticalCenter: parent.verticalCenter
            }
            width: Math.floor(root.width * 0.32)
            spacing: 2
            clip: true

            Repeater {
                model: SystemTray.items

                IconButton {
                    id: trayButton

                    required property var modelData

                    iconSource: modelData.icon
                    iconSize: Theme.topBarIconSize
                    glyphSize: Theme.topBarIconSize
                    tooltip: modelData.tooltipTitle || modelData.title
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

                    onClicked: mouse => {
                        const position = root.contentItem.mapFromItem(trayButton, 0, 0);
                        if (mouse.button === Qt.RightButton && modelData.hasMenu)
                            modelData.display(root, position.x, root.height);
                        else if (mouse.button === Qt.MiddleButton)
                            modelData.secondaryActivate();
                        else if (modelData.onlyMenu && modelData.hasMenu)
                            modelData.display(root, position.x, root.height);
                        else
                            modelData.activate();
                    }
                }
            }
        }

        Row {
            anchors.centerIn: parent
            spacing: 4

            Repeater {
                model: root.workspaces

                Rectangle {
                    id: workspaceButton

                    required property int modelData

                    width: Theme.scaled(32)
                    height: Theme.scaled(32)
                    radius: 7
                    color: modelData === root.activeWorkspace
                        ? Theme.accent
                        : workspaceMouse.containsMouse ? Theme.surfaceHover : Theme.surface

                    UiText {
                        id: workspaceNumber

                        anchors.centerIn: parent
                        text: workspaceButton.modelData
                        color: workspaceButton.modelData === root.activeWorkspace
                            ? Theme.accentText
                            : Theme.textMuted
                        font.pixelSize: Theme.scaled(12)
                        font.weight: Font.DemiBold
                    }

                    Rectangle {
                        anchors {
                            horizontalCenter: parent.horizontalCenter
                            top: workspaceNumber.bottom
                        }
                        width: 4
                        height: 4
                        radius: 2
                        visible: root.occupiedWorkspaces[String(workspaceButton.modelData)] === true
                        color: workspaceButton.modelData === root.activeWorkspace
                            ? Theme.accentText
                            : Theme.accent
                    }

                    MouseArea {
                        id: workspaceMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.workspaceRequested(workspaceButton.modelData)
                    }
                }
            }
        }

        RowLayout {
            anchors {
                right: parent.right
                rightMargin: 6
                verticalCenter: parent.verticalCenter
            }
            spacing: 2

            AudioVisualizer {
                Layout.alignment: Qt.AlignVCenter
                player: root.player
                onClicked: root.mediaRequested()
            }

            UsageGauge {
                Layout.alignment: Qt.AlignVCenter
                iconGlyph: "\uf2db"
                label: "CPU"
                value: SystemUsage.cpu
            }

            UsageGauge {
                Layout.alignment: Qt.AlignVCenter
                iconGlyph: "\uf538"
                label: "RAM"
                value: SystemUsage.memory
                valueText: SystemUsage.memoryText(SystemUsage.memoryUsed, SystemUsage.memoryTotal)
            }

            UsageGauge {
                Layout.alignment: Qt.AlignVCenter
                visible: SystemUsage.gpuAvailable
                iconGlyph: "\ue163"
                label: "GPU"
                value: SystemUsage.gpu
            }

            UsageGauge {
                Layout.alignment: Qt.AlignVCenter
                visible: SystemUsage.vramAvailable
                iconGlyph: "\uf538"
                label: "VRAM"
                value: SystemUsage.vram
                valueText: SystemUsage.memoryText(SystemUsage.vramUsed, SystemUsage.vramTotal)
            }

            IconButton {
                glyph: "\uf013"
                glyphFontFamily: Theme.iconFontFamily
                glyphSize: Theme.topBarIconSize
                tooltip: "Settings"
                onClicked: root.settingsRequested()
            }

            IconButton {
                glyph: "\uf011"
                glyphFontFamily: Theme.iconFontFamily
                glyphSize: Theme.topBarIconSize
                tooltip: "Power"
                onClicked: root.powerRequested()
            }
        }
    }
}
