shader_type spatial;
render_mode diffuse_burley;
uniform sampler2D armor_atlas : source_color, filter_linear_mipmap;
uniform sampler2D armor_normal : hint_normal, filter_linear_mipmap;
uniform sampler2D armor_orm : filter_linear_mipmap;
void fragment() {
    vec3 c = texture(armor_atlas, UV).rgb;
    float v = max(c.r, max(c.g, c.b));
    float low = min(c.r, min(c.g, c.b));
    float cloth = smoothstep(1.2, 1.7, c.r / max(0.012, c.g)) * (1.0 - smoothstep(0.16, 0.35, c.g));
    float steel = (1.0 - smoothstep(0.10, 0.26, v-low)) * (1.0 - cloth);
    vec3 blue_cloth = vec3(0.06, 0.23, 0.53) * (0.6 + v);
    vec3 blue_steel = vec3(0.18, 0.35, 0.57) * (0.55 + v);
    ALBEDO = mix(mix(c, blue_steel, steel * 0.72), blue_cloth, cloth);
    vec3 orm = texture(armor_orm, UV).rgb;
    METALLIC = min(orm.b, 0.55);
    ROUGHNESS = max(orm.g, 0.48);
    NORMAL_MAP = texture(armor_normal, UV).rgb;
}
