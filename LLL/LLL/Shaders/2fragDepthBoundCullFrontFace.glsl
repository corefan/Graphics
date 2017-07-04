#version 450 core

layout (binding = 0, r32ui) uniform uimage2D uLightStartOffsetImage;
layout (binding = 1, rgba32ui) uniform uimageBuffer uLightFragmentLinkedLBuffer;

uniform uint uLightIndex;

#define MAX_LIGHT_FRAGMENTS 100

void insertLightCullingFrontface()
{
	float fBackLightDepth = gl_FragCoord.z;

	uint Current = 0;
	int LightFragCount = 0;

	Current = imageLoad(uLightStartOffsetImage, ivec2(gl_FragCoord.xy)).x;

	while (Current != 0 && LightFragCount < MAX_LIGHT_FRAGMENTS)
	{
		uvec4 LightFragmentLink = imageLoad(uLightFragmentLinkedLBuffer, int(Current));
		uint Pos = Current; 
		Current = LightFragmentLink.w;

		uint LightIndex = LightFragmentLink.x;
		if (LightIndex != uLightIndex)
		{
			LightFragCount++;
			continue;
		}
	
		uint uLightDepthMax = floatBitsToUint(fBackLightDepth);
		LightFragmentLink.z = uLightDepthMax; //�޸�Light Fragment Link buffer �������ֵ		
		imageStore(uLightFragmentLinkedLBuffer, int(Pos), LightFragmentLink);

		return; //�Ѿ��޸Ĺ�Դ��������ֵ��������ǰ����
	}
}

void main()
{	
	insertLightCullingFrontface();
}