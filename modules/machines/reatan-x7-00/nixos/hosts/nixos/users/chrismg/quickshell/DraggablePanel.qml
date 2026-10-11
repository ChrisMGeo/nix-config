import QtQuick
import Quickshell

PanelWindow {
    id: root

    property real positionLeft: 0
    property real positionTop: 0
    property real panelWidth: 320
    property real panelHeight: 200
    property real minimumPanelWidth: 220
    property real minimumPanelHeight: 140

    signal positionRequested(real left, real top)
    signal sizeRequested(real width, real height)

    implicitWidth: Math.round(Math.max(
        root.minimumPanelWidth,
        Math.min(root.screen.width, root.panelWidth + resizeDrag.persistentTranslation.x)
    ))
    implicitHeight: Math.round(Math.max(
        root.minimumPanelHeight,
        Math.min(root.screen.height, root.panelHeight + resizeDrag.persistentTranslation.y)
    ))

    anchors {
        top: true
        left: true
    }

    margins {
        top: Math.round(Math.max(0, Math.min(
            root.screen.height - root.height,
            root.screen.height * root.positionTop + panelDrag.persistentTranslation.y
        )))
        left: Math.round(Math.max(0, Math.min(
            root.screen.width - root.width,
            root.screen.width * root.positionLeft + panelDrag.persistentTranslation.x
        )))
    }

    DragHandler {
        id: panelDrag

        target: null
        cursorShape: active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        onActiveChanged: {
            if (active)
                return;

            root.positionRequested(
                root.margins.left / root.screen.width,
                root.margins.top / root.screen.height
            );
            persistentTranslation = Qt.vector2d(0, 0);
        }
    }

    Item {
        anchors {
            right: parent.right
            bottom: parent.bottom
        }
        width: 18
        height: 18
        z: 1000

        Rectangle {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            width: 10
            height: 10
            color: Theme.outline
        }

        DragHandler {
            id: resizeDrag

            target: null
            dragThreshold: 0
            cursorShape: Qt.SizeFDiagCursor
            onActiveChanged: {
                if (active)
                    return;

                root.sizeRequested(root.width, root.height);
                root.positionRequested(
                    root.margins.left / root.screen.width,
                    root.margins.top / root.screen.height
                );
                persistentTranslation = Qt.vector2d(0, 0);
            }
        }
    }
}
