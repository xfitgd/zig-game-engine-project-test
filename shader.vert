#version 450
#extension GL_EXT_debug_printf : enable
layout(location = 0) in vec4 inPosition;
layout(location = 0) out vec3 fragColor;



vec4 positions[3] = vec4[](
    vec4(0.0, -0.5,0,1),
    vec4(0.5, 0.5,0,1),
    vec4(-0.5, 0.5,0,1)
);


vec3 colors[3] = vec3[](
    vec3(1.0, 0.0, 0.0),
    vec3(0.0, 1.0, 0.0),
    vec3(0.0, 0.0, 1.0)
);

void main() {
    gl_Position =inPosition;
    //debugPrintfEXT("pos %f %f %f %f", inPosition.x,inPosition.y,inPosition.z,inPosition.w);
    fragColor = colors[0];
}