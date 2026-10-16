pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

// The volume of each program, for the volume mixer. A program's volume is
// remembered once it is set in the mixer, and saved to app-volumes.json in
// Quickshell's state folder. The mixer then keeps showing that program after
// it stops playing or quits, and the saved volume is set again on every new
// stream the program opens.
Singleton {
    id: root

    // The remembered programs, keyed by name. Each value is an object with
    // `name`, `icon`, `volume` (0 to 1), and `muted`.
    property var saved: ({})

    // Every stream that plays sound, such as a browser tab or a music player.
    // Output devices, such as speakers, are left out, and so are recording
    // streams, which are not sinks.
    readonly property var streams: Pipewire.nodes.values
        .filter(node => node.isSink && node.isStream && node.audio !== null)

    // The names of the programs to show in the mixer: the ones playing now,
    // then the remembered ones that are not, each group in name order. A
    // stream's name is known only once it is ready, so it waits until then.
    readonly property var appKeys: {
        const running = [...new Set(streams.filter(node => node.ready).map(node => keyOf(node)))];
        const absent = Object.keys(saved).filter(key => !running.includes(key));
        const byName = (a, b) => a.localeCompare(b);
        return running.sort(byName).concat(absent.sort(byName));
    }

    // The name a program gives its streams, such as "Firefox". Programs that
    // give none fall back to the stream's own name.
    function keyOf(node) {
        return node?.properties["application.name"] || node?.description || node?.name || "Unknown";
    }

    // An icon name for a program, looked up in the icon theme by the mixer.
    // Many programs give none, so the program file's name is the fallback,
    // which often matches an icon, such as "firefox".
    function iconOf(node) {
        return node?.properties["application.icon-name"] || node?.properties["application.process.binary"] || "";
    }

    // The ready streams of one program. A browser can have one per tab.
    function nodesFor(key) {
        return streams.filter(node => node.ready && keyOf(node) === key);
    }

    // Sets a program's volume from the mixer, on all its streams, and
    // remembers it.
    function setVolume(key, volume) {
        const nodes = nodesFor(key);
        for (const node of nodes)
            node.audio.volume = volume;
        remember(key, nodes[0], { volume: volume });
    }

    function setMuted(key, muted) {
        const nodes = nodesFor(key);
        for (const node of nodes)
            node.audio.muted = muted;
        remember(key, nodes[0], { muted: muted });
    }

    // Stops remembering a program. The mixer drops its row once it is not
    // playing.
    function forget(key) {
        const next = Object.assign({}, saved);
        delete next[key];
        saved = next;
        saveTimer.restart();
    }

    // Saves a program's entry. `node`, when given, fills in the name, the
    // icon, and any value `changes` leaves out. A new object is assigned to
    // `saved`, because QML does not notice changes inside an existing one.
    function remember(key, node, changes) {
        const old = saved[key] ?? { name: key, icon: "", volume: 1, muted: false };
        const entry = Object.assign({}, old, node ? {
            icon: iconOf(node) || old.icon,
            volume: node.audio.volume,
            muted: node.audio.muted
        } : {}, changes);
        const next = Object.assign({}, saved);
        next[key] = entry;
        saved = next;
        saveTimer.restart();
    }

    // Binds every stream, so their names and volumes can be read and set.
    // PipeWire sends a node's details only while it is bound.
    PwObjectTracker {
        objects: root.streams
    }

    // One watcher per stream. `Variants` makes one copy of its contents for
    // each item in `model`.
    Variants {
        model: root.streams

        Scope {
            id: watcher

            required property var modelData
            readonly property var node: modelData
            // A stream can be ready before PipeWire has sent its channels.
            // Setting the volume before then does nothing, so this waits for
            // both.
            readonly property bool ready: (node?.ready ?? false) && (node?.audio?.volumes.length ?? 0) > 0
            // True once the saved volume, if any, was set on this stream.
            // Until then, volume changes are not saved, because the first one
            // is the stream's starting volume, not a choice.
            property bool restored: false
            // The program's name, kept from when the stream was ready. The
            // stream's details are erased when it ends, so the name cannot be
            // read again then.
            property string key: ""

            // `Qt.callLater` runs restore() once the current update is done.
            // Setting the volume inside it would change `ready`'s inputs while
            // `ready` is being worked out, which QML reports as a loop.
            onReadyChanged: Qt.callLater(restore)
            Component.onCompleted: Qt.callLater(restore)

            // Gives a new stream the volume its program was given in the
            // mixer. WirePlumber also restores stream volumes, but it does
            // not know about volumes set while the program was not running.
            function restore() {
                if (restored || !ready)
                    return;
                restored = true;
                key = root.keyOf(node);

                const entry = root.saved[key];
                if (entry) {
                    node.audio.volume = entry.volume;
                    node.audio.muted = entry.muted;
                }
            }

            // Keeps a remembered program's volume current when it changes
            // outside the mixer, such as from the program itself, so the row
            // shows the right value after the program quits.
            //
            // When a stream ends, Quickshell empties its list of channel
            // volumes and reports that as a volume change. An empty list
            // reads as a volume of 0, so changes are skipped unless the
            // stream is still ready with its channels. Otherwise every
            // program would be saved at 0 when it stops playing.
            function follow() {
                const live = (node?.ready ?? false) && (node?.audio?.volumes.length ?? 0) > 0;
                if (restored && live && key in root.saved)
                    root.remember(key, node, {});
            }

            Connections {
                target: watcher.node?.audio ?? null

                function onVolumesChanged() {
                    watcher.follow();
                }

                function onMutedChanged() {
                    watcher.follow();
                }
            }
        }
    }

    FileView {
        id: store

        path: Quickshell.statePath("app-volumes.json")
        // Reads the file before the first stream appears, so its saved volume
        // can be set on it.
        blockLoading: true
        // The file is missing until a volume is first set. That is expected,
        // so it is not reported.
        printErrors: false
        onLoaded: {
            try {
                root.saved = JSON.parse(text());
            } catch (error) {
                console.warn("Could not read app-volumes.json:", error);
            }
        }
    }

    // Waits half a second after the last change before writing the file, so
    // dragging a slider does not write it on every step.
    Timer {
        id: saveTimer

        interval: 500
        onTriggered: store.setText(JSON.stringify(root.saved, null, 2))
    }
}
