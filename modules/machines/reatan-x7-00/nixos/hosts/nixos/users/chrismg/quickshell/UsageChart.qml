import QtQuick

// A line chart of percentages from 0 to 100, with the area under the line
// filled with a fade. The newest value is on the right edge. Used in the
// activity monitor, both as the small chart on each tile and as the large one.
Canvas {
    id: root

    // The values to draw, oldest first.
    property var values: []
    // How many values fit across the chart. Fewer values start partway in, so
    // the chart fills from the right as samples arrive.
    property int capacity: SystemUsage.historyLength
    property color lineColor: Theme.accent
    property real lineWidth: 2
    // Faint lines at 25, 50, and 75 percent, for the large chart.
    property bool showGrid: false
    // A dot on the newest value, for the large chart.
    property bool showHead: false

    antialiasing: true

    onValuesChanged: requestPaint()
    onLineColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const context = getContext("2d");
        context.clearRect(0, 0, width, height);

        if (showGrid) {
            context.lineWidth = 1;
            context.strokeStyle = Theme.outlineFaint;
            for (const fraction of [0.25, 0.5, 0.75]) {
                // The half pixel puts a 1 pixel line on one row of pixels
                // instead of blurring it across two.
                const y = Math.round(height * fraction) + 0.5;
                context.beginPath();
                context.moveTo(0, y);
                context.lineTo(width, y);
                context.stroke();
            }
        }

        const count = values.length;
        if (count < 2)
            return;

        const step = width / Math.max(1, capacity - 1);
        const first = Math.max(0, capacity - count);
        const top = lineWidth;
        const usable = height - lineWidth * 2;
        const points = values.map((value, index) => ({
            x: (first + index) * step,
            y: top + usable * (1 - Math.max(0, Math.min(100, value)) / 100)
        }));

        // Traces the line with gentle curves. Each curve bends toward one
        // sample and ends halfway to the next, which smooths the corners
        // without overshooting.
        function trace() {
            context.moveTo(points[0].x, points[0].y);
            for (let index = 1; index < points.length - 1; index++) {
                const middleX = (points[index].x + points[index + 1].x) / 2;
                const middleY = (points[index].y + points[index + 1].y) / 2;
                context.quadraticCurveTo(points[index].x, points[index].y, middleX, middleY);
            }
            const last = points[points.length - 1];
            context.lineTo(last.x, last.y);
        }

        const fade = context.createLinearGradient(0, 0, 0, height);
        fade.addColorStop(0, Qt.rgba(lineColor.r, lineColor.g, lineColor.b, 0.32));
        fade.addColorStop(1, Qt.rgba(lineColor.r, lineColor.g, lineColor.b, 0));
        context.beginPath();
        trace();
        context.lineTo(points[points.length - 1].x, height);
        context.lineTo(points[0].x, height);
        context.closePath();
        context.fillStyle = fade;
        context.fill();

        context.beginPath();
        trace();
        context.lineWidth = lineWidth;
        context.lineJoin = "round";
        context.lineCap = "round";
        context.strokeStyle = lineColor;
        context.stroke();

        if (showHead) {
            const last = points[points.length - 1];
            context.beginPath();
            context.arc(last.x - lineWidth, last.y, lineWidth * 2, 0, Math.PI * 2);
            context.fillStyle = lineColor;
            context.fill();
        }
    }
}
