pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io

// Starts and stops the Bluetooth pairing agent, the bluetooth-agent service in
// bluetooth.nix. The agent answers pairing requests from any device, so it
// runs only while a scan or a pairing from the bar needs it. Also trusts and
// connects each device once a pairing started from the bar succeeds.
//
// This is a singleton, one object for the whole bar, instead of part of
// BluetoothDevices.qml. The Bluetooth section is destroyed when it closes,
// often before BlueZ reports that its scan stopped. The agent then had no one
// left to stop it. This object lives as long as the bar does.
//
// The same goes for the rows of that section. BlueZ reports Paired before it
// answers the Pair call, so a new device moves from the nearby list to the
// paired list, and its row is destroyed, while `pairing` is still true. The
// row is gone by the time the pairing ends, so the trust and connect step
// lives here instead.
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

    // Devices whose Pair was pressed in the bar, one entry per device, until
    // that pairing ends. Each entry is a JavaScript object
    // `{ device, started, failedAt, check }`. `check` is the function
    // connected to the device's `pairing` and `paired` change signals, kept so
    // it can be disconnected again.
    property var afterPair: []
    // How long after a failed pairing a late Paired still counts, in
    // milliseconds. BlueZ sends Paired before it answers Pair, but this also
    // covers the opposite order.
    readonly property int lateSuccessWindow: 5000

    // Sent when a waiting Pair cannot go ahead because the agent did not
    // start. BluetoothDevices.qml shows "Pairing failed" for that device.
    signal pairRefused(var device)
    // Sent when a pairing from the bar ended and the device is not paired.
    // BluetoothDevices.qml shows "Pairing failed" for that device.
    signal pairFailed(var device)

    onWantedChanged: sync()

    // Pairs `device` once the agent has registered with BlueZ, then trusts and
    // connects it. BlueZ refuses a pairing that starts before an agent is
    // there to answer it.
    function pairWhenReady(device) {
        if (!device || waiting.includes(device))
            return;
        watchPairing(device);
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

    // Forgets the devices still waiting for the agent. Their pairing never
    // started, so nothing is left half done. Pairings that already started
    // are left to finish, and are still trusted and connected.
    function cancelWaiting() {
        for (const device of waiting)
            forgetPairing(device);
        waiting = [];
    }

    // Watches the pairing that a Pair press starts on `device`. Once it ends
    // with the device paired, trusts and connects the device, one time. A new
    // Pair press replaces an earlier entry for the same device, so one press
    // gives at most one connect.
    function watchPairing(device) {
        forgetPairing(device);
        // `started` turns true once the pairing has begun, so a change that
        // comes in before that is ignored. `failedAt` is the time the pairing
        // ended without Paired, or 0.
        const entry = { device: device, started: false, failedAt: 0, check: null };
        // `() => { ... }` is a short way to write a function. This one can
        // still use `entry` and `device` from the lines above when it runs.
        entry.check = () => {
            if (device.pairing) {
                entry.started = true;
                return;
            }
            if (!entry.started)
                return;
            if (device.paired) {
                forgetPairing(device);
                // Trusted devices may reconnect on their own later.
                device.trusted = true;
                device.connect();
            } else if (entry.failedAt === 0) {
                // The entry stays for `lateSuccessWindow`, in case Paired
                // comes in just after the answer to Pair.
                entry.failedAt = Date.now();
                root.pairFailed(device);
            }
        };
        device.pairingChanged.connect(entry.check);
        device.pairedChanged.connect(entry.check);
        afterPair = afterPair.concat([entry]);
    }

    // Stops watching the pairing of `device`, if it is watched. Also drops
    // entries whose device BlueZ has removed.
    function forgetPairing(device) {
        for (const entry of afterPair) {
            if (entry.device && entry.device === device) {
                device.pairingChanged.disconnect(entry.check);
                device.pairedChanged.disconnect(entry.check);
            }
        }
        afterPair = afterPair.filter(entry => entry.device && entry.device !== device);
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

    // Drops pairings that failed more than `lateSuccessWindow` ago. Runs only
    // while some pairing is watched.
    Timer {
        interval: 1000
        repeat: true
        running: root.afterPair.length > 0
        onTriggered: {
            const now = Date.now();
            for (const entry of root.afterPair) {
                if (entry.failedAt > 0 && now - entry.failedAt >= root.lateSuccessWindow)
                    root.forgetPairing(entry.device);
            }
        }
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
                for (const device of refused) {
                    root.forgetPairing(device);
                    root.pairRefused(device);
                }
                return;
            }

            if (action === "start") {
                // Pair first, then empty the list. pair() marks the device as
                // pairing at once, so `wanted` stays true the whole time and
                // the agent is not stopped in between.
                for (const device of root.waiting) {
                    if (!device)
                        continue;
                    // A device that got paired some other way while it
                    // waited is not paired again. Its row offers Connect.
                    if (device.paired)
                        root.forgetPairing(device);
                    else if (!device.pairing)
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
