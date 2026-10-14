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

    // The bar is drawn as three separate panels with empty space between them:
    // the tray on the left, the workspaces in the center, and the gauges and
    // buttons on the right. They share this one window, so the space niri
    // reserves for the bar and the place where menus open stay the same.

    // Space between a panel's outline and its contents, in pixels.
    readonly property int sectionPadding: 6

    // The left panel: one button per tray icon. It hides when no program shows
    // a tray icon, so no empty panel is left behind.
    Rectangle {
        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
        }
        // As wide as the icons, at most a third of the bar. Extra icons are cut
        // off.
        width: Math.min(trayRow.implicitWidth, Math.floor(root.width * 0.32)) + root.sectionPadding * 2
        visible: trayRepeater.count > 0
        radius: Theme.radius
        color: Theme.panel
        border.color: Theme.outline
        border.width: Theme.outlineWidth
        clip: true

        Row {
            id: trayRow

            anchors {
                left: parent.left
                leftMargin: root.sectionPadding
                verticalCenter: parent.verticalCenter
            }
            spacing: 2

            Repeater {
                id: trayRepeater

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
    }

    // The center panel: the workspace buttons of this monitor.
    Rectangle {
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            bottom: parent.bottom
        }
        width: workspaceRow.implicitWidth + root.sectionPadding * 2
        radius: Theme.radius
        color: Theme.panel
        border.color: Theme.outline
        border.width: Theme.outlineWidth

        Row {
            id: workspaceRow

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
    }

    // The right panel: the audio visualizer, the usage gauges, and the
    // settings and power buttons.
    Rectangle {
        anchors {
            right: parent.right
            top: parent.top
            bottom: parent.bottom
        }
        width: statusRow.implicitWidth + root.sectionPadding * 2
        radius: Theme.radius
        color: Theme.panel
        border.color: Theme.outline
        border.width: Theme.outlineWidth

        RowLayout {
            id: statusRow

            anchors {
                right: parent.right
                rightMargin: root.sectionPadding
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
