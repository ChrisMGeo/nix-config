pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import Quickshell.Widgets

// The drop-down under the bar's tray button. TopBar.qml opens it. It lists one
// row per program that shows a tray icon. Left click activates the program,
// middle click runs its second action, and right click opens its own menu.
PopupWindow {
    id: root

    // The button the drop-down hangs from.
    property Item anchorItem

    // Asks TopBar.qml to close the drop-down, after a program was activated.
    signal closeRequested()

    // Opens below the bar, centered on the button. The anchor is a strip as
    // wide as the button that starts under the bar's panel plus a small gap.
    // `edges` picks the middle of that strip's top edge, and `gravity` makes
    // the drop-down grow downward from there.
    anchor.item: anchorItem
    anchor.rect.x: 0
    anchor.rect.y: anchorItem ? anchorItem.height + (Theme.barHeight - anchorItem.height) / 2 + Theme.gap : 0
    anchor.rect.width: anchorItem ? anchorItem.width : 1
    anchor.rect.height: 1
    anchor.edges: Edges.Top
    anchor.gravity: Edges.Bottom
    color: "transparent"
    implicitWidth: Theme.scaled(220)
    implicitHeight: column.implicitHeight + 16

    // Blurs what is behind the drop-down, for a frosted glass look. See
    // Theme.panel.
    BackgroundEffect.blurRegion: Region {
        width: root.width
        height: root.height
        radius: Theme.radius
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.panel
        border.color: Theme.outline
        border.width: Theme.compactOutlineWidth

        ColumnLayout {
            id: column

            anchors {
                fill: parent
                margins: 8
            }
            spacing: 4

            // Shown in place of the rows while no program has a tray icon.
            UiText {
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.scaled(34)
                visible: SystemTray.items.values.length === 0
                text: "No tray icons"
                color: Theme.textMuted
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            Repeater {
                model: SystemTray.items

                Rectangle {
                    id: trayRow

                    required property var modelData

                    Layout.fillWidth: true
                    Layout.preferredHeight: Theme.scaled(34)
                    radius: Theme.radius - 4
                    color: trayMouse.containsMouse ? Theme.surfaceHover : "transparent"

                    RowLayout {
                        anchors {
                            fill: parent
                            leftMargin: 10
                            rightMargin: 10
                        }
                        spacing: 10

                        IconImage {
                            Layout.preferredWidth: Theme.scaled(17)
                            Layout.preferredHeight: Theme.scaled(17)
                            source: trayRow.modelData.icon
                        }

                        UiText {
                            Layout.fillWidth: true
                            // Some programs leave the title empty, so fall back
                            // to the tooltip, then to the program's id.
                            text: trayRow.modelData.title
                                || trayRow.modelData.tooltipTitle
                                || trayRow.modelData.id
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: trayMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

                        onClicked: mouse => {
                            const item = trayRow.modelData;
                            // The program's menu opens under this row, so the
                            // drop-down stays open behind it.
                            const position = root.contentItem.mapFromItem(trayRow, 0, trayRow.height);
                            if (mouse.button === Qt.RightButton && item.hasMenu) {
                                item.display(root, position.x, position.y);
                            } else if (mouse.button === Qt.MiddleButton) {
                                item.secondaryActivate();
                                root.closeRequested();
                            } else if (item.onlyMenu && item.hasMenu) {
                                item.display(root, position.x, position.y);
                            } else {
                                item.activate();
                                root.closeRequested();
                            }
                        }
                    }
                }
            }
        }
    }
}
