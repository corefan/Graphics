#version 450 core

struct SBaseLight 
{
    vec4 Color; 
    float AmbientIntensity; 
    float DiffuseIntensity;
	vec2 BaseLightAlign;
};

struct SAttenuation
{
	float Constant;
	float Linear;
	float Quadratic;
	float AttenAlign;
};

struct SPointLight
{
	SBaseLight BaseLight;
	vec4 LightPosition; 
	SAttenuation Attenuation;
};

layout (std430, binding=1) buffer ssbo_block_GPULightEnv //���Դ����
{
	SPointLight uPointLight[];
};

struct SDirectionalLight
{
    SBaseLight BaseLight;
    vec4 Direction;
};
uniform SDirectionalLight uDirectionalLight; //�����

layout (binding = 0, r32ui) uniform uimage2D uLightStartOffsetImage;
layout (binding = 1, rgba32ui) uniform uimageBuffer uLightFragmentLinkedLBuffer;

layout (location = 0) out vec4 Color;

#define MAX_LIGHT_FRAGMENTS 100

uniform sampler2D uColorTex;
uniform vec3 uEyeWorldPos;
uniform float uShininess = 128;
uniform float uSpecularIntensity = 1.0;

in vec2 g_TexCoord;
in vec3 g_Normal;
in vec3 g_WorldPos;

//******************************************************************
//FUNCTION:
vec4 calcLightInternal(in SBaseLight vBaseLight, in vec3 vLightDirection,  in vec3 vWorldPos, in vec3 vNormal)
{
	vec4 AmbientColor = vec4(vBaseLight.Color.xyz * vBaseLight.AmbientIntensity, 1.0);
	vec4 DiffuseColor = vec4(0.0, 0.0, 0.0, 0.0);
	vec4 SpecularColor = vec4(0.0, 0.0, 0.0, 0.0);
	
	vec3 LightDirection = normalize(-vLightDirection);
	float DiffuseFactor = dot(normalize(vNormal), LightDirection);
	if (DiffuseFactor > 0.0)
	{
		DiffuseColor = vec4(vBaseLight.Color.xyz * vBaseLight.DiffuseIntensity * DiffuseFactor, 1.0);
		
		vec3 Vertex2Eye = normalize(uEyeWorldPos - vWorldPos);
		vec3 ReflectLight = normalize(reflect(-LightDirection, normalize(vNormal)));	

		float Specularvactor = dot(Vertex2Eye, ReflectLight);
		if (Specularvactor > 0.0)
		{
			SpecularColor = vec4(pow(Specularvactor, uShininess) * vBaseLight.Color.xyz * uSpecularIntensity, 1.0);
		}
	}

	return AmbientColor + DiffuseColor + SpecularColor;
}

//******************************************************************
//FUNCTION:
vec4 calcPunctualLight(in vec3 vWorldPos, in vec3 vNormal, in uint vLightIndex)
{
	vec3 LightDir = vWorldPos - uPointLight[vLightIndex].LightPosition.xyz;
	float Length = length(LightDir);
	LightDir = normalize(LightDir);

	vec4 Color = calcLightInternal(uPointLight[vLightIndex].BaseLight, LightDir, vWorldPos, vNormal);

	float Attenuation = uPointLight[vLightIndex].Attenuation.Constant + uPointLight[vLightIndex].Attenuation.Linear * Length + uPointLight[vLightIndex].Attenuation.Quadratic * Length * Length;
	Attenuation = max(1.0, Attenuation);

	return Color / Attenuation;
}

//������Դ����
vec4 calcDynamicLights(in vec3 vWorldPos, in vec3 vNormal, in float vCurrentFragmentDepth)
{
	uint Current = 0;
	int LightFragCount = 0;

	Current = imageLoad(uLightStartOffsetImage, ivec2(gl_FragCoord.xy)).x;

	vec4 FinalFragmentColor = vec4(0.0);
			
	//ִ��ѭ����ֱ������ĩ��
	while (Current != 0 && LightFragCount < MAX_LIGHT_FRAGMENTS)
	{
		LightFragCount++;

		uvec4 LightFragmentLink = imageLoad(uLightFragmentLinkedLBuffer, int(Current));
		Current = LightFragmentLink.w;

		float MinLightDepth = uintBitsToFloat(LightFragmentLink.y);
		float MaxLightDepth = uintBitsToFloat(LightFragmentLink.z);

		if ( (MinLightDepth > vCurrentFragmentDepth) || (MaxLightDepth < vCurrentFragmentDepth)) //�򵥵�bound test,�����ǰ���ز��ڹ�Դ���ڣ��������󲿼���
			continue;
		
		uint LightIndex = LightFragmentLink.x;
		vec4 FragmentColor = calcPunctualLight(vWorldPos, vNormal, LightIndex);
		FinalFragmentColor += FragmentColor;
	}

	return FinalFragmentColor;
}

//******************************************************************
//FUNCTION:
vec4 calcDirectionalLight(in vec3 vWorldPos, in vec3 vNormal)
{
	return calcLightInternal(uDirectionalLight.BaseLight, uDirectionalLight.Direction.xyz, vWorldPos, vNormal);
}

void main()
{
	vec3 Normal = normalize(g_Normal);
	float fSceneDepth = gl_FragCoord.z;
	vec4 PointLightColor = calcDynamicLights(g_WorldPos, Normal, fSceneDepth); //���Դ������ɫ

	vec4 DiffuseColor = texture2D(uColorTex, g_TexCoord); //������ɫ
	vec4 DirectionLightColor = calcDirectionalLight(g_WorldPos, Normal); //����������ɫ

	vec4 LightColor = PointLightColor + DirectionLightColor;
	Color = vec4(DiffuseColor.xyz, 1.0) * LightColor;
	Color.a = 0.5;
}