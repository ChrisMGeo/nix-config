import QtQuick

// A soft light glow around a panel, the same glow niri draws around the
// focused window. Place it next to the panel, before it, so it is drawn
// underneath, and set `target` to the panel. It covers the panel plus
// Theme.glowReach on each side, and draws only outside the panel, so the
// see-through panel does not look lighter. The window must leave that much
// space around the panel, or the glow is cut off. Two panels side by side in
// separate windows, such as the settings drawer and the volume mixer, set
// `neighbor` and `skip` so their glows join into one instead of doubling.
ShaderEffect {
    // The panel to glow around. It must have the same parent as this item.
    property Item target

    // The values glow.frag reads, by the same names. See ../look.nix.
    property color glowColor: Theme.glow
    property real reach: Theme.glowReach
    property real sigma: Theme.glowSoftness / 2
    property real spread: Theme.glowSpread
    // Another panel next to this one, as a rectangle measured from the top
    // left corner of `target`. This item adds that panel's glow to its own,
    // but never past the brightest point of one glow, so the space between
    // the panels is no brighter than any other edge. The other panel's
    // window sets this panel the same way. Qt.rect(0, 0, 0, 0), a rectangle
    // with no width, means none.
    property rect neighbor: Qt.rect(0, 0, 0, 0)
    // An area, measured the same way, where this item draws nothing, because
    // the other panel's window lies over it and draws the glow there. Without
    // it both windows would draw that area, and the glow would double there.
    property rect skip: Qt.rect(0, 0, 0, 0)

    x: target ? target.x - reach : 0
    y: target ? target.y - reach : 0
    width: target ? target.width + 2 * reach : 0
    height: target ? target.height + 2 * reach : 0
    visible: target !== null && target.visible
    // glow.frag.qsb is built from glow.frag by ../quickshell.nix.
    fragmentShader: Qt.resolvedUrl("glow.frag.qsb")
}
