/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
#version 330
in vec2 texUVs;
out vec4 outColor;

uniform sampler2D tex;
uniform float opacity;
uniform vec3 tint;

void main() {
    outColor = texture(tex, texUVs) * vec4(tint.xyz, 1) * opacity;
}