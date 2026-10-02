shader_type spatial;
render_mode diffuse_burley;
uniform vec4 paper : source_color = vec4(0.62, 0.55, 0.43, 1.0);
uniform vec4 ink : source_color = vec4(0.31, 0.24, 0.19, 1.0);
uniform vec2 repeats = vec2(18.0, 5.0);
void fragment() {
    vec2 cell = UV * repeats;
    cell.x += mod(floor(cell.y), 2.0) * 0.5;
    vec2 p = fract(cell) - 0.5;
    float leaf = exp(-length(p * vec2(8.0, 3.0)) * 3.0);
    float petals = exp(-length((abs(p) - vec2(0.12, 0.13)) * vec2(9.0, 6.0)) * 3.0);
    float border = 1.0 - smoothstep(0.012, 0.035, abs(abs(p.x) + abs(p.y) - 0.40));
    float motif = clamp(leaf * 2.0 + petals * 1.4 + border * 0.35, 0.0, 1.0);
    ALBEDO = mix(paper.rgb, ink.rgb, motif * 0.60);
    ROUGHNESS = 0.90;
}
