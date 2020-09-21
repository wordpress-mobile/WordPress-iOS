#include <metal_stdlib>
using namespace metal;

struct ShaderContext {
    float time;
};

typedef struct {
    float4 renderedCoordinate [[position]];
    float2 textureCoordinate;
} TextureMappingVertex;

//
// Shaders for render pipeline
//

vertex TextureMappingVertex vertexIdentity(unsigned int vertex_id [[ vertex_id ]])
{
    float4x4 renderedCoordinates = float4x4(float4( -1.0, -1.0, 0.0, 1.0 ),
                                            float4(  1.0, -1.0, 0.0, 1.0 ),
                                            float4( -1.0,  1.0, 0.0, 1.0 ),
                                            float4(  1.0,  1.0, 0.0, 1.0 ));

    float4x2 textureCoordinates = float4x2(float2( 0.0, 1.0 ),
                                           float2( 1.0, 1.0 ),
                                           float2( 0.0, 0.0 ),
                                           float2( 1.0, 0.0 ));
    TextureMappingVertex outVertex;
    outVertex.renderedCoordinate = renderedCoordinates[vertex_id];
    outVertex.textureCoordinate = textureCoordinates[vertex_id];
    
    return outVertex;
}

fragment half4 fragmentIdentity(TextureMappingVertex mappingVertex [[ stage_in ]],
                              texture2d<float, access::sample> texture [[ texture(0) ]])
{
    constexpr sampler s(address::clamp_to_edge, filter::linear);

    float4 color = texture.sample(s, mappingVertex.textureCoordinate);
    return half4(color);
}

//
// Shaders for compute pipeline
//

// common

#define W float3(0.2125, 0.7154, 0.0721)

uint2 clampToEdge(int2 pos, float width, float height) {
    if (pos.x < 0) pos.x = 0;
    if (pos.y < 0) pos.y = 0;
    if (pos.x > width) pos.x = width - 1;
    if (pos.y > height) pos.y = height - 1;
    return uint2(pos);
}

// identity

kernel void kernelIdentity(texture2d<float, access::read> inTexture [[ texture(0) ]],
                           texture2d<float, access::write> outTexture [[ texture(1) ]],
                           uint2 gid [[ thread_position_in_grid ]])
{
    float4 outColor = inTexture.read(gid);
    outTexture.write(outColor, gid);
}

// mirror2

kernel void mirror2(texture2d<float, access::read> inTexture [[ texture(0) ]],
                    texture2d<float, access::write> outTexture [[ texture(1) ]],
                    uint2 gid [[ thread_position_in_grid ]])
{
    float4 outColor;
    uint width = inTexture.get_width();
    if (gid.x >= width / 2) {
        outColor = inTexture.read(gid);
    }
    else {
        outColor = inTexture.read(uint2(width - gid.x, gid.y));
    }
    outTexture.write(outColor, gid);
}

// mirror4

kernel void mirror4(texture2d<float, access::read> inTexture [[ texture(0) ]],
                    texture2d<float, access::write> outTexture [[ texture(1) ]],
                    uint2 gid [[ thread_position_in_grid ]])
{
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    
    float4 outColor;
    // bottom right
    if (gid.x >= width / 2 && gid.y >= height / 2) {
        outColor = inTexture.read(gid);
    }
    // bottom left
    else if (gid.x < width / 2 && gid.y >= height / 2) {
        outColor = inTexture.read(uint2(width - gid.x, gid.y));
    }
    // top right
    else if (gid.x >= width / 2 && gid.y < height / 2) {
        outColor = inTexture.read(uint2(gid.x, height - gid.y));
    }
    // top left
    else {
        outColor = inTexture.read(uint2(width - gid.x, height - gid.y));
    }
    outTexture.write(outColor, gid);
}

// wavepool

