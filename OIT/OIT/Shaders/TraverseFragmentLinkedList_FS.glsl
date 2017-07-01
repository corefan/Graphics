#version 450 core

layout (binding = 0, r32ui) uniform uimage2D uStartOffsetImage;
layout (binding = 1, rgba32ui) uniform uimageBuffer uFragmentListBuffer;

//uniform sampler2D uStartOffsetImage;
//uniform samplerBuffer uFragmentListBuffer;

layout (location = 0) out vec4 Color;

#define MAX_FRAGMENTS 40
uvec4 g_Fragments[MAX_FRAGMENTS];

//������������ƬԪȡ������fragmentlist[],Ȼ�󷵻�����ƬԪ��Ŀ
int buildLocalFragmentList(void)
{
	uint Current = 0;
	int FragCount = 0;

	Current = imageLoad(uStartOffsetImage, ivec2(gl_FragCoord.xy)).x;
	//Current = texelFetch(uStartOffsetImage, ivec2(gl_FragCoord.xy), 0);

	//ִ��ѭ����ֱ������ĩ��
	while (Current != 0 && FragCount < MAX_FRAGMENTS)
	{
		//uvec4 Item = texelFetch(uFragmentListBuffer, Current);
		uvec4 Fragment = imageLoad(uFragmentListBuffer, int(Current));
		Current = Fragment.x;
		g_Fragments[FragCount] = Fragment;
		FragCount++;
	}

	return FragCount;
}

//ƬԪ�����������
void sortFragmentList(in int vFragCount)
{
	int i = 0, j = 0;

	for (i=0; i<vFragCount-1; i++)
	{
		for (j=i+1; j<vFragCount; j++)
		{
			float Depth_i = uintBitsToFloat(g_Fragments[i].z);
			float Depth_j = uintBitsToFloat(g_Fragments[j].z);

			if (Depth_i < Depth_j)
			{
				uvec4 Temp = g_Fragments[j];
				g_Fragments[j] = g_Fragments[i];
				g_Fragments[i] = Temp;
			}
		}
	}
}

//Alpha ��Ϻ���
vec4 blend(in vec4 vCurrentColor, in vec4 vNewColor)
{
	//return mix(vCurrentColor, vNewColor, 0.5);
	return vCurrentColor*0.5 + vNewColor * 0.5;
}

//��������ƬԪ��ɫ���������飬ÿ��������֮ǰ�����ػ��
vec4 calculateFinalColor(in int vFragCount)
{
	//vec4 FinalColor = vec4(0.0);
	vec4 FinalColor = vec4(0.1f, 0.2f, 0.2f, 1.0f);

	int i = 0;
	for (i=0; i<vFragCount; i++)
	{
		vec4 FragColor = unpackUnorm4x8(g_Fragments[i].y); //32λ�޷��������ֽ�Ϊ4��8λ�޷�����������ת���Ʊ�׼���ĸ���ֵ�� f / 255.0
		FinalColor = blend(FinalColor, FragColor);
	}

	return FinalColor;
}

void main()
{
	int FragCount = buildLocalFragmentList();

	sortFragmentList(FragCount);
	
	Color = calculateFinalColor(FragCount);
}