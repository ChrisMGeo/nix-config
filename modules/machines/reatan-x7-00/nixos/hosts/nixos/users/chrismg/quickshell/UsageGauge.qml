import QtQuick
import Quickshell

Item {
    id: root

    property string iconGlyph: ""
    property real value: 0
    property string label: ""
    property string valueText: `${Math.round(value)}%`

    implicitWidth: Theme.scaled(28)
    implicitHeight: Theme.scaled(28)

    Canvas {
        id: gauge

        anchors.fill: parent
        antialiasing: true

        onPaint: {
            const context = getContext("2d");
            const lineWidth = Theme.compactOutlineWidth + 2;
            const center = width / 2;
            const radius = Math.min(width, height) / 2 - lineWidth;
            const start = -Math.PI / 2;

            context.clearRect(0, 0, width, height);
            context.lineWidth = lineWidth;
            context.lineCap = "round";
            context.strokeStyle = Theme.outlineFaint;
            context.beginPath();
            context.arc(center, height / 2, radius, 0, Math.PI * 2);
            context.stroke();

            context.strokeStyle = Theme.accent;
            context.beginPath();
            context.arc(center, height / 2, radius, start, start + Math.PI * 2 * root.value / 100);
            context.stroke();
        }
    }

    UiText {
        anchors.centerIn: parent
        text: root.iconGlyph
        color: Theme.text
        font.family: Theme.iconFontFamily
        font.pixelSize: Theme.topBarIconSize
        font.weight: Font.Black
    }

    PopupWindow {
        anchor.item: root
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom
        anchor.margins.bottom: Theme.scaled(10)
        visible: root.visible && gaugeMouse.containsMouse
        color: "transparent"
        implicitWidth: popupText.implicitWidth + Theme.scaled(18)
        implicitHeight: popupText.implicitHeight + Theme.scaled(12)

        Rectangle {
            anchors.fill: parent
            radius: Theme.radius - 4
            color: Theme.panel
            border.color: Theme.outline
            border.width: Theme.compactOutlineWidth

            Column {
                id: popupText
                anchors.centerIn: parent
                spacing: 2

                UiText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.label
                    color: Theme.textMuted
                    font.pixelSize: Theme.scaled(10)
                }

                UiText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.valueText
                    font.pixelSize: Theme.scaled(17)
                    font.weight: Font.DemiBold
                }
            }
        }
    }

    MouseArea {
        id: gaugeMouse

        anchors.fill: parent
        hoverEnabled: true
    }

    onValueChanged: gauge.requestPaint()
}
