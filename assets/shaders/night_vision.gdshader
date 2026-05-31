shader_type canvas_item;

// 夜视光圈：圈内透明（可见），圈外平滑压暗。
// light_center 为屏幕 UV（已按宽高比预校正传入）；半径以校正后的 UV 距离为单位。

uniform vec2 light_center = vec2(0.43, 0.5);
uniform float inner_radius = 0.18;
uniform float outer_radius = 0.42;
uniform float darkness = 0.0;
uniform float aspect = 1.7777778;

void fragment() {
	vec2 p = vec2(UV.x * aspect, UV.y);
	vec2 c = vec2(light_center.x * aspect, light_center.y);
	float d = distance(p, c);
	float v = smoothstep(inner_radius, outer_radius, d);
	COLOR = vec4(0.0, 0.0, 0.0, darkness * v);
}
