pragma ComponentBehavior: Bound

import QtQuick

Rectangle {
    id: root

    property string title
    property string subtitle
    property string iconGlyph
    property string iconFontFamily: Theme.iconFontFamily
    property bool expanded: false
    property Component contentComponent
    property bool expandable: contentComponent !== null

    implicitHeight: contents.implicitHeight
    radius: Theme.radius - 3
    // No fill, so the drawer's frosted glass shows through. An open section
    // still gets the accent outline below.
    color: "transparent"
    border.color: expanded ? Theme.accent : "transparent"
    border.width: Theme.compactOutlineWidth

    Behavior on implicitHeight {
        NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
    }

    Column {
        id: contents
        width: parent.width

        Item {
            width: parent.width
            height: Theme.scaled(54)

            UiText {
                id: sectionIcon
                anchors {
                    left: parent.left
                    leftMargin: 12
                    verticalCenter: parent.verticalCenter
                }
                width: Theme.scaled(18)
                text: root.iconGlyph
                color: Theme.textMuted
                font.family: root.iconFontFamily
                font.pixelSize: Theme.scaled(16)
                font.weight: Font.Black
                horizontalAlignment: Text.AlignHCenter
            }

            Column {
                anchors {
                    left: sectionIcon.right
                    leftMargin: 10
                    right: disclosure.left
                    rightMargin: 8
                    verticalCenter: parent.verticalCenter
                }
                spacing: 1

                UiText {
                    width: parent.width
                    text: root.title
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                UiText {
                    width: parent.width
                    visible: text.length > 0
                    text: root.subtitle
                    color: Theme.textMuted
                    font.pixelSize: Theme.scaled(11)
                    elide: Text.ElideRight
                }
            }

            UiText {
                id: disclosure
                anchors {
                    right: parent.right
                    rightMargin: 14
                    verticalCenter: parent.verticalCenter
                }
                text: root.expanded ? "\uf077" : "\uf078"
                visible: root.expandable
                color: Theme.textMuted
                font.family: Theme.iconFontFamily
                font.pixelSize: Theme.scaled(15)
                font.weight: Font.Black
            }

            MouseArea {
                anchors.fill: parent
                enabled: root.expandable
                hoverEnabled: true
                onClicked: root.expanded = !root.expanded
            }
        }

        Loader {
            width: parent.width
            active: root.expanded && root.expandable
            visible: active
            sourceComponent: root.contentComponent
        }
    }
}
