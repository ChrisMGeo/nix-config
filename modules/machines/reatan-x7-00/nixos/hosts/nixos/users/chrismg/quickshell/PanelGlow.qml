import QtQuick

// A soft light glow around a panel, the same glow niri draws around the
// focused window. Place it next to the panel, before it, so it is drawn
// underneath, and set `target` to the panel. It covers the panel plus
// Theme.glowReach on each side, and draws only outside the panel, so the
// see-through panel does not look lighter. The window must leave that much
// space around the panel, or the glow is cut off.
ShaderEffect {
    // The panel to glow around. It must have the same parent as this item.
    property Item target

    // The values glow.frag reads, by the same names. See ../look.nix.
    property color glowColor: Theme.glow
    property real reach: Theme.glowReach
    property real sigma: Theme.glowSoftness / 2
    property real spread: Theme.glowSpread

    x: target ? target.x - reach : 0
    y: target ? target.y - reach : 0
    width: target ? target.width + 2 * reach : 0
    height: target ? target.height + 2 * reach : 0
    visible: target !== null && target.visible
    // glow.frag.qsb is built from glow.frag by ../quickshell.nix.
    fragmentShader: Qt.resolvedUrl("glow.frag.qsb")
}
