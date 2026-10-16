pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// The activity monitor: a window with CPU, memory, GPU, and video memory use
// over the last two minutes, details for the chosen one, and the programs that
// use the most CPU or memory. Clicking a usage gauge in the bar opens it with
// that gauge's measure chosen. shell.qml creates it while it is open and
// destroys it when it closes, so it reads nothing while closed.
//
// It is a normal window, not a panel, so niri places it, focuses it, and
// closes it with Mod+Q. niri.nix makes it float and blurs what is behind it.
FloatingWindow {
    id: root

    // The measure shown in the large chart: "cpu", "memory", "gpu", or "vram".
    // Set by shell.qml. Clicking a tile asks for another one with
    // metricSelected().
    property string metric: "cpu"
    // A measure that this computer cannot read, such as the GPU on a computer
    // without one, falls back to the CPU.
    readonly property string shownMetric: available(metric) ? metric : "cpu"
    // Which column orders the process list: "name", "cpu", "memory", "gpu",
    // "vram", or "" for no order, which lists programs in the order they
    // started. Choosing a measure sorts by its column, busiest first. Clicking
    // a column title changes it. See sortBy().
    property string sortColumn: "cpu"
    property bool sortDescending: true
    // The number columns of the process list, after the name. Each `id` is
    // also a measure, so its bars use that tile's color. GPU and VRAM show
    // only when this computer reports them.
    readonly property var columns: [
        { id: "cpu", label: "CPU", width: Theme.scaled(64) },
        { id: "memory", label: "Memory", width: Theme.scaled(80) },
        { id: "gpu", label: "GPU", width: Theme.scaled(56) },
        { id: "vram", label: "VRAM", width: Theme.scaled(80) }
    ].filter(column => available(column.id))

    // Filled from Theme.activityCommand. See ../quickshell.nix for the format.
    property var coreUsage: []
    property real uptime: 0
    property var loadAverage: []
    property real cachedMemory: 0
    property real swapUsed: 0
    property real swapTotal: 0
    property string cpuModel: ""
    // In kHz, millidegrees, microwatts, and Hz, as the kernel reports them.
    // -1 means this computer has no such sensor.
    property real cpuFrequency: -1
    property real cpuTemperature: -1
    property real gpuTemperature: -1
    property real gpuPower: -1
    property real gpuClock: -1
    // One entry per program name, with every process of that name added up.
    property var processGroups: []
    property int processCount: 0
    // The largest value in the sorted column, so each row's bar can show its
    // share of the busiest program.
    property real processMaximum: 0
    // How many readings have arrived. CPU use needs two.
    property int samples: 0

    // The last reading, to compare the next one with.
    property var previousCores: []
    property var previousTotal: null
    property var previousProcessTimes: ({})
    property var previousGpuTimes: ({})
    property real previousReadingTime: 0

    readonly property var metrics: [
        { id: "cpu", label: "CPU", glyph: "" },
        { id: "memory", label: "RAM", glyph: "" },
        { id: "gpu", label: "GPU", glyph: "" },
        { id: "vram", label: "VRAM", glyph: "" }
    ]
    readonly property var availableMetrics: metrics.filter(entry => available(entry.id))
    readonly property var shownEntry: metrics.find(entry => entry.id === shownMetric)
    readonly property color tint: colorOf(shownMetric)

    signal metricSelected(string metric)
    signal closeRequested()

    // niri.nix matches this title to make the window float.
    title: "Activity monitor"
    implicitWidth: Theme.scaled(760)
    implicitHeight: Theme.scaled(820)
    // The Rectangle below draws the see-through background.
    color: "transparent"

    // Closing the window from niri, such as with Mod+Q, hides it. Tell
    // shell.qml, so the next click on a gauge opens it again.
    onVisibleChanged: {
        if (!visible)
            closeRequested();
    }

    // The process columns have the same names as the measures, so choosing a
    // measure sorts by its own column.
    onShownMetricChanged: {
        sortColumn = shownMetric;
        sortDescending = true;
    }
    onSortColumnChanged: showProcesses()
    onSortDescendingChanged: showProcesses()
    Component.onCompleted: sortColumn = shownMetric

    // Clicking a column title cycles through its orders, then back to none.
    // Numbers start with the largest first, and names start with A.
    function sortBy(column) {
        const firstDescending = column !== "name";
        if (sortColumn !== column) {
            sortColumn = column;
            sortDescending = firstDescending;
        } else if (sortDescending === firstDescending) {
            sortDescending = !firstDescending;
        } else {
            sortColumn = "";
        }
    }

    function available(id) {
        if (id === "gpu")
            return SystemUsage.gpuAvailable;
        if (id === "vram")
            return SystemUsage.vramAvailable;
        return true;
    }

    // Each measure gets its own Stylix accent color.
    function colorOf(id) {
        switch (id) {
        case "memory": return Theme.magenta;
        case "gpu": return Theme.positive;
        case "vram": return Theme.cyan;
        default: return Theme.accent;
        }
    }

    // SystemUsage names its percentages and histories after the measures, such
    // as `cpu` and `cpuHistory`. `object[name]` reads a property by name.
    function valueOf(id) {
        return SystemUsage[id];
    }

    function historyOf(id) {
        return SystemUsage[`${id}History`];
    }

    function bytesText(bytes) {
        const gigabyte = 1024 * 1024 * 1024;
        if (bytes >= gigabyte)
            return `${(bytes / gigabyte).toFixed(1)} GB`;
        return `${Math.round(bytes / (1024 * 1024))} MB`;
    }

    function durationText(seconds) {
        const days = Math.floor(seconds / 86400);
        const hours = Math.floor(seconds % 86400 / 3600);
        const minutes = Math.floor(seconds % 3600 / 60);
        if (days > 0)
            return `${days}d ${hours}h`;
        if (hours > 0)
            return `${hours}h ${minutes}m`;
        return `${minutes}m`;
    }

    function temperatureText(millidegrees) {
        return `${Math.round(millidegrees / 1000)}°C`;
    }

    // The short line under each tile's percentage.
    function captionOf(id) {
        switch (id) {
        case "cpu":
            return cpuTemperature >= 0 ? temperatureText(cpuTemperature) : `${coreUsage.length} cores`;
        case "memory":
            return SystemUsage.memoryText(SystemUsage.memoryUsed, SystemUsage.memoryTotal);
        case "gpu":
            return gpuTemperature >= 0 ? temperatureText(gpuTemperature) : "";
        default:
            return SystemUsage.memoryText(SystemUsage.vramUsed, SystemUsage.vramTotal);
        }
    }

    // The text beside the large chart's title.
    function subtitleOf(id) {
        switch (id) {
        case "cpu":
            return cpuModel;
        case "memory":
            return `${bytesText(SystemUsage.memoryUsed)} of ${bytesText(SystemUsage.memoryTotal)} in use`;
        case "gpu":
            return "Time the graphics card spends busy";
        default:
            return `${bytesText(SystemUsage.vramUsed)} of ${bytesText(SystemUsage.vramTotal)} in use`;
        }
    }

    // The small labeled numbers under the large chart. Readings this computer
    // does not have are left out.
    function statsOf(id) {
        const stats = [];
        const add = (label, value) => stats.push({ label: label, value: value });
        switch (id) {
        case "cpu":
            if (cpuFrequency >= 0)
                add("Speed", `${(cpuFrequency / 1e6).toFixed(2)} GHz`);
            if (cpuTemperature >= 0)
                add("Temperature", temperatureText(cpuTemperature));
            if (loadAverage.length === 3)
                add("Load average", loadAverage.join("  "));
            add("Cores", String(coreUsage.length));
            break;
        case "memory": {
            const free = SystemUsage.memoryTotal - SystemUsage.memoryUsed;
            add("In use", bytesText(SystemUsage.memoryUsed));
            add("Cache", bytesText(Math.min(cachedMemory, free)));
            add("Available", bytesText(free));
            add("Swap", swapTotal > 0 ? `${bytesText(swapUsed)} of ${bytesText(swapTotal)}` : "Off");
            break;
        }
        case "gpu":
            if (gpuTemperature >= 0)
                add("Temperature", temperatureText(gpuTemperature));
            if (gpuPower >= 0)
                add("Power", `${(gpuPower / 1e6).toFixed(1)} W`);
            if (gpuClock >= 0)
                add("Clock", `${(gpuClock / 1e9).toFixed(2)} GHz`);
            if (SystemUsage.vramAvailable)
                add("Video memory", bytesText(SystemUsage.vramUsed));
            break;
        default:
            add("In use", bytesText(SystemUsage.vramUsed));
            add("Free", bytesText(SystemUsage.vramTotal - SystemUsage.vramUsed));
            add("Total", bytesText(SystemUsage.vramTotal));
            break;
        }
        return stats;
    }

    // The text of one cell in the process list.
    function cellText(column, value) {
        if (column === "cpu" || column === "gpu")
            return `${value.toFixed(1)}%`;
        return bytesText(value);
    }

    // Whether a cell shows almost nothing, under 0.1% or 1 MB.
    function isIdle(column, value) {
        if (column === "cpu" || column === "gpu")
            return value < 0.1;
        return value < 1024 * 1024;
    }

    // A column title in the process list. Clicking it sorts by that column,
    // and an arrow beside the label shows the order while it does. `component`
    // defines a small type for use only in this file.
    component ColumnTitle: Item {
        id: title

        property string label
        property bool alignRight: true
        property bool active: false
        property bool descending: true

        signal clicked()

        implicitHeight: titleRow.implicitHeight + 4

        RowLayout {
            id: titleRow

            anchors.fill: parent
            spacing: 4
            // Right to left puts the label at the right edge, over the
            // numbers, with the arrow before it.
            layoutDirection: title.alignRight ? Qt.RightToLeft : Qt.LeftToRight

            UiText {
                text: title.label
                color: title.active || titleMouse.containsMouse ? Theme.text : Theme.textMuted
                font.pixelSize: Theme.scaled(10)
                font.weight: title.active ? Font.DemiBold : Font.Normal
            }

            // A caret that points down for largest or Z first, and up for
            // smallest or A first.
            UiText {
                visible: title.active
                text: title.descending ? "" : ""
                font.family: Theme.iconFontFamily
                font.pixelSize: Theme.scaled(9)
            }

            Item {
                Layout.fillWidth: true
            }
        }

        MouseArea {
            id: titleMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: title.clicked()
        }
    }

    // Nix wrappers rename a program `foo` to `.foo-wrapped`. Show the name
    // people know.
    function programName(name) {
        return name.replace(/^\.(.+)-wrapped$/, "$1");
    }

    // Reads one output of Theme.activityCommand. See ../quickshell.nix for
    // the format.
    function readDetails(text) {
        const cores = [];
        let total = null;
        const processes = [];
        let frequency = -1;
        let cpuTemp = -1;
        let gpuTemp = -1;
        let power = -1;
        let clock = -1;
        let readingTime = 0;

        for (const line of text.split("\n")) {
            const fields = line.split(" ");
            switch (fields[0]) {
            case "core": {
                const reading = { total: Number(fields[2]), idle: Number(fields[3]) };
                if (fields[1] === "cpu")
                    total = reading;
                else
                    cores.push(reading);
                break;
            }
            case "uptime": uptime = Number(fields[1]); break;
            case "load": loadAverage = fields.slice(1, 4); break;
            case "memory":
                cachedMemory = Number(fields[1]);
                swapUsed = Number(fields[2]);
                swapTotal = Number(fields[3]);
                break;
            case "cpumodel": cpuModel = line.slice("cpumodel".length).trim(); break;
            case "cpufreq": frequency = Number(fields[1]); break;
            case "cputemp": cpuTemp = Number(fields[1]); break;
            case "gputemp": gpuTemp = Number(fields[1]); break;
            case "gpupower": power = Number(fields[1]); break;
            case "gpuclock": clock = Number(fields[1]); break;
            case "clock": readingTime = Number(fields[1]); break;
            case "proc":
                processes.push({
                    pid: fields[1],
                    time: Number(fields[2]),
                    memory: Number(fields[3]),
                    gpuTime: Number(fields[4]),
                    vram: Number(fields[5]),
                    // The name is last and can hold spaces.
                    name: fields.slice(6).join(" ")
                });
                break;
            }
        }

        cpuFrequency = frequency;
        cpuTemperature = cpuTemp;
        gpuTemperature = gpuTemp;
        gpuPower = power;
        gpuClock = clock;

        // Each core's use is the share of time it was not idle since the last
        // reading.
        coreUsage = cores.map((core, index) => {
            const before = previousCores[index];
            const elapsed = before ? core.total - before.total : 0;
            if (elapsed <= 0)
                return 0;
            return Math.max(0, Math.min(100, 100 * (elapsed - (core.idle - before.idle)) / elapsed));
        });
        previousCores = cores;

        // A process's CPU use is its share of the time of all cores together,
        // like the CPU gauge. A program that keeps one of 16 cores busy shows
        // about 6%, and the rows add up to the CPU tile.
        const elapsedTotal = total && previousTotal ? total.total - previousTotal.total : 0;
        // GPU use is the GPU time a process used, in nanoseconds, out of the
        // time that passed, in seconds.
        const elapsedNanoseconds = previousReadingTime > 0 ? (readingTime - previousReadingTime) * 1e9 : 0;
        const times = {};
        const gpuTimes = {};
        const groups = {};
        for (const process of processes) {
            const before = previousProcessTimes[process.pid];
            const share = elapsedTotal > 0 && before !== undefined
                ? 100 * Math.max(0, process.time - before) / elapsedTotal
                : 0;
            times[process.pid] = process.time;

            const gpuBefore = previousGpuTimes[process.pid];
            const gpuShare = elapsedNanoseconds > 0 && gpuBefore !== undefined
                ? 100 * Math.max(0, process.gpuTime - gpuBefore) / elapsedNanoseconds
                : 0;
            gpuTimes[process.pid] = process.gpuTime;

            const name = programName(process.name);
            const group = groups[name] ?? (groups[name] = {
                name: name,
                instances: 0,
                firstPid: Number(process.pid),
                cpu: 0,
                memory: 0,
                gpu: 0,
                vram: 0
            });
            group.instances += 1;
            group.firstPid = Math.min(group.firstPid, Number(process.pid));
            group.cpu += share;
            group.memory += process.memory;
            group.gpu += gpuShare;
            group.vram += process.vram;
        }
        previousTotal = total;
        previousProcessTimes = times;
        previousGpuTimes = gpuTimes;
        previousReadingTime = readingTime;

        // Several GPU engines can run at once, so a program's sum can pass
        // 100%. Show at most 100.
        for (const group of Object.values(groups))
            group.gpu = Math.min(100, group.gpu);

        processGroups = Object.values(groups);
        processCount = processes.length;
        samples += 1;
        showProcesses();
    }

    // Copies the programs into processModel in the chosen order. Changing rows
    // in place, instead of giving the list a new array, keeps its scroll
    // position.
    function showProcesses() {
        const column = sortColumn;
        const direction = sortDescending ? -1 : 1;
        // Ties, and the "no order" setting, fall back to the order the
        // programs started in, which is the lowest process ID first.
        const byStart = (left, right) => left.firstPid - right.firstPid;
        const compare = column === ""
            ? byStart
            : column === "name"
                ? (left, right) => direction * left.name.localeCompare(right.name) || byStart(left, right)
                : (left, right) => direction * (left[column] - right[column]) || byStart(left, right);
        const rows = processGroups.slice().sort(compare);

        for (let index = 0; index < rows.length; index++) {
            if (index < processModel.count)
                processModel.set(index, rows[index]);
            else
                processModel.append(rows[index]);
        }
        if (processModel.count > rows.length)
            processModel.remove(rows.length, processModel.count - rows.length);

        // The bars behind the rows show numbers only.
        const numeric = column !== "" && column !== "name";
        processMaximum = numeric ? Math.max(0, ...rows.map(row => row[column])) : 0;
    }

    ListModel {
        id: processModel
    }

    Process {
        id: detailsQuery

        command: [Theme.activityCommand]
        running: true

        stdout: StdioCollector {
            onStreamFinished: root.readDetails(text)
        }
    }

    // Reads again every 2 seconds. The second reading comes sooner, because
    // CPU use needs two readings and the window would show zeros until then.
    Timer {
        interval: root.samples < 2 ? 600 : 2000
        repeat: true
        running: true
        onTriggered: {
            if (!detailsQuery.running)
                detailsQuery.running = true;
        }
    }

    Rectangle {
        anchors.fill: parent
        // niri rounds the window's corners to 12 pixels, the same as
        // Theme.radius. See niri.nix. There is no border here, because niri
        // draws the same outline around this window as around every other.
        radius: Theme.radius
        color: Theme.panel

        // Escape closes the window, and 1 to 4 choose a measure.
        focus: true
        Keys.onEscapePressed: root.closeRequested()
        Keys.onPressed: event => {
            const index = event.key - Qt.Key_1;
            if (index >= 0 && index < root.availableMetrics.length) {
                root.metricSelected(root.availableMetrics[index].id);
                event.accepted = true;
            }
        }

        ColumnLayout {
            anchors {
                fill: parent
                margins: 14
            }
            spacing: 12

            // The title, uptime, and close button.
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                UiText {
                    text: ""
                    color: Theme.accent
                    font.family: Theme.iconFontFamily
                    font.pixelSize: Theme.scaled(14)
                }

                UiText {
                    text: "Activity"
                    color: Theme.accent
                    font.pixelSize: Theme.scaled(16)
                    font.weight: Font.DemiBold
                }

                UiText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                    text: root.uptime > 0 ? `Up ${root.durationText(root.uptime)}` : ""
                    color: Theme.textMuted
                    font.pixelSize: Theme.scaled(11)
                }

                IconButton {
                    glyph: ""
                    glyphFontFamily: Theme.iconFontFamily
                    tooltip: "Close"
                    onClicked: root.closeRequested()
                }
            }

            // One tile per measure, with its percentage and a small chart.
            // Clicking one shows it in the large chart below.
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: root.availableMetrics

                    Rectangle {
                        id: tile

                        required property var modelData
                        readonly property bool selected: root.shownMetric === modelData.id
                        readonly property color tint: root.colorOf(modelData.id)

                        // Equal preferred widths split the row evenly.
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: Theme.scaled(108)
                        radius: Theme.radius - 3
                        color: selected
                            ? Qt.rgba(tint.r, tint.g, tint.b, 0.1)
                            : tileMouse.containsMouse ? Theme.subtleButton : "transparent"
                        border.color: selected ? tint : Theme.outlineFaint
                        border.width: Theme.compactOutlineWidth

                        Behavior on color {
                            ColorAnimation { duration: 140 }
                        }

                        ColumnLayout {
                            anchors {
                                fill: parent
                                margins: 10
                            }
                            spacing: 2

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                UiText {
                                    text: tile.modelData.glyph
                                    color: tile.tint
                                    font.family: Theme.iconFontFamily
                                    font.pixelSize: Theme.scaled(10)
                                }

                                UiText {
                                    Layout.fillWidth: true
                                    text: tile.modelData.label
                                    color: Theme.textMuted
                                    font.pixelSize: Theme.scaled(11)
                                    font.weight: Font.DemiBold
                                }
                            }

                            UiText {
                                text: `${Math.round(root.valueOf(tile.modelData.id))}%`
                                font.pixelSize: Theme.scaled(22)
                                font.weight: Font.DemiBold
                            }

                            UiText {
                                Layout.fillWidth: true
                                text: root.captionOf(tile.modelData.id)
                                color: Theme.textMuted
                                font.pixelSize: Theme.scaled(10)
                                elide: Text.ElideRight
                            }

                            UsageChart {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                values: root.historyOf(tile.modelData.id)
                                lineColor: tile.tint
                                lineWidth: 1.5
                            }
                        }

                        MouseArea {
                            id: tileMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.metricSelected(tile.modelData.id)
                        }
                    }
                }
            }

            // The chosen measure: a large chart, its details, and a bar per
            // core or a bar of memory use.
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: detailColumn.implicitHeight + 24
                radius: Theme.radius - 3
                color: "transparent"
                border.color: Theme.outlineFaint
                border.width: Theme.compactOutlineWidth

                ColumnLayout {
                    id: detailColumn

                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: 12
                    }
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        UiText {
                            text: root.shownEntry.label
                            font.pixelSize: Theme.scaled(15)
                            font.weight: Font.DemiBold
                        }

                        UiText {
                            Layout.fillWidth: true
                            text: root.subtitleOf(root.shownMetric)
                            color: Theme.textMuted
                            font.pixelSize: Theme.scaled(11)
                            elide: Text.ElideRight
                        }

                        UiText {
                            text: `${Math.round(root.valueOf(root.shownMetric))}%`
                            color: root.tint
                            font.pixelSize: Theme.scaled(24)
                            font.weight: Font.DemiBold
                        }
                    }

                    // The chart, with the percentage of each grid line on the
                    // right.
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Theme.scaled(120)

                        UsageChart {
                            anchors {
                                fill: parent
                                rightMargin: Theme.scaled(34)
                            }
                            values: root.historyOf(root.shownMetric)
                            lineColor: root.tint
                            showGrid: true
                            showHead: true
                        }

                        Repeater {
                            model: [75, 50, 25]

                            UiText {
                                required property int modelData

                                anchors.right: parent.right
                                y: parent.height * (1 - modelData / 100) - height / 2
                                text: `${modelData}%`
                                color: Theme.textMuted
                                font.pixelSize: Theme.scaled(9)
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.rightMargin: Theme.scaled(34)

                        UiText {
                            text: `${Math.round(SystemUsage.historyLength * SystemUsage.sampleInterval / 60000)} min ago`
                            color: Theme.textMuted
                            font.pixelSize: Theme.scaled(9)
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        UiText {
                            text: "Now"
                            color: Theme.textMuted
                            font.pixelSize: Theme.scaled(9)
                        }
                    }

                    // The details, each a label over a number.
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 4
                        spacing: 8

                        Repeater {
                            model: root.statsOf(root.shownMetric)

                            Rectangle {
                                id: stat

                                required property var modelData

                                Layout.fillWidth: true
                                Layout.preferredWidth: 1
                                implicitHeight: statColumn.implicitHeight + 14
                                radius: Theme.radius - 5
                                color: Theme.subtleButton

                                Column {
                                    id: statColumn

                                    anchors {
                                        left: parent.left
                                        right: parent.right
                                        verticalCenter: parent.verticalCenter
                                        leftMargin: 10
                                        rightMargin: 10
                                    }
                                    spacing: 1

                                    UiText {
                                        width: parent.width
                                        text: stat.modelData.label
                                        color: Theme.textMuted
                                        font.pixelSize: Theme.scaled(10)
                                        elide: Text.ElideRight
                                    }

                                    UiText {
                                        width: parent.width
                                        text: stat.modelData.value
                                        font.pixelSize: Theme.scaled(13)
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }
                    }

                    // CPU: one bar per core, filled from the bottom.
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Theme.scaled(40)
                        visible: root.shownMetric === "cpu" && root.coreUsage.length > 0
                        spacing: 3

                        Repeater {
                            model: root.coreUsage.length

                            Rectangle {
                                id: core

                                required property int index
                                readonly property real usage: root.coreUsage[index] ?? 0

                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                // A small fixed rounding for the thin bars. It does not follow
                                // Theme.radius, which is for windows and panels.
                                radius: 3
                                color: Theme.subtleButton

                                Rectangle {
                                    anchors {
                                        left: parent.left
                                        right: parent.right
                                        bottom: parent.bottom
                                    }
                                    height: Math.max(2, parent.height * core.usage / 100)
                                    radius: 3
                                    color: root.tint

                                    Behavior on height {
                                        NumberAnimation {
                                            duration: 400
                                            easing.type: Easing.OutCubic
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // RAM and VRAM: one bar of the whole memory. The solid part
                    // is in use. For RAM, the faint part after it is cache,
                    // which the system frees when programs need it.
                    Rectangle {
                        id: memoryBar

                        readonly property bool system: root.shownMetric === "memory"
                        readonly property real total: system ? SystemUsage.memoryTotal : SystemUsage.vramTotal
                        readonly property real used: system ? SystemUsage.memoryUsed : SystemUsage.vramUsed
                        readonly property real cached: system ? Math.min(root.cachedMemory, total - used) : 0

                        Layout.fillWidth: true
                        Layout.preferredHeight: Theme.scaled(10)
                        visible: (root.shownMetric === "memory" || root.shownMetric === "vram") && total > 0
                        radius: height / 2
                        color: Theme.subtleButton

                        Rectangle {
                            height: parent.height
                            width: parent.width * (memoryBar.used + memoryBar.cached) / Math.max(1, memoryBar.total)
                            radius: height / 2
                            color: Qt.rgba(root.tint.r, root.tint.g, root.tint.b, 0.35)
                        }

                        Rectangle {
                            height: parent.height
                            width: parent.width * memoryBar.used / Math.max(1, memoryBar.total)
                            radius: height / 2
                            color: root.tint
                        }
                    }
                }
            }

            // The programs that use the most, with all processes of one
            // program added together.
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Theme.radius - 3
                color: "transparent"
                border.color: Theme.outlineFaint
                border.width: Theme.compactOutlineWidth

                ColumnLayout {
                    anchors {
                        fill: parent
                        margins: 12
                    }
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        UiText {
                            text: "Processes"
                            font.pixelSize: Theme.scaled(15)
                            font.weight: Font.DemiBold
                        }

                        UiText {
                            Layout.fillWidth: true
                            text: root.processCount > 0 ? `${root.processCount} running` : ""
                            color: Theme.textMuted
                            font.pixelSize: Theme.scaled(11)
                        }
                    }

                    // Column titles. The widths match the rows below.
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 8
                        Layout.rightMargin: 8
                        spacing: 6

                        ColumnTitle {
                            Layout.fillWidth: true
                            label: "Name"
                            alignRight: false
                            active: root.sortColumn === "name"
                            descending: root.sortDescending
                            onClicked: root.sortBy("name")
                        }

                        Repeater {
                            model: root.columns

                            ColumnTitle {
                                required property var modelData

                                Layout.preferredWidth: modelData.width
                                label: modelData.label
                                active: root.sortColumn === modelData.id
                                descending: root.sortDescending
                                onClicked: root.sortBy(modelData.id)
                            }
                        }
                    }

                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 2
                        boundsBehavior: Flickable.StopAtBounds
                        model: processModel

                        delegate: Rectangle {
                            id: row

                            required property string name
                            required property int instances
                            required property real cpu
                            required property real memory
                            required property real gpu
                            required property real vram
                            // The value in the sorted column, or 0 when the
                            // list is sorted by name or not at all.
                            readonly property real sorted: root.processMaximum > 0 ? row[root.sortColumn] : 0
                            readonly property color barColor: root.colorOf(root.sortColumn)

                            width: ListView.view.width
                            height: Theme.scaled(28)
                            radius: Theme.radius - 5
                            color: rowHover.hovered ? Theme.subtleButton : "transparent"

                            // A faint bar behind the row, as long as its share
                            // of the busiest program in the sorted column. It
                            // hides while shorter than its rounded ends, where
                            // it would only be a sliver.
                            Rectangle {
                                visible: width >= radius * 2
                                anchors {
                                    left: parent.left
                                    top: parent.top
                                    bottom: parent.bottom
                                }
                                width: root.processMaximum > 0 ? parent.width * row.sorted / root.processMaximum : 0
                                radius: parent.radius
                                color: Qt.rgba(row.barColor.r, row.barColor.g, row.barColor.b, 0.1)

                                Behavior on width {
                                    NumberAnimation {
                                        duration: 300
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }

                            RowLayout {
                                anchors {
                                    fill: parent
                                    leftMargin: 8
                                    rightMargin: 8
                                }
                                spacing: 6

                                UiText {
                                    Layout.fillWidth: true
                                    text: row.name
                                    elide: Text.ElideRight
                                }

                                // How many processes the program runs, such as
                                // a browser's tabs.
                                UiText {
                                    visible: row.instances > 1
                                    text: `×${row.instances}`
                                    color: Theme.textMuted
                                    font.pixelSize: Theme.scaled(10)
                                }

                                // One cell per column. `row[id]` reads the
                                // row's value for that column by name.
                                Repeater {
                                    model: root.columns

                                    UiText {
                                        required property var modelData
                                        readonly property real value: row[modelData.id]

                                        Layout.preferredWidth: modelData.width
                                        horizontalAlignment: Text.AlignRight
                                        text: root.cellText(modelData.id, value)
                                        // Idle programs fade, so busy ones stand out.
                                        color: root.isIdle(modelData.id, value) ? Theme.textMuted : Theme.text
                                    }
                                }
                            }

                            HoverHandler {
                                id: rowHover
                            }
                        }
                    }
                }
            }
        }
    }
}
