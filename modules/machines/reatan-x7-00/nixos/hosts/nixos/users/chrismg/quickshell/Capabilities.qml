pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property bool powerProfiles: false

    Process {
        id: powerProfilesProbe

        command: [Theme.powerProfilesCommand]
        running: true
        onExited: (exitCode, exitStatus) => {
            root.powerProfiles = exitCode === 0;
        }
    }

    Timer {
        interval: 10000
        repeat: true
        running: true
        onTriggered: {
            if (!powerProfilesProbe.running)
                powerProfilesProbe.running = true;
        }
    }
}
