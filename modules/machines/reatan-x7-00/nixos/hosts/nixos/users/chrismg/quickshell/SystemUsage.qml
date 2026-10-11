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

                if (root.previousTotal > 0 && totalDelta > 0)
                    root.cpu = Math.max(0, Math.min(100, 100 * (totalDelta - idleDelta) / totalDelta));

                root.previousTotal = total;
                root.previousIdle = idle;
                root.memoryUsed = fields[2];
                root.memoryTotal = fields[3];
                root.gpu = Math.max(0, Math.min(100, fields[4]));
                root.gpuAvailable = fields[5] === 1;
                root.vramUsed = fields[6];
                root.vramTotal = fields[7];
            }
        }
    }

    Timer {
        interval: 1500
        repeat: true
        running: true
        onTriggered: {
            if (!usageQuery.running)
                usageQuery.running = true;
        }
    }
}
