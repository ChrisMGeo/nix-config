pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property real cpu: 0
    property real memoryUsed: 0
    property real memoryTotal: 0
    readonly property real memory: percentage(memoryUsed, memoryTotal)
    property real gpu: 0
    property bool gpuAvailable: false
    property real vramUsed: 0
    property real vramTotal: 0
    readonly property real vram: percentage(vramUsed, vramTotal)
    readonly property bool vramAvailable: vramTotal > 0
    property real previousTotal: 0
    property real previousIdle: 0

    // The last two minutes of readings, oldest first, for the charts in the
    // activity monitor. They are kept even while it is closed, so its charts
    // are full as soon as it opens. 80 readings, one every sampleInterval
    // milliseconds.
    readonly property int sampleInterval: 1500
    readonly property int historyLength: 80
    property var cpuHistory: []
    property var memoryHistory: []
    property var gpuHistory: []
    property var vramHistory: []

    // Returns `list` with `value` added at the end, dropping the oldest value
    // once the list is full.
    function appended(list, value) {
        const next = list.concat([value]);
        return next.length > historyLength ? next.slice(next.length - historyLength) : next;
    }

    function percentage(used, total) {
        return total > 0 ? Math.max(0, Math.min(100, 100 * used / total)) : 0;
    }

    function memoryText(used, total) {
        // Match familiar RAM/VRAM capacities, using binary gigabytes.
        const gigabyte = 1024 * 1024 * 1024;
        return `${(used / gigabyte).toFixed(1)}/${(total / gigabyte).toFixed(1).replace(/\.0$/, "")} GB`;
    }

    Process {
        id: usageQuery

        command: [Theme.systemUsageCommand]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                const fields = text.trim().split(/\s+/).map(Number);
                if (fields.length !== 8 || fields.some(value => !Number.isFinite(value) || value < 0))
                    return;

                const total = fields[0];
                const idle = fields[1];
                const totalDelta = total - root.previousTotal;
                const idleDelta = idle - root.previousIdle;

                // The first reading has nothing to compare with, so CPU use
                // and the history start with the second one.
                const compared = root.previousTotal > 0 && totalDelta > 0;
                if (compared)
                    root.cpu = Math.max(0, Math.min(100, 100 * (totalDelta - idleDelta) / totalDelta));

                root.previousTotal = total;
                root.previousIdle = idle;
                root.memoryUsed = fields[2];
                root.memoryTotal = fields[3];
                root.gpu = Math.max(0, Math.min(100, fields[4]));
                root.gpuAvailable = fields[5] === 1;
                root.vramUsed = fields[6];
                root.vramTotal = fields[7];

                if (compared) {
                    root.cpuHistory = root.appended(root.cpuHistory, root.cpu);
                    root.memoryHistory = root.appended(root.memoryHistory, root.memory);
                    root.gpuHistory = root.appended(root.gpuHistory, root.gpu);
                    root.vramHistory = root.appended(root.vramHistory, root.vram);
                }
            }
        }
    }

    Timer {
        interval: root.sampleInterval
        repeat: true
        running: true
        onTriggered: {
            if (!usageQuery.running)
                usageQuery.running = true;
        }
    }
}
