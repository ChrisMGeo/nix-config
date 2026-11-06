pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property bool powerProfiles: false

    // Checks again whether power-profiles-daemon is running. Only the settings
    // drawer shows the result, so it calls this each time it opens, instead of
    // a timer checking all session long.
    function refresh() {
        if (!powerProfilesProbe.running)
            powerProfilesProbe.running = true;
    }

    Process {
        id: powerProfilesProbe

        command: [Theme.powerProfilesCommand]
        running: true
        onExited: (exitCode, exitStatus) => {
            root.powerProfiles = exitCode === 0;
        }
    }
}
