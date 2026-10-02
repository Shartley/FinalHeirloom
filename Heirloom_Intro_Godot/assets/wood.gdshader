shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform vec4 tint : source_color = vec4(0.24, 0.13, 0.075, 1.0);
void fragment() {
    vec2 p = UV * vec2(5.0, 45.0);
    float grain = sin(p.y + sin(p.x * 2.8) * 1.2 + sin(p.x * 0.8) * 2.0);
    float fine = sin(p.y * 5.0 + p.x * 0.9);
    ALBEDO = tint.rgb * (0.95 + grain * 0.075 + fine * 0.020);
    ROUGHNESS = 0.51;
    SPECULAR = 0.35;
}