#define TAU 6.28318530718
#define MAX_ITER 5
kernel void wavepool(texture2d<float, access::read> inTexture [[ texture(0) ]],
                     texture2d<float, access::write> outTexture [[ texture(1) ]],
                     constant ShaderContext &shaderContext [[ buffer(0) ]],
                     uint2 gid [[ thread_position_in_grid ]])
{
    float time = shaderContext.time;
    float width = inTexture.get_width();
    float height = inTexture.get_height();
    float2 uv = float2(gid.x / width, gid.y / height);
    
    float2 p =  fmod(uv * TAU * 2, TAU) - 250.0;
    float2 i = float2(p);
    float c = 1.0;
    float inten = 0.005;
    
    for (int n = 0; n < MAX_ITER; n++) {
        float t = time * (1.0 - (3.5 / float(n + 1)));
        i = p + float2(cos(t - i.x) + sin(t + i.y), sin(t - i.y) + cos(t + i.x));
        c += 1.0 / length(float2(p.x / (sin(i.x + t) / inten), p.y / (cos(i.y + t) / inten)));
    }
    c /= float(MAX_ITER);
    c = 1.17 - pow(c, 1.4);
    float3 color = float3(pow(abs(c), 8.0));
    color = clamp(color + float3(0.0, 0.35, 0.5), 0.0, 1.0);
    
    float4 outColor = float4(color, 1.0);
    float stongth = 0.3;
    float waveu = sin((uv.y + time) * 20.0) * 0.5 * 0.05 * stongth;
    float4 textureColor = inTexture.read(gid + uint2(waveu * width, 0));
    
    outColor.r = (outColor.r + (textureColor.r * 1.3)) / 2.0;
    outColor.g = (outColor.g + (textureColor.g * 1.3)) / 2.0;
    outColor.b = (outColor.b + (textureColor.b * 1.3)) / 2.0;
    outColor.a = 1.0;
    
    outTexture.write(outColor, gid);
}

// grayscale

kernel void grayscale(texture2d<float, access::read> inTexture [[ texture(0) ]],
                      texture2d<float, access::write> outTexture [[ texture(1) ]],
                      uint2 gid [[ thread_position_in_grid ]])
{
    float4 inColor = inTexture.read(gid);
    float gray = dot(inColor.rgb, W);
    float4 outColor(gray, gray, gray, 1.0);
    outTexture.write(outColor, gid);
}

// light leaks

kernel void lightLeaks(texture2d<float, access::read> inTexture [[ texture(0) ]],
                       texture2d<float, access::write> outTexture [[ texture(1) ]],
                       constant ShaderContext &shaderContext [[ buffer(0) ]],
                       uint2 gid [[ thread_position_in_grid ]])
{
    float time = shaderContext.time;
    float width = inTexture.get_width();
    float height = inTexture.get_height();
    float2 p = float2(gid.x / width, gid.y / height);
    float4 cam = inTexture.read(gid);
    
    for (int i = 1; i < 6; i++) {
        float2 newp = p;
        newp.x += 0.6 / float(i) * cos(float(i) * p.y + (time * 7.0) / 10.0 + 0.3 * float(i)) + 400. / 20.0;
        newp.y += 0.6 / float(i) * cos(float(i) * p.x + (time * 5.0) / 10.0 + 0.3 * float(i + 10)) - 400. / 20.0 + 15.0;
        p = newp;
    }
    float4 col = float4(2.0 * sin(3.0 * p.x) + 0.7, 1.2 * sin(3.0 * p.y) + 0.7, 3.0 * sin(p.x + p.y)+0.4, sin(1.0));
    float alphaDivisor = cam.a + step(cam.a, 0.2);
    float4 outColor = cam * (col.a * (cam / alphaDivisor)
                            + (1.5 * col * (1.0 - (cam / alphaDivisor))))
                            + col * (1.0 - cam.a) + cam * (1.0 - col.a);
    outTexture.write(outColor, gid);
}

// lego

kernel void lego(texture2d<float, access::read> inTexture [[ texture(0) ]],
                 texture2d<float, access::write> outTexture [[ texture(1) ]],
                 uint2 gid [[ thread_position_in_grid ]])
{
    const float c = 0.03;
    float2 fragCoord = float2(gid);
    
    float2 middle = floor(fragCoord * c + 0.5) / c;
    float3 outColor = inTexture.read(uint2(middle)).rgb;
    
    float dis = distance(fragCoord, middle) * c * 2.0;
    if (dis < 0.65 && dis > 0.55) {
        outColor *= dot(float2(0.707), normalize(fragCoord - middle)) * 0.5 + 1.0;
    }
    
    float2 delta = abs(fragCoord - middle) * c * 2.0;
    float sdis = max(delta.x, delta.y);
    if (sdis > 0.9) {
        outColor *= 0.8;
    }
    outTexture.write(float4(outColor, 1.0), gid);
}

// rgb

kernel void rgb(texture2d<float, access::read> inTexture [[ texture(0) ]],
                texture2d<float, access::write> outTexture [[ texture(1) ]],
                uint2 gid [[ thread_position_in_grid ]])
{
    float width = inTexture.get_width();
    float height = inTexture.get_height();
    float2 control = float2(0.7, 0.7);
    float2 m = float2(control.xy);
    float d = (length(m) < 0.02) ? 0.015 : m.x / 10.0;
    
    int2 posR = int2(gid.x - d * width, gid.y - d * height);
    posR = int2(clampToEdge(posR, width, height));
    int2 posG = int2(gid);
    int2 posB = int2(gid.x + d * width, gid.y + d * height);
    posB = int2(clampToEdge(posB, width, height));
    
    float4 outColor = float4(inTexture.read(uint2(posR)).x,
                             inTexture.read(uint2(posG)).x,
                             inTexture.read(uint2(posB)).x,
                             1.0);
    outTexture.write(outColor, gid);
}

