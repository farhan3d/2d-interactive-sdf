// Comment below three lines and replace with iResolution, iTime, and iMouse
// in entire code if testing this on Shadertoy. Also search for "shadertoy"
// mentions in the code below and change as instructed to view on shadertoy.

#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;
#define OBJ_TYPES_COUNT 20
#define CIRC_RAD 0.1
#define CIRC_OFF_X 0.1
#define CIRC_OFF_Y 0.1
#define SQ_SIZE 0.08
#define SQ_OFF_X 0.0
#define SQ_OFF_Y 0.0
#define ROT_SPEED_MULT 0.5
#define MAX_OBJ_COUNT 10
#define BLOOM_FACTOR 1.0
#define BLEND_RADIUS 0.015
#define LINE_THK 0.0025
#define DRAW_WIREFRAME true
#define ROT_HEX true
#define DRAW_FIELDS true
#define FUNKY_BLOOM false
#define SHOW_BOUNDINGBOX true
#define TOGGLE_PERSISTANT_SELECTION false

vec2 obj_centers[MAX_OBJ_COUNT];

// storing the +X, -X, +Y, -Y max points of all objects
// to compute their respective bounding boxes.
vec4 obj_limits[MAX_OBJ_COUNT];

vec2 obj_type_map[MAX_OBJ_COUNT];

float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

float opSmoothSubtraction(float d1, float d2, float k) {
    float h = clamp(0.5 - 0.5 * (d2 + d1) / k, 0.0, 1.0 );
    return mix(d2, -d1, h) + k * h * (1.0 - h);
}

vec2 rotate(vec2 uv, float th) {
    return mat2(cos(th), sin(th), -sin(th), cos(th)) * uv;
}

vec2 rotationByCenter(in float angle,in vec2 position,in vec2 center) {
    //Function seen from https://www.shadertoy.com/view/XlsGWf
    float rot = radians(angle);
    mat2 rotation = mat2(cos(rot), -sin(rot), sin(rot), cos(rot));
    return vec2((position-center)*rotation);
}

float sdHexagon(vec2 p, float s, float r, vec2 offset) {
    vec2 rotated = p;
    if (ROT_HEX) {
        rotated = rotate(vec2(p.x, p.y), u_time * ROT_SPEED_MULT);
    }
    const vec3 k = vec3(-0.866025404, 0.5, 0.577350269);
    p = vec2(rotated.x - offset.x, rotated.y - offset.y);
    p = abs(p);
    p -= 2.0 * min(dot(k.xy, p), 0.0) * k.xy;
    p -= vec2(clamp(p.x, -k.z * s, k.z * s), s);
    return length(p) * sign(p.y) - r;
}

float sdSquare(vec2 uv, float radius, vec2 offset) {
    float x = uv.x - offset.x;
    float y = uv.y - offset.y;
    return max(abs(x), abs(y)) - radius;
}

float sdSphere(vec2 uv, vec2 offset, float radius) {
    float x = uv.x - offset.x;
    float y = uv.y - offset.y;
    return length(vec2(x, y)) - radius;
}

// create tight-fit bounding boxes around objects
vec3 drawBoundingBoxes(vec3 in_vec,
                       float[MAX_OBJ_COUNT] d,
                       vec2 obj_cen[MAX_OBJ_COUNT]) {
    vec3 ret_vec = in_vec;
    for (int i = 0; i < MAX_OBJ_COUNT; i++) {

    }
    return ret_vec;
}

vec3 drawOutlineForObjects(vec3 in_vec, float[MAX_OBJ_COUNT] d) {
    vec3 ret_vec = in_vec;
    for (int i = 0; i < MAX_OBJ_COUNT; i++) {
        if (d[i] == 0.0) {
            break;
        } else {
            vec3 line_color = vec3(0.1, 0.2, 0.2);
            ret_vec = mix(ret_vec, line_color, 1.0 -
                smoothstep(0.0, 0.00175, abs(d[i])));
        }
    }
    return ret_vec;
}

