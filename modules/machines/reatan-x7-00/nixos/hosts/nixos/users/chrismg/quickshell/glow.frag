// The fragment shader for PanelGlow.qml. It draws a soft light glow around a
// rectangle, with the same math niri uses for the glow around the focused
// window, so the panels and windows match. ../quickshell.nix compiles it to
// glow.frag.qsb with Qt's qsb tool, because Qt 6 cannot read plain GLSL.

#version 440

// Where this pixel is in the item, from 0 to 1 on each axis. Qt's default
// vertex shader fills it in.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

// Qt fills these in from the ShaderEffect properties of the same name.
// qt_Matrix and qt_Opacity come from Qt itself. The block must start with them.
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    // The glow color. Qt passes it premultiplied, so the shader only scales it.
    vec4 glowColor;
    // The size of the whole effect item, glow included, in pixels.
    float width;
    float height;
    // How much space the item leaves around the panel on each side.
    float reach;
    // Half the softness. See look.glowSoftness in ../look.nix.
    float sigma;
    // How far outside the panel the glow starts to fade.
    float spread;
    // A second panel next to this one, as x, y, width, and height in pixels
    // from this panel's top left corner. A width of 0 means none. Its glow is
    // added to this one, but the sum stops at the brightest point of a single
    // glow, so where the two meet the glow is full, not doubled. Its panel
    // stays clear, like this one.
    vec4 neighbor;
    // An area, in the same units, where this item draws nothing, because
    // another window draws the glow there. A width of 0 means none.
    vec4 skip;
};

// An approximation of the error function, the same one niri's shadow shader
// uses. GLSL has no built-in one.
float erfApprox(float x) {
    float s = sign(x);
    float a = abs(x);
    float t = 1.0 + (0.278393 + (0.230389 + 0.078108 * (a * a)) * a) * a;
    t *= t;
    return s - s / (t * t);
}

// How much of the glow reaches the point `p` along one axis, for a strip
// from `low` to `high` blurred with a Gaussian curve. It is 1 deep inside the
// strip and fades to 0 outside it.
float strip(float p, float low, float high) {
    float k = sqrt(0.5) / sigma;
    return 0.5 * (erfApprox((high - p) * k) - erfApprox((low - p) * k));
}

// Whether the point `p` is inside the rectangle `r`, given as x, y, width,
// and height. A rectangle with a width of 0 holds nothing.
bool inside(vec2 p, vec4 r) {
    return r.z > 0.0 && p.x >= r.x && p.y >= r.y
        && p.x <= r.x + r.z && p.y <= r.y + r.w;
}

// How strong the glow around the panel `r` is at the point `p`. A blurred
// rectangle is the product of a blurred strip on each axis. This gives
// straight lines of equal brightness near the corners, which keeps them
// square.
float glowAround(vec2 p, vec4 r) {
    return strip(p.x, r.x - spread, r.x + r.z + spread)
        * strip(p.y, r.y - spread, r.y + r.w + spread);
}

void main() {
    // This pixel in pixels, measured from the panel's top left corner.
    vec2 p = qt_TexCoord0 * vec2(width, height) - vec2(reach);
    vec4 panel = vec4(0.0, 0.0, width - 2.0 * reach, height - 2.0 * reach);

    // Nothing inside either panel, so the glow does not show through the
    // see-through panels, and nothing where another window draws the glow.
    if (inside(p, panel) || inside(p, neighbor) || inside(p, skip)) {
        fragColor = vec4(0.0);
        return;
    }

    float value = glowAround(p, panel);
    if (neighbor.z > 0.0) {
        // The brightest a single glow gets, right at its panel's edge. It is
        // less than 1, because the glow has already started to fade there.
        // The far side of the strip is put very far away, so only the near
        // edge counts.
        float peak = strip(0.0, -spread, 1.0e6);
        value = min(value + glowAround(p, neighbor), peak);
    }
    fragColor = glowColor * value * qt_Opacity;
}