// toon

kernel void toon(texture2d<float, access::read> inTexture [[ texture(0) ]],
                 texture2d<float, access::write> outTexture [[ texture(1) ]],
                 uint2 gid [[ thread_position_in_grid ]])
{
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    
    float ResS = 720.;
    float ResT = 720.;
    float MagTol = .5;
    float Quantize = 10.;

    float3 irgb = inTexture.read(gid).rgb;
    float2 stp0 = float2(1. / ResS, 0.);
    float2 st0p = float2(0., 1. / ResT);
    float2 stpp = float2(1. / ResS, 1. / ResT);
    float2 stpm = float2(1. / ResS, -1. / ResT);
    
    float im1m1 = dot(inTexture.read(gid - uint2(stpp.x * width, stpp.y * height)).rgb, W);
    float ip1p1 = dot(inTexture.read(gid + uint2(stpp.x * width, stpp.y * height)).rgb, W);
    float im1p1 = dot(inTexture.read(gid - uint2(stpm.x * width, stpm.y * height)).rgb, W);
    float ip1m1 = dot(inTexture.read(gid + uint2(stpm.x * width, stpm.y * height)).rgb, W);
    float im10 = dot(inTexture.read(gid - uint2(stp0.x * width, stp0.y * height)).rgb, W);
    float ip10 = dot(inTexture.read(gid + uint2(stp0.x * width, stp0.y * height)).rgb, W);
    float i0m1 = dot(inTexture.read(gid - uint2(st0p.x * width, st0p.y * height)).rgb, W);
    float i0p1 = dot(inTexture.read(gid + uint2(st0p.x * width, st0p.y * height)).rgb, W);
    
    float h = -1. * im1p1 - 2. * i0p1 - 1. * ip1p1 + 1. * im1m1 + 2. * i0m1 + 1. * ip1m1;
    float v = -1. * im1m1 - 2. * im10 - 1. * im1p1 + 1. * ip1m1 + 2. * ip10 + 1. * ip1p1;
    float mag = length(float2(h, v));
    
    float4 outColor;
    if (mag > MagTol) {
        outColor = float4(0, 0, 0, 1);
    }
    else {
        irgb *= Quantize;
        irgb += float3(0.5, 0.5, 0.5);
        int3 intrgb = int3(irgb);
        irgb = float3(intrgb) / Quantize;
        outColor = float4(irgb, 1);
    }
    outTexture.write(outColor, gid);
}

// manga

float3 StripsPattern(float2 position) {
    float2 p = (position - 0.5) * 500;

    float angle = 0.7;
    float2 direction = float2(cos(angle), sin(angle));

    float contrast = cos(dot(p, direction));
    float3 color = float3(1.0 - contrast);
    
    float gray = dot(color, W);
    if (gray > 0.5) {
        return float3(220.0 / 255.0, 220.0 / 255.0, 220.0 / 255.0);
    }
    else {
        return float3(120.0 / 255.0, 120.0 / 255.0, 120.0 / 255.0);
    }
}

kernel void manga(texture2d<float, access::read> inTexture [[ texture(0) ]],
                  texture2d<float, access::write> outTexture [[ texture(1) ]],
                  uint2 gid [[ thread_position_in_grid ]])
{
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    
    uint dx = 1.0/720.0 * width;
    uint dy = 1.0/720.0 * height;
    
    float3 sample0 = inTexture.read(uint2(gid.x - dx, gid.y + dy)).rgb;
    float3 sample1 = inTexture.read(uint2(gid.x - dx, gid.y)).rgb;
    float3 sample2 = inTexture.read(uint2(gid.x - dx, gid.y - dy)).rgb;
    float3 sample3 = inTexture.read(uint2(gid.x, gid.y + dy)).rgb;
    float3 sample4 = inTexture.read(uint2(gid.x, gid.y)).rgb;
    float3 sample5 = inTexture.read(uint2(gid.x, gid.y - dy)).rgb;
    float3 sample6 = inTexture.read(uint2(gid.x + dx, gid.y + dy)).rgb;
    float3 sample7 = inTexture.read(uint2(gid.x + dx, gid.y)).rgb;
    float3 sample8 = inTexture.read(uint2(gid.x + dx, gid.y - dy)).rgb;
    
    float3 horizEdge = sample2 + sample5 + sample8 - (sample0 + sample3 + sample6);
    float3 vertEdge = sample0 + sample1 + sample2 - (sample6 + sample7 + sample8);
    
    float3 border;
    border = sqrt((horizEdge * horizEdge) + (vertEdge * vertEdge));

    float gray = dot(sample4, W);
    
    float3 outColor;
    if (border.r > 0.5 || border.g > 0.5 || border.b > 0.5) {
        outColor = float3(0);
    }
    else {
        if (gray < 0.25) {
            outColor = float3(20.0/255.0, 20.0/255.0, 20.0/255.0);
        }
        else if (gray >= 0.25 && gray < 0.4) {
            outColor = StripsPattern(float2(float(gid.x) / float(width), float(gid.y) / float(height)));
        }
        else {
            outColor = float3(1.0);
        }
    }
    
    outTexture.write(float4(outColor, 1.0), gid);
}

