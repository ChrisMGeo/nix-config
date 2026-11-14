pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io

// Starts and stops the Bluetooth pairing agent, the bluetooth-agent service in
// bluetooth.nix. The agent answers pairing requests from any device, so it
// runs only while a scan or a pairing from the bar needs it.
//
// This is a singleton, one object for the whole bar, instead of part of
// BluetoothDevices.qml. The Bluetooth section is destroyed when it closes,
// often before BlueZ reports that its scan stopped. The agent then had no one
// left to stop it. This object lives as long as the bar does.
Singleton {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    // True while any device is pairing. Quickshell sets a device's `pairing`
    // as soon as pair() is called and clears it when BlueZ answers.
    readonly property bool anyPairing: adapter !== null
        && adapter.devices.values.some(device => device.pairing)
    // Devices whose Pair was pressed, waiting for the agent to be ready.
    property var waiting: []
    // Whether the agent should run now.
    readonly property bool wanted: adapter !== null
        && (adapter.discovering || anyPairing || waiting.length > 0)

    // The action of the systemctl run in progress, "start" or "stop", or ""
    // when none is running.
    property string running: ""
    // Whether the last systemctl run was a start, so the agent may be up.
    property bool lastWasStart: false
    // A Pair came in while systemctl was running, so a start must run next
    // even if the last action was a start.
    property bool pendingForce: false

    // Sent when a waiting Pair cannot go ahead because the agent did not
    // start. BluetoothDevices.qml shows "Pairing failed" for that device.
    signal pairRefused(var device)

    onWantedChanged: sync()

    // Pairs `device` once the agent has registered with BlueZ. BlueZ refuses a
    // pairing that starts before an agent is there to answer it.
    function pairWhenReady(device) {
        if (!device || waiting.includes(device))
            return;
        // Runs `systemctl start` even if the agent already runs. It returns at
        // once in that case, and it starts the agent again if the time limit
        // in bluetooth.nix stopped it. If this Pair turns `wanted` on,
        // onWantedChanged runs the sync. Otherwise it runs here.
        const wasWanted = wanted;
        pendingForce = true;
        waiting = waiting.concat([device]);
        if (wasWanted)
            sync();
    }

    // Forgets the devices still waiting for the agent. Pairings that already
    // started are left to finish.
    function cancelWaiting() {
        waiting = [];
    }

    // Starts or stops the agent to match `wanted`. Only one systemctl runs at
    // a time. A change that comes in while one runs is handled when it ends,
    // so a quick stop and start always ends with the agent in the state that
    // is wanted last. `pendingForce` runs a start even if the last action was
    // one.
    function sync() {
        if (running !== "")
            return;
        if (wanted && (pendingForce || !lastWasStart)) {
            pendingForce = false;
            run("start");
        } else if (!wanted && lastWasStart) {
            run("stop");
        }
    }

    function run(action) {
        running = action;
        lastWasStart = action === "start";
        control.command = [Theme.systemctlCommand, "--user", action, "bluetooth-agent"];
        control.running = true;
    }

    Process {
        id: control

        // `systemctl start` waits until the service has started. bt-agent
        // registers with BlueZ and becomes the default agent before it moves
        // itself to the background, and systemd counts the service as started
        // only after that (`Type = "forking"` in bluetooth.nix). So a start
        // that ends with exit code 0 means the agent is ready.
        onExited: exitCode => {
            const action = root.running;

            if (action === "start" && exitCode !== 0) {
                // The agent is not running. Refuse the waiting pairings, and
                // try again only on the next change, so a start that keeps
                // failing does not run over and over.
                const refused = root.waiting;
                root.lastWasStart = false;
                root.pendingForce = false;
                root.waiting = [];
                root.running = "";
                for (const device of refused)
                    root.pairRefused(device);
                return;
            }

            if (action === "start") {
                // Pair first, then empty the list. pair() marks the device as
                // pairing at once, so `wanted` stays true the whole time and
                // the agent is not stopped in between.
                for (const device of root.waiting) {
                    if (device && !device.paired && !device.pairing)
                        device.pair();
                }
                root.waiting = [];
            }

            // A stop that failed may have left the agent running. Count it as
            // started, so the next change stops it again. Like a failed start,
            // it is not tried again at once.
            if (action === "stop" && exitCode !== 0) {
                root.lastWasStart = true;
                root.running = "";
                return;
            }

            root.running = "";
            root.sync();
        }
    }
}
