#version 440

// Kin suong cho panel man khoa: lay video nen lam mau, blur ngay trong panel,
// bo goc tron, cong trong suot ben ngoai.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 itemSize;
    vec4 panelRect;     // x, y, w, h trong pixel man hinh
    vec4 radii;         // 4 bo goc
    float blurRadius;   // px
    float tintAlpha;    // 0 = khong tint, 1 = nhieu
};

layout(binding = 1) uniform sampler2D src;

void main() {
    vec2 px = qt_TexCoord0 * itemSize;
    vec2 center = panelRect.xy + panelRect.zw * 0.5;
    vec2 p = px - center;
    vec2 h = panelRect.zw * 0.5;

    float r = p.x < 0.0 ? (p.y < 0.0 ? radii.x : radii.w) : (p.y < 0.0 ? radii.y : radii.z);
    r = min(r, min(h.x, h.y));
    vec2 q = abs(p) - h + r;
    float d = min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
    float cover = clamp(0.5 - d, 0.0, 1.0);
    if (cover <= 0.001) {
        fragColor = vec4(0.0);
        return;
    }

    vec2 texel = 1.0 / max(itemSize, vec2(1.0));
    float step_ = max(1.0, blurRadius) / 2.0;

    vec3 sum = vec3(0.0);
    float wsum = 0.0;
    for (int i = -2; i <= 2; ++i) {
        for (int j = -2; j <= 2; ++j) {
            float w = exp(-float(i * i + j * j) / 4.0);
            sum += texture(src, qt_TexCoord0 + vec2(float(i), float(j)) * texel * step_).rgb * w;
            wsum += w;
        }
    }
    vec3 col = sum / max(wsum, 0.0001);

    fragColor = vec4(col, cover * qt_Opacity);
}