// film

float hash(float n) {
    return fract(sin(n) * 43758.5453123);
}

kernel void film(texture2d<float, access::read> inTexture [[ texture(0) ]],
                 texture2d<float, access::write> outTexture [[ texture(1) ]],
                 constant ShaderContext &shaderContext [[ buffer(0) ]],
                 uint2 gid [[ thread_position_in_grid ]])
{
    float time = shaderContext.time;
    float height = inTexture.get_height();
    float2 res = float2(1.0, 1.0);
    float2 p = float2(gid) / res;
    
    float2 u = p * 2.0 - 1.0;
    float2 n = u * float2(res.x / res.y, 1.0);
    float3 c = inTexture.read(uint2(p)).xyz;
    
    float4 outColor;
    if (fmod(gid.y / height * 0.5, 1.0) > 1.0) {
        outColor = float4(float3(0), 1);
    }
    else {
        c += hash((hash(n.x) + n.y) * time) * 0.3;
        outColor = float4(c, 1.0);
    }
    outTexture.write(outColor, gid);
}

// plasma

float3 rainbow(float h) {
    h = fmod(fmod(h, 1.0) + 1.0, 1.0);
    float h6 = h * 6.0;
    float r = clamp(h6 - 4.0, 0.0, 1.0) + clamp(2.0 - h6, 0.0, 1.0);
    float g = h6 < 2.0 ? clamp(h6, 0.0, 1.0) : clamp(4.0 - h6, 0.0, 1.0);
    float b = h6 < 4.0 ? clamp(h6 - 2.0, 0.0, 1.0) : clamp(6.0 - h6, 0.0, 1.0);
    return float3(r, g, b);
}

float3 plasma(texture2d<float, access::read> inTexture, float2 textureCoordinate, float time, float width, float height) {
    const float speed = 12.0;
    const float scale = 2.5;

    const float startA = 563.0 / 512.0;
    const float startB = 233.0 / 512.0;
    const float startC = 4325.0 / 512.0;
    const float startD = 312556.0 / 512.0;

    const float advanceA = 6.34 / 512.0 * 18.2 * speed;
    const float advanceB = 4.98 / 512.0 * 18.2 * speed;
    const float advanceC = 4.46 / 512.0 * 18.2 * speed;
    const float advanceD = 5.72 / 512.0 * 18.2 * speed;

    float2 uv = textureCoordinate * scale;

    float a = startA + time * advanceA;
    float b = startB + time * advanceB;
    float c = startC + time * advanceC;
    float d = startD + time * advanceD;

    float n = sin(a + 3.0 * uv.x) + sin(b - 4.0 * uv.x) + sin(c + 2.0 * uv.y) + sin(d + 5.0 * uv.y);

    n = fmod(((4.0 + n) / 4.0), 1.0);

    uv = textureCoordinate.xy;
    n += inTexture.read(uint2(uv.x * width, uv.y * height)).r;

    return rainbow(n);
}

kernel void plasma(texture2d<float, access::read> inTexture [[ texture(0) ]],
                   texture2d<float, access::write> outTexture [[ texture(1) ]],
                   constant ShaderContext &shaderContext [[ buffer(0) ]],
                   uint2 gid [[ thread_position_in_grid ]])
{
    float time = shaderContext.time;
    float width = inTexture.get_width();
    float height = inTexture.get_height();
    
    float3 green = float3(0.173, 0.5, 0.106);
    float2 uv = float2(gid.x / width, gid.y / height);
    float3 inColor = inTexture.read(gid).rgb;
    float greenness = 1.0 - (length(inColor - green) / length(float3(1, 1, 1)));
    float imageAlpha = clamp((greenness - 0.7) / 0.2, 0.0, 1.0);
    
    float4 outColor = float4(inColor * (1.0 - imageAlpha), 1.0) +
                    float4(plasma(inTexture, uv, time, width, height) * imageAlpha, 1.0);
    outTexture.write(outColor, gid);
}