float drawLShape(vec2 uv, vec2 base_loc) {
    float res = sdSphere(uv, vec2(base_loc.x, base_loc.y), CIRC_RAD * 0.75);
    //res = smin(in_val, temp, BLEND_RADIUS);
    float temp = sdSquare(uv, CIRC_RAD * 0.75, vec2(base_loc.x, base_loc.y - 0.075));
    res = smin(res, temp, 0.0);
    temp = sdSphere(uv, vec2(base_loc.x, base_loc.y), CIRC_RAD * 0.4);
    res = opSmoothSubtraction(temp, res, 0.001);
    temp = sdSquare(uv, CIRC_RAD * 0.75, vec2(base_loc.x, base_loc.y - 0.22));
    res = smin(res, temp, 0.0);
    temp = sdSquare(uv, CIRC_RAD * 0.75, vec2(base_loc.x + 0.14, base_loc.y - 0.22));
    res = smin(res, temp, 0.0);
    temp = sdSphere(uv, vec2(base_loc.x + 0.22, base_loc.y - 0.22), CIRC_RAD * 0.75);
    res = smin(res, temp, 0.0);
    temp = sdSphere(uv, vec2(base_loc.x + 0.22, base_loc.y - 0.22), CIRC_RAD * 0.4);
    res = opSmoothSubtraction(temp, res, 0.001);
    vec2 rotated = rotationByCenter(45.0, uv, base_loc);
    temp = sdSquare(rotated, CIRC_RAD * 0.75, vec2(0.155, -0.28));
    res = opSmoothSubtraction(temp, res, 0.001);
    return res;
}

vec3 drawHoverHighlight(vec2 uv, vec2 obj_cen[MAX_OBJ_COUNT],
                        float[MAX_OBJ_COUNT] d,
                        int[OBJ_TYPES_COUNT] object_class) {
    vec3 ret_vec;

    // below commented code for shadertoy
    //vec4 m = vec4 (u_mouse.x / u_resolution.y - 1.0,
    //    u_mouse.y / u_resolution.y - 0.75,
    //    u_mouse.z, u_mouse.w);
    vec2 m = vec2(u_mouse.x, u_mouse.y);
    // below line for shadertoy
    //vec2 mouse_loc_adj = vec2(m.x + 0.1125, m.y + 0.25);
    vec2 mouse_loc_adj = vec2(m.x - 0.5, m.y - 0.5);

    // while mouse button is pressed in shadertoy, highlight object clicked
    // below if check only for shadertoy
    if (m.x > 0.0) {
        for (int i = 0; i < MAX_OBJ_COUNT; i++) {
            if (object_class[i] == 0) {
                float test_val = sdSphere(mouse_loc_adj, obj_cen[i], CIRC_RAD);
                if (test_val < 0.0) {
                    vec3 hover_fill_col = vec3(0.2, 0.25, 0.25);
                    if (d[i] < 0.0) {
                        ret_vec = hover_fill_col;
                    }
                }
            } else if (object_class[i] == 2) {
                float hex1 = sdHexagon(mouse_loc_adj, SQ_SIZE * 1.15, SQ_SIZE * 0.35,
                    obj_centers[i]);
                float hex2 = sdHexagon(mouse_loc_adj, SQ_SIZE * 0.65, SQ_SIZE * 0.45,
                    obj_centers[i]);
                float test_val = opSmoothSubtraction(hex2, hex1, 0.001);
                if (test_val < 0.0) {
                    vec3 hover_fill_col = vec3(0.2, 0.25, 0.25);
                    if (d[i] < 0.0) {
                        ret_vec = hover_fill_col;
                    }
                }
            } else if (object_class[i] == 3) {
                float test_val = sdSquare(mouse_loc_adj, SQ_SIZE * 1.25,
                    vec2(obj_centers[i].x, obj_centers[i].y));
                if (test_val < 0.0) {
                    vec3 hover_fill_col = vec3(0.2, 0.25, 0.25);
                    if (d[i] < 0.0) {
                        ret_vec = hover_fill_col;
                    }
                }
            } else if (object_class[i] == 4) {
                float test_val = drawLShape(mouse_loc_adj,
                    obj_centers[i]);
                if (test_val < 0.0) {
                    vec3 hover_fill_col = vec3(0.2, 0.25, 0.25);
                    if (d[i] < 0.0) {
                        ret_vec = hover_fill_col;
                    }
                }
            }
        }
    }
    return ret_vec;
}

