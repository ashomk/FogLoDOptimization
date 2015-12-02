using UnityEngine;
using System.Collections;

public class FogLoDController : MonoBehaviour {

	public bool enableFogOcclusion = true;

	void OnWillRenderObject () {
	
		Vector3 camPosition = Camera.current.transform.position;
		Renderer renderer = GetComponent<Renderer> ();
		Vector3 closestPoint = renderer.bounds.ClosestPoint (camPosition);
		Vector3 viewVector = closestPoint - camPosition;
		float viewDistance = viewVector.magnitude;
		float occlusionLevel = 0;

		if (enableFogOcclusion) {

			switch (RenderSettings.fogMode) {

			case FogMode.Linear:
				occlusionLevel = (RenderSettings.fogEndDistance - viewDistance) /
					(RenderSettings.fogEndDistance - RenderSettings.fogStartDistance);
				break;
			case FogMode.Exponential:
				occlusionLevel = Mathf.Exp (-viewDistance * RenderSettings.fogDensity);
				break;
			case FogMode.ExponentialSquared:
				occlusionLevel = Mathf.Exp (-viewDistance * RenderSettings.fogDensity *
					viewDistance * RenderSettings.fogDensity);
				break;
			}

			occlusionLevel = 1f - Mathf.Clamp01 (occlusionLevel);
		}

		renderer.material.SetFloat ("_EdgeTessellationFactor", occlusionLevel);

		if (occlusionLevel > 0.95f) renderer.material.SetFloat ("_ShadingLevel", 0.5f);
		else if (occlusionLevel > 0.75f) renderer.material.SetFloat ("_ShadingLevel", 1.5f);
		else renderer.material.SetFloat ("_ShadingLevel", 3);
	}
}
