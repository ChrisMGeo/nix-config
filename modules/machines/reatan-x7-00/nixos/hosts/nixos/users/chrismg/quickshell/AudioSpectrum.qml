pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Scope {
    id: root

    readonly property bool active: Mpris.players.values.some(player => player.isPlaying)
    property var values: Array(Theme.spectrumBars).fill(0)
    property var mediaValues: Array(Theme.mediaSpectrumBars).fill(0)

    onActiveChanged: {
        if (!active) {
            restartTimer.stop();
            values = Array(Theme.spectrumBars).fill(0);
            mediaValues = Array(Theme.mediaSpectrumBars).fill(0);
        }
    }

    function reduceLevels(levels, targetCount) {
        const reduced = [];
        const groupSize = levels.length / targetCount;

        for (let group = 0; group < targetCount; group++) {
            const start = Math.floor(group * groupSize);
            const end = Math.max(start + 1, Math.floor((group + 1) * groupSize));
            reduced.push(Math.max(...levels.slice(start, end)));
        }

        return reduced;
    }

    Process {
        id: cava

        running: root.active && !restartTimer.running
        // Both paths come from Nix through Theme.qml. See ../quickshell.nix.
        command: [Theme.cavaCommand, "-p", Theme.cavaConfig]
        onExited: {
            if (root.active)
                restartTimer.restart();
        }

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                if (!root.active)
                    return;

                const levels = data.trim().split(";")
                    .filter(value => value.length > 0)
                    .slice(0, Theme.spectrumBars)
                    .map(value => Math.max(0, Math.min(1, Number(value) / 1000)));

                if (levels.length === Theme.spectrumBars) {
                    root.values = levels;
                    root.mediaValues = root.reduceLevels(levels, Theme.mediaSpectrumBars);
                }
            }
        }
    }

    Timer {
        id: restartTimer

        interval: 1000
    }
}
