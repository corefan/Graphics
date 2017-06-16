#pragma once
#include <gl/glew.h>
#include <gl/freeglut.h>
#include <GLM/glm.hpp>
#include <AntTweakBar/AntTweakBar.h>
#include <Cooler/Effect.h>
#include "MSAAFBO.h"

namespace Cooler
{
	CInputTransformer;
}

class CMSAAEffect : public Cooler::CEffect
{
public:
	enum EMSAAMethod
	{
		APPROACH_NOMSAA,
		APPROACH_COVERAGEMASK,
		APPROACH_DISCONTINUITY,
	};

public:
	CMSAAEffect();
	virtual ~CMSAAEffect();

protected:
	virtual void _initEffectV() override;
	virtual void _renderEffectV() override;
	virtual void _destoryEffectV() override;

private:
	void __initTweakBar();
	void __lightingPass();
	void __geometryPass_NoMSAA();
	void __geometryPass();
	void __resolveMSAAGBuffer();
	void __fillStencilBuffer();

	void __performSingelPassLighting();
	void __performDualPassLighting_PerPixel();
	void __performDualPassLighting_PerSample();

	void __updateRenderTargets();
	void __destoryRenderTargets();
	void __renderScreenSizeQuad();
	void __initSceneData();

//	EMSAAMethod m_MSAAMehod;
	glm::mat4 m_ProjectionMatrix, m_ModelViewMatrix, m_NormalMatrix;
	Cooler::CInputTransformer* m_pInputTransformer;
	CMSAAFBO* m_pMSAAFBO;
	GLuint m_VBO, m_VAO;

	int m_BRDF;

	static int m_MSAAMehod, /*m_bUseDiscontinuity,*/ m_bMarkComplexPixels; //����û��ʹ��bool��������Ϊ������tweark bar��bool֧�ֲ�̫�Ѻã�����
	static int m_bSeparateComplexPass;
	static int m_bUsePerSamplePixelShader, m_bAdaptiveShading; //Note:1) PerSample��AdaptiveShading����,��PerSample���ر�AdaptiveShading;��Adaptive���ر�Persample
	 															   //     2) PerSample�򿪣���Separate complex pass; �ر�SeqarateComplexPass��ҲӦ�ùر�PerSample

	static void TW_CALL setMSAAMethod(const void *value, void * /*clientData*/);
	static void TW_CALL getMSAAMethod(void *value, void * /*clientData*/);

	static void TW_CALL setPerSampleCB(const void *value, void * /*clientData*/);
	static void TW_CALL getPerSampleCB(void *value, void * /*clientData*/);
	 
	static void TW_CALL setAdaptiveShadingCB(const void *value, void * /*clientData*/);
	static void TW_CALL getAdaptiveShadingCB(void *value, void * /*clientData*/);
	 
	static void TW_CALL setSeparateComplexPassCB(const void *value, void * /*clientData*/);
	static void TW_CALL getSeparateComplexPassCB(void *value, void * /*clientData*/);
};

int CMSAAEffect::m_MSAAMehod = 1;
int CMSAAEffect::m_bMarkComplexPixels = 0;

int CMSAAEffect::m_bSeparateComplexPass = 1;
int CMSAAEffect::m_bAdaptiveShading = 0;
int CMSAAEffect::m_bUsePerSamplePixelShader = 0;