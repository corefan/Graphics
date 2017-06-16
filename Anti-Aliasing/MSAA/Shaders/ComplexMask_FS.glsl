#version 450

layout (location=0) out vec4 FS_Color;

uniform sampler2DMS uNormalDepthTex;
uniform sampler2DMS uDiffuseEdgeTex;
uniform sampler2DRect uResolvedColorTex;
uniform int uUseDiscontinuity;

const uint cMSAACount = 4;

// Coverage Mask version
void main(void)
{
    if (uUseDiscontinuity > 0.5) //ͨ���Ƚ�ģ�͵���Ȼ��߷��߻�����ɫ����������Ե
    {
        vec4 NormalDepth = texelFetch(uNormalDepthTex, ivec2(gl_FragCoord.xy), 0);
        vec4 DiffuseEdge = texelFetch(uDiffuseEdgeTex, ivec2(gl_FragCoord.xy), 0);

        vec3 Normal = NormalDepth.xyz;
        float Depth = NormalDepth.w;
        vec3 Albedo = DiffuseEdge.rgb;

        for (int i = 1; i < cMSAACount; ++i)
        {
            vec4 NormalDepthNext = texelFetch(uNormalDepthTex, ivec2(gl_FragCoord.xy), i);
            vec4 DiffuseEdgeNext = texelFetch(uDiffuseEdgeTex, ivec2(gl_FragCoord.xy), i);

            vec3 NextNormal = NormalDepthNext.xyz;
            float NextDepth = NormalDepthNext.w;
            vec3 NextAlbedo = DiffuseEdgeNext.rgb;

			//ֻҪ����һ����������ΪComplex Pixel
            if (abs(Depth - NextDepth) > 0.1f ||
                abs(dot(abs(Normal - NextNormal), vec3(1, 1, 1))) > 0.1f ||
                abs(dot(Albedo - NextAlbedo, vec3(1, 1, 1))) > 0.1f)
            {
                discard;
            }
        }
    }
    else if (texture(uResolvedColorTex, gl_FragCoord.xy).a > 0.02) //aͨ����ֵΪ0��1��1ΪComplex Pixel��0ΪSimple Pixel
    {
        discard;
    }

    FS_Color = vec4(0.0, 0.0, 0.0, 0.0); //Simple Pixelͨ��ģ����ԣ�ģ��ֵ����Ϊ1
}
