pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Networking

// The open Wi-Fi section of the settings drawer: the on/off switch, a rescan
// button, and the list of networks in range. Clicking a network joins it. A
// secured network that has no saved password opens a login form under its row.
Column {
    id: root

    // The Wi-Fi card, from Quickshell.Networking.
    required property var device
    // True while the drawer is on screen. Scanning only happens then.
    property bool scanning: false

    // The network whose login form is open, or null.
    property var formNetwork: null
    // The network whose last join failed, and the message shown under it.
    property var errorNetwork: null
    property string errorText: ""

    // Networks with a name, connected first, then saved ones, then by signal
    // strength. Sorting by bars instead of the exact strength keeps the rows
    // from jumping around after every scan.
    readonly property var networks: {
        if (!device || !Networking.wifiEnabled)
            return [];
        return device.networks.values
            .filter(network => network.name.length > 0)
            .sort((a, b) => (b.connected - a.connected)
                || (b.known - a.known)
                || (bars(b) - bars(a))
                || a.name.localeCompare(b.name));
    }

    bottomPadding: 8

    // Signal strength from 0 to 1, as 1 to 4 bars.
    function bars(network) {
        return network ? Math.max(1, Math.ceil(network.signalStrength * 4)) : 0;
    }

    function isOpen(network) {
        return network?.security === WifiSecurityType.Open || network?.security === WifiSecurityType.Owe;
    }

    // Networks that log in with a username and a password, such as eduroam.
    function isEnterprise(network) {
        return network?.security === WifiSecurityType.Wpa2Eap || network?.security === WifiSecurityType.WpaEap;
    }

    // Login types that the form cannot set up. nmtui can.
    function isUnsupported(network) {
        return network?.security === WifiSecurityType.Wpa3SuiteB192
            || network?.security === WifiSecurityType.DynamicWep
            || network?.security === WifiSecurityType.Leap;
    }

    function securityLabel(network) {
        if (isOpen(network))
            return "Open";
        if (isEnterprise(network))
            return "Enterprise";
        return WifiSecurityType.toString(network.security);
    }

    function statusText(network) {
        if (!network)
            return "";
        if (network.state === ConnectionState.Connecting)
            return "Connecting…";
        if (network.state === ConnectionState.Disconnecting)
            return "Disconnecting…";
        if (network.connected)
            return "Connected";
        if (network.known)
            return `Saved · ${securityLabel(network)}`;
        return securityLabel(network);
    }

    function failureText(reason) {
        switch (reason) {
        case ConnectionFailReason.NoSecrets:
            return "A password is needed.";
        case ConnectionFailReason.WifiClientDisconnected:
        case ConnectionFailReason.WifiClientFailed:
            return "Could not join. Check the password.";
        case ConnectionFailReason.WifiAuthTimeout:
            return "The network did not answer in time.";
        case ConnectionFailReason.WifiNetworkLost:
            return "The network went out of range.";
        default:
            return "Could not join the network.";
        }
    }

    function clearError() {
        errorNetwork = null;
        errorText = "";
    }

    // Called when a network row is clicked.
    function activate(network) {
        if (network.connected || network.stateChanging)
            return;
        clearError();
        if (network.known || isOpen(network)) {
            formNetwork = null;
            network.connect();
        } else if (isUnsupported(network)) {
            errorNetwork = network;
            errorText = "This login type is not supported here. Use nmtui.";
        } else {
            // Clicking the row again closes its form.
            formNetwork = formNetwork === network ? null : network;
        }
    }

    function join(network, username, password) {
        clearError();
        if (isEnterprise(network)) {
            // The password goes to the script on stdin, so it never shows up
            // in the process list. See onStarted below.
            enterpriseJoin.network = network;
            enterpriseJoin.password = password;
            enterpriseJoin.command = [Theme.wifiEnterpriseCommand, network.name, device.name, username];
            enterpriseJoin.running = true;
        } else {
            formNetwork = null;
            network.connectWithPsk(password);
        }
    }

    // Lets NetworkManager look for networks only while the list is on screen,
    // because scanning uses power. When this list closes, the Binding puts the
    // old value back.
    Binding {
        target: root.device
        property: "scannerEnabled"
        value: root.scanning && Networking.wifiEnabled
        when: root.device !== null
    }

    // Asks NetworkManager for a fresh scan. It refuses one right after another,
    // which is harmless, so the result is ignored.
    Process {
        id: rescan

        command: [Theme.nmcliCommand, "device", "wifi", "rescan"]
    }

    // Saves an enterprise network with the username and joins it. The script is
    // in ../quickshell.nix.
    Process {
        id: enterpriseJoin

        property var network: null
        property string password

        stdinEnabled: true
        stderr: StdioCollector {
            id: enterpriseErrors
        }

        onStarted: {
            write(password + "\n");
            password = "";
        }

        onExited: exitCode => {
            if (exitCode === 0) {
                root.formNetwork = null;
            } else {
                root.errorNetwork = enterpriseJoin.network;
                // nmcli explains the failure on its last line of errors.
                const lines = enterpriseErrors.text.trim().split("\n");
                root.errorText = lines[lines.length - 1] || "Could not join. Check the username and password.";
            }
        }
    }

    RowLayout {
        width: parent.width
        height: Theme.scaled(48)

        UiText {
            Layout.leftMargin: 12
            Layout.fillWidth: true
            text: "Wireless networking"
            color: Theme.textMuted
        }

        IconButton {
            visible: Networking.wifiEnabled
            enabled: !rescan.running
            glyph: ""
            glyphFontFamily: Theme.iconFontFamily
            glyphSize: Theme.scaled(12)
            tooltip: "Scan for networks"
            onClicked: rescan.running = true
        }

        ThemedSwitch {
            Layout.rightMargin: 8
            checked: Networking.wifiEnabled
            onToggled: Networking.wifiEnabled = checked
        }
    }

    UiText {
        x: 12
        visible: Networking.wifiEnabled && root.networks.length === 0
        text: "Looking for networks…"
        color: Theme.textMuted
        font.pixelSize: Theme.scaled(11)
        bottomPadding: 6
    }

    Repeater {
        // ScriptModel keeps each row when the order changes, so a half-typed
        // password survives a rescan.
        model: ScriptModel {
            values: root.networks
        }

        Column {
            id: networkItem

            required property var modelData
            // `?.` below reads a property only when the object is there. A
            // network that goes out of range is deleted a moment before its
            // row, and plain `.` would print errors in that moment.
            readonly property var network: modelData
            readonly property bool formOpen: root.formNetwork === network
            readonly property bool enterprise: root.isEnterprise(network)

            width: root.width

            Connections {
                target: networkItem.network

                function onConnectionFailed(reason) {
                    root.errorNetwork = networkItem.network;
                    root.errorText = root.failureText(reason);
                    // A saved password that stopped working opens the form, so
                    // a new one can be typed.
                    if (!root.isOpen(networkItem.network) && reason !== ConnectionFailReason.WifiNetworkLost)
                        root.formNetwork = networkItem.network;
                }
            }

            Rectangle {
                width: parent.width - 12
                x: 6
                height: Theme.scaled(42)
                radius: Theme.radius - 5
                color: rowMouse.containsMouse || networkItem.formOpen ? Theme.subtleButton : "transparent"

                MouseArea {
                    id: rowMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: networkItem.network?.connected ? Qt.ArrowCursor : Qt.PointingHandCursor
                    onClicked: root.activate(networkItem.network)
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 4
                    spacing: 8

                    // Four bars of rising height. The lit ones show the signal.
                    Row {
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 2

                        Repeater {
                            model: 4

                            Rectangle {
                                required property int index

                                // Lines up the bottoms of the bars. The tallest
                                // bar is 13 units high.
                                y: Theme.scaled(13) - height
                                width: Theme.scaled(3)
                                height: Theme.scaled(4 + index * 3)
                                // A small fixed rounding for the thin bars. It does not follow
                                // Theme.radius, which is for windows and panels.
                                radius: 1
                                color: index < root.bars(networkItem.network)
                                    ? networkItem.network?.connected ? Theme.accent : Theme.text
                                    : Theme.outlineTranslucent
                            }
                        }
                    }

                    Column {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 1

                        UiText {
                            width: parent.width
                            text: networkItem.network?.name ?? ""
                            color: networkItem.network?.connected ? Theme.accent : Theme.text
                            font.weight: networkItem.network?.connected ? Font.DemiBold : Font.Normal
                            elide: Text.ElideRight
                        }

                        UiText {
                            width: parent.width
                            text: root.statusText(networkItem.network)
                            color: Theme.textMuted
                            font.pixelSize: Theme.scaled(10)
                            elide: Text.ElideRight
                        }
                    }

                    UiText {
                        visible: !root.isOpen(networkItem.network)
                        text: ""
                        color: Theme.textMuted
                        font.family: Theme.iconFontFamily
                        font.pixelSize: Theme.scaled(10)
                        font.weight: Font.Black
                    }

                    IconButton {
                        visible: networkItem.network?.connected
                        glyph: ""
                        glyphFontFamily: Theme.iconFontFamily
                        glyphSize: Theme.scaled(11)
                        tooltip: "Disconnect"
                        onClicked: networkItem.network?.disconnect()
                    }

                    // Deletes the saved password and settings for this network.
                    IconButton {
                        visible: networkItem.network?.known
                        glyph: ""
                        glyphFontFamily: Theme.iconFontFamily
                        glyphSize: Theme.scaled(11)
                        tooltip: "Forget network"
                        onClicked: {
                            if (root.formNetwork === networkItem.network)
                                root.formNetwork = null;
                            networkItem.network?.forget();
                        }
                    }
                }
            }

            UiText {
                x: 14
                width: parent.width - 28
                visible: root.errorNetwork === networkItem.network && root.errorText.length > 0
                text: root.errorText
                color: Theme.destructive
                font.pixelSize: Theme.scaled(10)
                wrapMode: Text.Wrap
                topPadding: 2
                bottomPadding: 4
            }

            // The login form. A Loader creates it only while it is open, so the
            // typed text is thrown away when it closes.
            Loader {
                width: parent.width
                active: networkItem.formOpen
                visible: active

                sourceComponent: Column {
                    id: form

                    property bool showPassword: false

                    leftPadding: 14
                    rightPadding: 14
                    topPadding: 4
                    bottomPadding: 8
                    spacing: 6

                    readonly property bool busy: enterpriseJoin.running && enterpriseJoin.network === networkItem.network
                    readonly property bool ready: passwordField.text.length > 0
                        && (!networkItem.enterprise || usernameField.text.length > 0)

                    function submit() {
                        if (ready && !busy)
                            root.join(networkItem.network, usernameField.text, passwordField.text);
                    }

                    // Puts the cursor in the first box, so typing can start at once.
                    Component.onCompleted: (networkItem.enterprise ? usernameField : passwordField).forceActiveFocus()

                    LoginField {
                        id: usernameField

                        visible: networkItem.enterprise
                        width: parent.width - 28
                        placeholderText: "Username"
                        onAccepted: passwordField.forceActiveFocus()
                    }

                    LoginField {
                        id: passwordField

                        width: parent.width - 28
                        placeholderText: "Password"
                        echoMode: form.showPassword ? TextInput.Normal : TextInput.Password
                        onAccepted: form.submit()
                    }

                    RowLayout {
                        width: parent.width - 28

                        IconButton {
                            glyph: form.showPassword ? "" : ""
                            glyphFontFamily: Theme.iconFontFamily
                            glyphSize: Theme.scaled(11)
                            tooltip: form.showPassword ? "Hide password" : "Show password"
                            onClicked: form.showPassword = !form.showPassword
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        TextButton {
                            text: "Cancel"
                            onClicked: root.formNetwork = null
                        }

                        TextButton {
                            primary: true
                            enabled: form.ready && !form.busy
                            text: form.busy ? "Joining…" : "Join"
                            onClicked: form.submit()
                        }
                    }
                }
            }
        }
    }

    // A text box in the theme colors, for the login form.
    component LoginField: TextField {
        color: Theme.text
        placeholderTextColor: Theme.textMuted
        selectionColor: Theme.accent
        selectedTextColor: Theme.accentText
        font.family: Theme.fontFamily
        font.pixelSize: Theme.scaled(12)
        leftPadding: 8
        rightPadding: 8

        background: Rectangle {
            implicitHeight: Theme.scaled(30)
            radius: Theme.radius - 5
            color: Theme.subtleButton
            border.color: parent.activeFocus ? Theme.accent : Theme.outlineTranslucent
            border.width: Theme.compactOutlineWidth
        }
    }
}
