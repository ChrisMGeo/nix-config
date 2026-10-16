pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth

// The open Bluetooth section of the settings drawer: the on/off switch, the
// paired devices with Connect and Disconnect buttons, and a Scan button that
// lists nearby devices. Pairing a nearby device also trusts and connects it.
Column {
    id: root

    // The Bluetooth adapter, from Quickshell.Bluetooth.
    required property var adapter
    // True while the drawer is on screen. Closing the drawer stops a scan.
    property bool active: false

    readonly property bool powered: adapter !== null && adapter.enabled
    readonly property var allDevices: powered ? adapter.devices.values : []
    // Paired devices, connected ones first.
    readonly property var pairedDevices: allDevices
        .filter(device => device.paired || device.connected)
        .sort((a, b) => (b.connected - a.connected) || a.name.localeCompare(b.name))
    // Devices found by a scan. Ones that do not send a name show only their
    // address, which is not useful, so they are left out.
    readonly property var nearbyDevices: allDevices
        .filter(device => !device.paired && !device.connected && device.deviceName.length > 0)
        .sort((a, b) => a.name.localeCompare(b.name))

    bottomPadding: 8

    // Scanning uses power and slows down other Bluetooth traffic, so it stops
    // when the drawer closes, when this section closes, and after one minute.
    function stopScan() {
        if (adapter && adapter.discovering)
            adapter.discovering = false;
    }

    onActiveChanged: {
        if (!active)
            stopScan();
    }
    Component.onDestruction: stopScan()

    Timer {
        interval: 60000
        running: root.adapter !== null && root.adapter.discovering
        onTriggered: root.stopScan()
    }

    // A Font Awesome icon for the kind of device. BlueZ reports the kind as a
    // freedesktop icon name, such as "audio-headset".
    function glyphFor(icon) {
        if (icon.startsWith("audio-head"))
            return "";
        if (icon.startsWith("audio"))
            return "";
        if (icon === "input-mouse")
            return "";
        if (icon === "input-keyboard")
            return "";
        if (icon === "input-gaming")
            return "";
        if (icon.startsWith("phone"))
            return "";
        if (icon.startsWith("computer"))
            return "";
        return "";
    }

    RowLayout {
        width: parent.width
        height: Theme.scaled(48)

        UiText {
            Layout.leftMargin: 12
            Layout.fillWidth: true
            text: root.adapter
                ? `${root.pairedDevices.filter(device => device.connected).length} connected`
                : "Bluetooth unavailable"
            color: Theme.textMuted
        }

        TextButton {
            visible: root.powered
            text: root.adapter && root.adapter.discovering ? "Stop" : "Scan"
            onClicked: root.adapter.discovering = !root.adapter.discovering
        }

        ThemedSwitch {
            Layout.rightMargin: 8
            enabled: root.adapter !== null
            checked: root.powered
            onToggled: root.adapter.enabled = checked
        }
    }

    UiText {
        x: 12
        visible: root.powered && root.pairedDevices.length === 0
        text: "No paired devices. Press Scan to find one."
        color: Theme.textMuted
        font.pixelSize: Theme.scaled(11)
        bottomPadding: 6
    }

    Repeater {
        // ScriptModel keeps each row when the order changes.
        model: ScriptModel {
            values: root.pairedDevices
        }

        DeviceRow {}
    }

    UiText {
        x: 12
        visible: root.powered && (root.adapter.discovering || root.nearbyDevices.length > 0)
        text: root.adapter && root.adapter.discovering && root.nearbyDevices.length === 0
            ? "NEARBY · SEARCHING…"
            : "NEARBY"
        color: Theme.textMuted
        font.pixelSize: Theme.scaled(10)
        font.weight: Font.DemiBold
        font.letterSpacing: 1
        topPadding: 6
        bottomPadding: 4
    }

    Repeater {
        model: ScriptModel {
            values: root.nearbyDevices
        }

        DeviceRow {}
    }

    // One device: its icon, name, state, and one button for the next step.
    component DeviceRow: Item {
        id: row

        required property var modelData
        // `?.` below reads a property only when the object is there. A device
        // that leaves is deleted a moment before its row.
        readonly property var device: modelData
        readonly property string glyph: root.glyphFor(device?.icon ?? "")
        readonly property bool busy: device?.pairing
            || device?.state === BluetoothDeviceState.Connecting
            || device?.state === BluetoothDeviceState.Disconnecting
        // Set when Pair is pressed, so the device connects once pairing ends.
        property bool connectAfterPair: false
        property bool pairFailed: false

        width: root.width
        height: Theme.scaled(42)

        Connections {
            target: row.device

            function onPairingChanged() {
                if (row.device?.pairing || !row.connectAfterPair)
                    return;
                row.connectAfterPair = false;
                if (row.device?.paired) {
                    // Trusted devices may reconnect on their own later.
                    row.device.trusted = true;
                    row.device?.connect();
                } else {
                    row.pairFailed = true;
                }
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 10
            spacing: 10

            // Devices of an unknown kind get the Bluetooth logo, which is in
            // the Brands font instead of the Solid one.
            UiText {
                Layout.preferredWidth: Theme.scaled(16)
                text: row.glyph || ""
                color: row.device?.connected ? Theme.accent : Theme.textMuted
                font.family: row.glyph ? Theme.iconFontFamily : Theme.brandIconFontFamily
                font.pixelSize: Theme.scaled(13)
                font.weight: Font.Black
                horizontalAlignment: Text.AlignHCenter
            }

            Column {
                Layout.fillWidth: true
                spacing: 1

                UiText {
                    width: parent.width
                    text: row.device?.name ?? ""
                    color: row.device?.connected ? Theme.accent : Theme.text
                    font.weight: row.device?.connected ? Font.DemiBold : Font.Normal
                    elide: Text.ElideRight
                }

                UiText {
                    width: parent.width
                    text: {
                        if (row.device?.pairing)
                            return "Pairing…";
                        if (row.device?.state === BluetoothDeviceState.Connecting)
                            return "Connecting…";
                        if (row.device?.state === BluetoothDeviceState.Disconnecting)
                            return "Disconnecting…";
                        if (row.device?.connected)
                            return row.device?.batteryAvailable
                                ? `Connected · ${Math.round(row.device?.battery * 100)}% battery`
                                : "Connected";
                        if (row.device?.paired)
                            return "Paired";
                        return row.pairFailed ? "Pairing failed" : "Not paired";
                    }
                    color: row.pairFailed && !row.device?.paired ? Theme.destructive : Theme.textMuted
                    font.pixelSize: Theme.scaled(10)
                    elide: Text.ElideRight
                }
            }

            TextButton {
                enabled: !row.busy
                primary: !row.device?.connected
                text: row.device?.connected ? "Disconnect" : row.device?.paired ? "Connect" : "Pair"
                onClicked: {
                    if (row.device?.connected) {
                        row.device?.disconnect();
                    } else if (row.device?.paired) {
                        row.device?.connect();
                    } else {
                        row.pairFailed = false;
                        row.connectAfterPair = true;
                        row.device?.pair();
                    }
                }
            }
        }
    }
}
