Shader "Custom/BRDF/LambertMVP"
{
    Properties
    {
        [MainTexture] _BaseMap("Base Map", 2D) = "white" {}

        _L("Local (Object)", Vector) = (0, 0, 0, 0)
        _M("Model (World)", Vector) = (0, 0, 0, 0)
        _V("View (Camera)", Vector) = (0, 0, 0, 0)
        _P("Projection (Clip)", Vector) = (0, 0, 0, 0)
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 uv           : TEXCOORD0;
                float3 normalOS     : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float3 normal       : TEXCOORD1;
                float3 viewDir      : TEXCOORD2;
                float3 lightDir     : TEXCOORD3;
            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            float4 _L;
            float4 _M;
            float4 _V;
            float4 _P;

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                IN.positionOS += _L; // 오브젝트 공간에 개입
                float4 posWS = mul(UNITY_MATRIX_M, IN.positionOS); // M
                posWS += _M; // 월드 공간에 개입
                float4 posVS = mul(UNITY_MATRIX_V, posWS); // V
                posVS += _V; // 뷰(카메라) 공간에 개입
                OUT.positionHCS = mul(UNITY_MATRIX_P, posVS); // P
                OUT.positionHCS += _P; // 클립 공간에 개입

                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                OUT.normal = TransformObjectToWorldNormal(IN.normalOS);
                OUT.viewDir = normalize(_WorldSpaceCameraPos.xyz - TransformObjectToWorld(IN.positionOS.xyz));
                OUT.lightDir = normalize(_MainLightPosition.xyz);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                // 이걸 안 하면 버텍스 사이 픽셀 노멀의 길이가 1이 아닌 것들이 발생함.
                IN.normal = normalize(IN.normal);

                half4 color = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv);
                float NdotL = saturate(dot(IN.normal, IN.lightDir));
                half3 ambient = SampleSH(IN.normal);
                half3 lighting = NdotL * _MainLightColor.rgb + ambient;
                color.rgb *= lighting;
                
                return color;
            }
            ENDHLSL
        }
        UsePass "Universal Render Pipeline/Lit/ShadowCaster"
    }
}