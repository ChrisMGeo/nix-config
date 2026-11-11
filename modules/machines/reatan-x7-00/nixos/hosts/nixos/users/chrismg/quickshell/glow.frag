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

void main() {
    // This pixel in pixels, measured from the panel's top left corner.
    vec2 p = qt_TexCoord0 * vec2(width, height) - vec2(reach);
    vec2 panelSize = vec2(width, height) - vec2(2.0 * reach);

    // Nothing inside the panel itself, so the glow does not show through the
    // see-through panel.
    if (p.x >= 0.0 && p.y >= 0.0 && p.x <= panelSize.x && p.y <= panelSize.y) {
        fragColor = vec4(0.0);
        return;
    }

    // A blurred rectangle is the product of a blurred strip on each axis.
    // This gives straight lines of equal brightness near the corners, which
    // keeps them square.
    float value = strip(p.x, -spread, panelSize.x + spread)
        * strip(p.y, -spread, panelSize.y + spread);
    fragColor = glowColor * value * qt_Opacity;
}
