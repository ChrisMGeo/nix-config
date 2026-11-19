pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Wayland

PanelWindow {
    id: root

    readonly property var wiredDevice: Networking.devices.values.find(device => device.type === DeviceType.Wired) ?? null
    readonly property var wifiDevice: Networking.devices.values.find(device => device.type === DeviceType.Wifi) ?? null
    // The Wi-Fi network the computer is on. The device's own name is the
    // interface, such as wlp2s0, so the subtitle shows this one instead.
    readonly property var wifiNetwork: wifiDevice?.networks.values.find(network => network.connected) ?? null
    readonly property var bluetoothAdapter: Bluetooth.defaultAdapter
    readonly property var audioSink: Pipewire.defaultAudioSink
    readonly property bool batteryAvailable: UPower.displayDevice !== null
        && UPower.displayDevice.ready
        && UPower.displayDevice.isPresent
    // Theme.showBattery is false on desktops. A UPS or a wireless mouse can
    // still look like a battery there, so its level stays hidden.
    readonly property bool showBattery: Theme.showBattery && batteryAvailable
    readonly property bool powerProfilesAvailable: Capabilities.powerProfiles
    // Whether the volume mixer popup is open. It opens from the Sound section.
    // shell.qml sets it, and closes it with the drawer.
    property bool mixerOpen: false
    // Whether the drawer is open, set by shell.qml. A hidden bar hides an open
    // drawer, so `visible` is false then while this stays true. The Wi-Fi
    // and Bluetooth scans follow this, so a hidden drawer keeps scanning and
    // keeps its state, as if it were still on screen.
    property bool open: false
    // Whether this window has the keyboard. shell.qml uses it to notice a
    // click away.
    readonly property bool hasKeyboard: drawerPanel.windowActive

    signal closeRequested()
    // Asks shell.qml to open or close the volume mixer.
    signal mixerOpenRequested(bool wanted)
    // Escape was pressed in the drawer or the volume mixer, a popup of this
    // window whose keys come here. shell.qml closes the volume mixer first,
    // then the drawer, through the same path as their close buttons.
    signal escapePressed()

    onVisibleChanged: {
        if (visible)
            Capabilities.refresh();
    }

    // The drawer's panel. VolumeMixer.qml lines itself up with it.
    readonly property Item panel: drawerPanel

    // Asks niri to blur what is behind the panel, for a frosted glass look.
    // Theme.panel is see-through, so the blur shows. Only this region is
    // blurred, so the glow space around the panel stays clear.
    BackgroundEffect.blurRegion: Region {
        item: drawerPanel
    }

    // Only the panel takes clicks. Clicks on the glow around it go through
    // to the windows below.
    mask: Region {
        item: drawerPanel
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    // The window is the panel plus Theme.glowReach of space on the left, top,
    // and bottom for the glow around it. On the right it reaches the screen
    // edge and the panel keeps Theme.outerMargin from it, so the glow has
    // room there too.
    implicitWidth: Theme.glowReach + Theme.drawerWidth + Theme.outerMargin
    implicitHeight: Math.min(Theme.scaled(680), screen.height - Theme.barHeight - Theme.outerMargin * 4)
        + Theme.glowReach * 2
    color: "transparent"
    // The drawer can take the keyboard, for Escape and the Wi-Fi fields. This
    // is on-demand focus: niri gives the drawer the keyboard when it appears,
    // so Escape works without a click first. It keeps the keyboard until a
    // click on another window, which shell.qml treats as a click away.
    focusable: true
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        right: true
    }

    // The panel's top is at Theme.menuTop, like the other menus under the
    // bar. The window starts Theme.glowReach above that, to fit the glow.
    margins {
        top: Theme.menuTop - Theme.glowReach
    }

    // The glow. While the volume mixer is open, its glow and this one are
    // joined into one, so they do not double in the gap between the panels.
    // The mixer's panel ends Theme.gap left of this one, at the same top. The
    // mixer's window covers everything left of this panel, from the top of
    // this window to Theme.glowReach below the mixer's panel, and draws the
    // glow there, so this glow leaves that area out.
    PanelGlow {
        target: drawerPanel
        neighbor: mixer.visible
            ? Qt.rect(-Theme.gap - mixer.mixerPanel.width, 0, mixer.mixerPanel.width, mixer.mixerPanel.height)
            : Qt.rect(0, 0, 0, 0)
        skip: mixer.visible
            ? Qt.rect(-Theme.glowReach, -Theme.glowReach, Theme.glowReach, mixer.mixerPanel.height + Theme.glowReach * 2)
            : Qt.rect(0, 0, 0, 0)
    }

    Rectangle {
        id: drawerPanel

        x: Theme.glowReach
        y: Theme.glowReach
        width: Theme.drawerWidth
        height: root.height - Theme.glowReach * 2
        color: Theme.panel

        // Whether the window has the keyboard. The attached `Window` must be
        // read from an item, which tells it its window.
        readonly property bool windowActive: Window.active

        // A Shortcut works wherever the keyboard focus is in the window, even
        // inside a Wi-Fi password field.
        Shortcut {
            sequence: "Escape"
            enabled: root.visible
            onActivated: root.escapePressed()
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            RowLayout {
                Layout.fillWidth: true

                UiText {
                    Layout.fillWidth: true
                    text: "Settings"
                    color: Theme.accent
                    font.pixelSize: Theme.scaled(16)
                    font.weight: Font.DemiBold
                }

                IconButton {
                    glyph: "\uf00d"
                    glyphFontFamily: Theme.iconFontFamily
                    tooltip: "Close settings"
                    onClicked: root.closeRequested()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.scaled(70)
                radius: Theme.radius - 3
                // No fill, like the sections below, so the drawer's frosted
                // glass shows through.
                color: "transparent"

                Rectangle {
                    id: avatar
                    anchors {
                        left: parent.left
                        leftMargin: 12
                        verticalCenter: parent.verticalCenter
                    }
                    width: Theme.scaled(44)
                    height: Theme.scaled(44)
                    radius: width / 2
                    color: Theme.accent

                    UiText {
                        anchors.centerIn: parent
                        text: (Quickshell.env("USER") || "U").slice(0, 1).toUpperCase()
                        color: Theme.accentText
                        font.pixelSize: Theme.scaled(20)
                        font.weight: Font.Bold
                    }
                }

                Column {
                    anchors {
                        left: avatar.right
                        leftMargin: 12
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: 2

                    UiText {
                        text: Quickshell.env("USER") || "User"
                        font.pixelSize: Theme.scaled(15)
                        font.weight: Font.DemiBold
                    }

                    UiText {
                        text: "Local session"
                        color: Theme.textMuted
                        font.pixelSize: Theme.scaled(11)
                    }
                }
            }

            UiText {
                Layout.fillWidth: true
                Layout.topMargin: 4
                text: "QUICK SETTINGS"
                color: Theme.textMuted
                font.pixelSize: Theme.scaled(10)
                font.weight: Font.DemiBold
                font.letterSpacing: 1
            }

            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentHeight: sections.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: sections
                    width: parent.width
                    spacing: 7

                    SettingsSection {
                        width: parent.width
                        visible: root.wiredDevice !== null
                        title: "Ethernet"
                        subtitle: root.wiredDevice
                            ? `${root.wiredDevice.name} · ${root.wiredDevice.connected ? "Connected" : "Disconnected"}`
                            : "No wired device"
                        iconGlyph: "\uf796"
                        expanded: true

                        contentComponent: Component {
                            Column {
                                width: sections.width
                                leftPadding: 12
                                rightPadding: 12
                                bottomPadding: 12
                                spacing: 5

                                // The link speed. The device's address is its
                                // hardware (MAC) address, not an IP address, so
                                // it is not shown here.
                                UiText {
                                    text: root.wiredDevice && root.wiredDevice.connected
                                        ? root.wiredDevice.linkSpeed > 0
                                            ? `Connected at ${root.wiredDevice.linkSpeed} Mb/s`
                                            : "Connected"
                                        : "No active wired connection"
                                    color: Theme.textMuted
                                    font.pixelSize: Theme.scaled(11)
                                }
                            }
                        }
                    }

                    SettingsSection {
                        width: parent.width
                        visible: root.wifiDevice !== null
                        title: "Wi-Fi"
                        subtitle: Networking.wifiEnabled
                            ? root.wifiDevice && root.wifiDevice.connected ? root.wifiNetwork?.name ?? "Connected" : "Enabled"
                            : "Disabled"
                        iconGlyph: "\uf1eb"

                        contentComponent: Component {
                            WifiNetworks {
                                width: sections.width
                                device: root.wifiDevice
                                scanning: root.open
                            }
                        }
                    }

                    SettingsSection {
                        width: parent.width
                        visible: root.bluetoothAdapter !== null
                        title: "Bluetooth"
                        subtitle: root.bluetoothAdapter
                            ? root.bluetoothAdapter.enabled ? "Enabled" : "Disabled"
                            : "No adapter"
                        iconGlyph: "\uf294"
                        iconFontFamily: Theme.brandIconFontFamily

                        contentComponent: Component {
                            BluetoothDevices {
                                width: sections.width
                                adapter: root.bluetoothAdapter
                                active: root.open
                            }
                        }
                    }

                    SettingsSection {
                        width: parent.width
                        visible: root.audioSink !== null
                        title: "Sound"
                        subtitle: root.audioSink ? root.audioSink.description : "No audio output"
                        iconGlyph: "\uf028"

                        contentComponent: Component {
                            Column {
                                width: sections.width

                                RowLayout {
                                    width: parent.width
                                    height: Theme.scaled(52)

                                    UiText {
                                        Layout.leftMargin: 12
                                        text: root.audioSink && root.audioSink.audio && root.audioSink.audio.muted
                                            ? "Muted"
                                            : "Volume"
                                        color: Theme.textMuted
                                    }

                                    ThemedSlider {
                                        Layout.fillWidth: true
                                        from: 0
                                        to: 1
                                        enabled: root.audioSink !== null && root.audioSink.audio !== null
                                        value: root.audioSink && root.audioSink.audio ? root.audioSink.audio.volume : 0
                                        onMoved: root.audioSink.audio.volume = value
                                    }

                                    IconButton {
                                        Layout.rightMargin: 8
                                        enabled: root.audioSink !== null && root.audioSink.audio !== null
                                        glyph: root.audioSink && root.audioSink.audio && root.audioSink.audio.muted
                                            ? "\uf6a9"
                                            : "\uf028"
                                        glyphFontFamily: Theme.iconFontFamily
                                        tooltip: "Toggle mute"
                                        onClicked: root.audioSink.audio.muted = !root.audioSink.audio.muted
                                    }
                                }

                                AudioOutputs {
                                    width: parent.width
                                }

                                // Opens and closes the volume mixer beside the
                                // drawer.
                                Item {
                                    width: parent.width
                                    height: mixerButton.height + 12

                                    TextButton {
                                        id: mixerButton

                                        x: 12
                                        text: root.mixerOpen ? "Close volume mixer" : "Volume mixer"
                                        primary: root.mixerOpen
                                        onClicked: root.mixerOpenRequested(!root.mixerOpen)
                                    }
                                }
                            }
                        }
                    }

                    SettingsSection {
                        width: parent.width
                        // The profile switch shows wherever power-profiles-daemon
                        // runs. The battery level shows only on laptops.
                        visible: root.showBattery || root.powerProfilesAvailable
                        expandable: root.powerProfilesAvailable
                        title: "Power"
                        subtitle: root.showBattery
                            ? `${Math.round(UPower.displayDevice.percentage * 100)}% battery`
                            : PowerProfile.toString(PowerProfiles.profile)
                        iconGlyph: "\uf0e7"

                        contentComponent: Component {
                            Row {
                                id: profileRow

                                width: sections.width
                                leftPadding: Theme.scaled(8)
                                rightPadding: Theme.scaled(8)
                                height: visible ? Theme.scaled(52) : 0
                                visible: root.powerProfilesAvailable
                                spacing: Theme.scaled(5)

                                Repeater {
                                    id: profileRepeater

                                    model: PowerProfiles.hasPerformanceProfile
                                        ? [
                                            { label: "Saver", profile: PowerProfile.PowerSaver },
                                            { label: "Balanced", profile: PowerProfile.Balanced },
                                            { label: "Performance", profile: PowerProfile.Performance }
                                        ]
                                        : [
                                            { label: "Saver", profile: PowerProfile.PowerSaver },
                                            { label: "Balanced", profile: PowerProfile.Balanced }
                                        ]

                                    Rectangle {
                                        id: profileButton

                                        required property var modelData

                                        width: Math.floor(
                                            (profileRow.width - profileRow.leftPadding - profileRow.rightPadding
                                                - profileRow.spacing * (profileRepeater.count - 1))
                                                / profileRepeater.count
                                        )
                                        height: Theme.scaled(32)
                                        y: Math.round((profileRow.height - height) / 2)
                                        radius: Theme.radius - 5
                                        color: PowerProfiles.profile === modelData.profile
                                            ? Theme.accent
                                            : Theme.surfaceRaised

                                        UiText {
                                            id: profileLabel

                                            anchors.centerIn: parent
                                            text: profileButton.modelData.label
                                            color: PowerProfiles.profile === profileButton.modelData.profile
                                                ? Theme.accentText
                                                : Theme.text
                                            font.pixelSize: Theme.scaled(10)
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: PowerProfiles.profile = profileButton.modelData.profile
                                        }
                                    }
                                }
                            }
                        }
                    }

                    SettingsSection {
                        width: parent.width
                        title: "Paths"
                        subtitle: "Shell data and configuration"
                        iconGlyph: "\uf07b"

                        contentComponent: Component {
                            Column {
                                width: sections.width
                                leftPadding: 12
                                rightPadding: 12
                                bottomPadding: 12
                                spacing: 4

                                UiText {
                                    width: parent.width - 24
                                    text: `Config  ${Quickshell.shellDir}`
                                    color: Theme.textMuted
                                    font.pixelSize: Theme.scaled(10)
                                    elide: Text.ElideMiddle
                                }

                                UiText {
                                    width: parent.width - 24
                                    text: `State   ${Quickshell.stateDir}`
                                    color: Theme.textMuted
                                    font.pixelSize: Theme.scaled(10)
                                    elide: Text.ElideMiddle
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    VolumeMixer {
        id: mixer

        parentWindow: root
        visible: root.visible && root.mixerOpen
        onCloseRequested: root.mixerOpenRequested(false)
    }
}