// rave

kernel void rave(texture2d<float, access::read> inTexture [[ texture(0) ]],
                 texture2d<float, access::write> outTexture [[ texture(1) ]],
                 constant ShaderContext &shaderContext [[ buffer(0) ]],
                 uint2 gid [[ thread_position_in_grid ]])
{
    float time = shaderContext.time;
    float4 outColor = inTexture.read(gid);
    outColor.r *= abs(sin(time * 1.0));
    outColor.g *= abs(sin(time * 5.0 + 4.0));
    outColor.b *= abs(sin(time * 3.0 + 2.0));
    outColor.a = 1.0;
    outTexture.write(outColor, gid);
}

// chroma

kernel void chroma(texture2d<float, access::read> inTexture [[ texture(0) ]],
                   texture2d<float, access::write> outTexture [[ texture(1) ]],
                   constant ShaderContext &shaderContext [[ buffer(0) ]],
                   uint2 gid [[ thread_position_in_grid ]])
{
    float width = inTexture.get_width();
    float height = inTexture.get_height();
    float time = shaderContext.time;

    float go = sin(time) * 0.01;
    float go2 = sin(time) * 0.01;
    float2 strength = float2(2.5, 1.0); // tweaked value from the OpenGL shader
    
    float4 outColor;
    outColor.r = inTexture.read(clampToEdge(int2(gid - uint2(float2(go * width, 0) * strength)), width, height)).r;
    outColor.g = inTexture.read(clampToEdge(int2(gid - uint2(float2(0.005 * width, go2 * height) * strength)), width, height)).g;
    outColor.b = inTexture.read(gid).g;
    outColor.a = 1.0;
    outTexture.write(outColor, gid);
}

// em_interference

float rng2(float time, float2 seed) {
    return fract(sin(dot(seed * floor(time * 12.), float2(127.1, 311.7))) * 43758.5453123);
}

float rng(float time, float seed) {
    return rng2(time, float2(seed, 1.0));
}

kernel void em_interference(texture2d<float, access::read> inTexture [[ texture(0) ]],
                            texture2d<float, access::write> outTexture [[ texture(1) ]],
                            constant ShaderContext &shaderContext [[ buffer(0) ]],
                            uint2 gid [[ thread_position_in_grid ]])
{
    float time = shaderContext.time;
    float width = inTexture.get_width();
    float height = inTexture.get_height();
    
    float2 uv = float2(gid.x/width, gid.y/height);
    float2 blockS = floor(uv * float2(24.0, 9.0));
    float2 blockL = floor(uv * float2(8.0, 4.0));
    
    float r = rng2(time, uv);
    float3 noise = (float3(r, 1.0 - r, r / 2.0 + 0.5) * 1.0 - 2.0) * 0.08;
    
    float lineNoise = pow(rng2(time, blockS), 8.0) * pow(rng2(time, blockL), 3.0) - pow(rng(time, 7.2341), 17.0) * 2.0;
    
    float2 pos1 = uv;
    float2 pos2 = uv + float2(lineNoise * 0.05 * rng(time, 5.0), 0);
    float2 pos3 = uv - float2(lineNoise * 0.05 * rng(time, 31.0), 0);
    float4 col1 = inTexture.read(clampToEdge(int2(pos1.x * width, pos1.y * height), width, height));
    float4 col2 = inTexture.read(clampToEdge(int2(pos2.x * width, pos2.y * height), width, height));
    float4 col3 = inTexture.read(clampToEdge(int2(pos3.x * width, pos3.y * height), width, height));
    
    float4 outColor = float4(float3(col1.x, col2.y, col3.z) + noise, 1.0);
    outTexture.write(outColor, gid);
}

kernel void alpha_blend(texture2d<float, access::read> inTexture [[ texture(0) ]],
                        texture2d<float, access::write> outTexture [[ texture(1) ]],
                        texture2d<float, access::read> overlayTexture [[ texture(2) ]],
                        constant ShaderContext &shaderContext [[ buffer(0) ]],
                        uint2 gid [[ thread_position_in_grid ]])
{
    float4 inColor = inTexture.read(gid);
    float4 overlay = overlayTexture.read(gid);
    float4 outColor = float4(mix(inColor.rgb, overlay.rgb, overlay.a), inColor.a);
    outTexture.write(outColor, gid);
}
