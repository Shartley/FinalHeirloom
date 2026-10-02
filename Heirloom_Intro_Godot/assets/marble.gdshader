shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform vec4 tint : source_color = vec4(0.68, 0.67, 0.62, 1.0);
void fragment() {
    float wave = sin(UV.x * 38.0 + sin(UV.y * 12.0) * 2.5 + UV.y * 8.0);
    float veins = 1.0 - smoothstep(0.02, 0.08, abs(wave));
    ALBEDO = tint.rgb * (1.0 - veins * 0.065);
    ROUGHNESS = 0.47;
    SPECULAR = 0.30;
}
