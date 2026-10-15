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
    readonly property var bluetoothAdapter: Bluetooth.defaultAdapter
    readonly property var audioSink: Pipewire.defaultAudioSink
    readonly property bool batteryAvailable: UPower.displayDevice !== null
        && UPower.displayDevice.ready
        && UPower.displayDevice.isPresent
    // Theme.showBattery is false on desktops. A UPS or a wireless mouse can
    // still look like a battery there, so its level stays hidden.
    readonly property bool showBattery: Theme.showBattery && batteryAvailable
    readonly property bool powerProfilesAvailable: Capabilities.powerProfiles

    signal closeRequested()

    // Asks niri to blur what is behind the whole window, with the same rounded
    // corners as the panel, for a frosted glass look. Theme.panel is
    // see-through, so the blur shows. Only this region is blurred.
    BackgroundEffect.blurRegion: Region {
        width: root.width
        height: root.height
        radius: Theme.radius
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    implicitWidth: Theme.drawerWidth
    implicitHeight: Math.min(Theme.scaled(680), screen.height - Theme.barHeight - Theme.outerMargin * 4)
    color: "transparent"
    focusable: true
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        right: true
    }

    margins {
        top: Theme.barHeight + Theme.outerMargin * 2
        right: Theme.outerMargin
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.panel
        border.color: Theme.outline
        border.width: Theme.compactOutlineWidth

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

                                UiText {
                                    text: root.wiredDevice && root.wiredDevice.connected
                                        ? root.wiredDevice.address || "Connected"
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
                            ? root.wifiDevice && root.wifiDevice.connected ? root.wifiDevice.name : "Enabled"
                            : "Disabled"
                        iconGlyph: "\uf1eb"

                        contentComponent: Component {
                            WifiNetworks {
                                width: sections.width
                                device: root.wifiDevice
                                scanning: root.visible
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
                                active: root.visible
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

                                    Slider {
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
                                        radius: 7
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
}
