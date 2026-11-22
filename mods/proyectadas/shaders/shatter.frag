#pragma header

uniform float fall_progress = 0.0;
uniform int pieces_x = 9;
uniform int pieces_y = 6;

// EXPLOSION CONTROLS
uniform float gravity = 2.8;
uniform float scatter = 1.8;
uniform float rotation_amount = 12.0;

uniform float point_jitter = 1.0;
uniform float delay_variation = 0.08;

// SHATTER / GLASS CONTROLS
uniform float edge_thickness = 0.0;
uniform float edge_brightness = 1.2;
uniform float alpha_fade = 0.5;

// NEW EXPLOSION CONTROLS
uniform float explosion_force = 1.15;
uniform float chaos = 0.65;
uniform float spin_speed = 16.0;
uniform float upward_force = 0.8;
uniform vec2 explosion_origin = vec2(0.5, 0.5);

const int SEARCH_RADIUS = 1;

float hash12(vec2 p)
{
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec2 hash22(vec2 p)
{
    return vec2(
        hash12(p + vec2(1.23, 4.56)),
        hash12(p + vec2(7.89, 0.12))
    );
}

mat2 rot(float a)
{
    float s = sin(a);
    float c = cos(a);
    return mat2(c, -s, s, c);
}

vec2 cell_point(vec2 cell_id)
{
    vec2 h = hash22(cell_id);

    return cell_id + 0.5
        + (h - 0.5) * (point_jitter * 2.0);
}

void voronoi_info(
    vec2 p,
    out vec2 owner_cell,
    out vec2 owner_point,
    out float edge_dist
)
{
    vec2 base = floor(p);

    float best_d = 1.0e20;
    float second_d = 1.0e20;

    vec2 best_cell = vec2(0.0);
    vec2 best_point = vec2(0.0);

    for (int j = -SEARCH_RADIUS; j <= SEARCH_RADIUS; j++)
    {
        for (int i = -SEARCH_RADIUS; i <= SEARCH_RADIUS; i++)
        {
            vec2 c = base + vec2(float(i), float(j));
            vec2 pt = cell_point(c);

            float d = distance(p, pt);

            if (d < best_d)
            {
                second_d = best_d;
                best_d = d;
                best_cell = c;
                best_point = pt;
            }
            else if (d < second_d)
            {
                second_d = d;
            }
        }
    }

    owner_cell = best_cell;
    owner_point = best_point;
    edge_dist = second_d - best_d;
}

void piece_transform(
    vec2 piece_cell,
    vec2 piece_point,
    vec2 grid,
    out float t,
    out vec2 piece_offset_uv,
    out float piece_angle
)
{
    float rnd  = hash12(piece_cell);
    float rnd2 = hash12(piece_cell + 17.37);
    float rnd3 = hash12(piece_cell + 91.11);
    float rnd4 = hash12(piece_cell + 43.71);

    // Randomized detonation timing.
    float delay = rnd * delay_variation;

    t = clamp(
        (fall_progress - delay) / max(0.0001, 1.0 - delay),
        0.0,
        1.0
    );

    // Smooth, aggressive launch.
    float launch = t * (2.0 - t);

    // Each shard explodes away from the impact point.
    vec2 shard_uv = piece_point / grid;

    vec2 radial = shard_uv - explosion_origin;

    // Prevent the center shard from producing an invalid direction.
    radial += (hash22(piece_cell + 8.17) - 0.5) * 0.08;

    radial = normalize(radial);

    // Individual shards receive additional random impulses.
    vec2 random_kick = (hash22(piece_cell + 31.73) - 0.5) * 2.0;

    float force = explosion_force * (0.65 + rnd2 * 1.15);

    vec2 blast = radial * force * launch;

    // Violent sideways recoil and unpredictable movement.
    float sideways = random_kick.x * scatter;
    float extra_vertical = random_kick.y * scatter * 0.55;

    vec2 chaotic_motion = vec2(
        sideways * launch,
        extra_vertical * launch
    );

    // Gravity takes over after the initial blast.
    float fall = gravity * t * t * (0.7 + rnd3 * 0.9);

    // Upward blast impulse: negative Y is upward.
    float lift = upward_force * (0.5 + rnd4) * launch;

    // Randomized drift keeps the shards from following identical arcs.
    float turbulence_x =
        sin(t * (5.0 + rnd3 * 12.0) + rnd * 30.0)
        * chaos * t * t;

    float turbulence_y =
        cos(t * (4.0 + rnd2 * 10.0) + rnd3 * 25.0)
        * chaos * 0.4 * t * t;

    piece_offset_uv = blast + chaotic_motion;

    piece_offset_uv.x += turbulence_x;
    piece_offset_uv.y += turbulence_y;
    piece_offset_uv.y += fall - lift;

    // Independent, high-speed tumbling.
    float spin_direction = mix(-1.0, 1.0, step(0.5, rnd2));

    float spin = spin_direction
        * spin_speed
        * (0.35 + rnd3 * 1.65)
        * t;

    float initial_twist = (rnd - 0.5) * rotation_amount;

    piece_angle = initial_twist * launch + spin;
}

void main()
{
    vec2 uv = openfl_TextureCoordv;
    vec2 grid = vec2(float(pieces_x), float(pieces_y));

    vec2 p_now = uv * grid;

    vec2 now_cell;
    vec2 now_point;
    float now_edge;

    voronoi_info(
        p_now,
        now_cell,
        now_point,
        now_edge
    );

    float t;
    vec2 piece_offset_uv;
    float piece_angle;

    piece_transform(
        now_cell,
        now_point,
        grid,
        t,
        piece_offset_uv,
        piece_angle
    );

    vec2 piece_center_uv = now_point / grid;

    vec2 rel_now = uv - piece_center_uv;

    // Reverse the shard's rotation and translation to sample
    // its original position in the sprite.
    vec2 uv_from = piece_center_uv
        + rot(-piece_angle) * (rel_now - piece_offset_uv);

    float inside_image =
        step(0.0, uv_from.x) *
        step(0.0, uv_from.y) *
        step(uv_from.x, 1.0) *
        step(uv_from.y, 1.0);

    vec2 safe_uv = clamp(uv_from, vec2(0.0), vec2(1.0));

    vec2 p_from = safe_uv * grid;

    vec2 from_cell;
    vec2 from_point;
    float from_edge;

    voronoi_info(
        p_from,
        from_cell,
        from_point,
        from_edge
    );

    float same_piece =
        1.0 - step(0.001, distance(from_cell, now_cell));

    vec4 col = flixel_texture2D(bitmap, safe_uv);

    // Bright, sharp glass edges.
    float edge = 1.0 - smoothstep(
        0.0,
        max(edge_thickness, 0.001),
        now_edge
    );

    // Add a subtle white glint to the shards.
    col.rgb += edge * edge_brightness;

    // A slight fade removes distant debris toward the end.
    col.a *= inside_image;
    col.a *= same_piece;
    col.a *= mix(1.0, 1.0 - alpha_fade, t);

    gl_FragColor = col;
}