vec3 drawScene(vec2 uv) {
    vec3 ret_vec;
    float res;
    ret_vec = vec3(0.15, 0.5, 0.8);
    float d[MAX_OBJ_COUNT];
    int obj_class[OBJ_TYPES_COUNT];

    // creating objects
    d[0] = sdSphere(uv, vec2(CIRC_OFF_X, CIRC_OFF_Y), CIRC_RAD);
    obj_centers[0] = vec2(CIRC_OFF_X, CIRC_OFF_Y);
    obj_class[0] = 0;
    d[1] = sdHexagon(uv, SQ_SIZE * 1.15, SQ_SIZE * 0.35, vec2(SQ_OFF_X, SQ_OFF_Y));
    obj_centers[1] = vec2(SQ_OFF_X, SQ_OFF_Y);
    obj_class[1] = 1;
    d[2] = sdHexagon(uv, SQ_SIZE * 0.65, SQ_SIZE * 0.45, vec2(SQ_OFF_X, SQ_OFF_Y));
    obj_centers[2] = vec2(SQ_OFF_X, SQ_OFF_Y);
    obj_class[2] = 1;
    d[3] = opSmoothSubtraction(d[2], d[1], 0.001);
    obj_centers[3] = vec2(SQ_OFF_X, SQ_OFF_Y);
    obj_class[3] = 2;
    d[4] = sdSquare(uv, SQ_SIZE * 1.25, vec2(SQ_OFF_X - 0.15, SQ_OFF_Y - 0.125));
    obj_centers[4] = vec2(SQ_OFF_X - 0.15, SQ_OFF_Y - 0.125);
    obj_class[4] = 3;
    float full_un = smin(d[4], d[3], BLEND_RADIUS);
    full_un = smin(full_un, d[0], BLEND_RADIUS);
    d[5] = sdSquare(uv, SQ_SIZE * 1.25, vec2(SQ_OFF_X - 0.275, SQ_OFF_Y));
    obj_centers[5] = vec2(SQ_OFF_X - 0.275, SQ_OFF_Y);
    obj_class[5] = 3;
    full_un = opSmoothSubtraction(d[5], full_un, 0.001);

    // create test L bracket thingy
    //obj_centers[6] = vec2(0.3, 0.0);
    //d[6] = drawLShape(uv, obj_centers[6]);
    //full_un = smin(full_un, d[6], BLEND_RADIUS);
    //obj_class[6] = 4;

    ret_vec += drawHoverHighlight(uv, obj_centers, d, obj_class);

    // create the global objects field around them
    res = full_un;
    if (DRAW_FIELDS) {
        ret_vec *= 1.5 - exp(-15.0 * abs(res));
        ret_vec *= 0.75 + 0.1 * cos(300.0 * res);
    }

    // create the consumed part of drawn objects
    if ((DRAW_WIREFRAME) && (true)) {
        ret_vec = drawOutlineForObjects(ret_vec, d);
    }

    // draw object boundaries
    ret_vec = mix(ret_vec, vec3(0.65), 1.0 - smoothstep(0.0, LINE_THK, abs(res)));

    // color inside the combined objects
    vec3 obj_fill_col = vec3(ret_vec.x + 0.1, ret_vec.y + 0.25, ret_vec.z + 0.25);
    if (FUNKY_BLOOM) {
        res = smoothstep(0.0, 0.0025 * BLOOM_FACTOR * sin(u_time), res * 0.005);
    } else {
        res = smoothstep(0.0, 0.005 * BLOOM_FACTOR , res);
    }
    ret_vec = mix(obj_fill_col, ret_vec, res);

    return ret_vec;
}

// below main block for shadertoy
/*
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;
    uv -= 0.5;
    float aspect = iResolution.x / iResolution.y;
    uv.x *= aspect;
    vec3 color = drawScene(uv);

    fragColor = vec4(color, 1.0);
}
*/

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    uv -= 0.5;
    float aspect = u_resolution.x / u_resolution.y;
    uv.x *= aspect;
    vec3 color = drawScene(uv);

    gl_FragColor = vec4(color, 1.0);
}
