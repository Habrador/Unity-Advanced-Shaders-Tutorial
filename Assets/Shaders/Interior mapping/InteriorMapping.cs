using System.Collections;
using System.Collections.Generic;
using UnityEngine;

//Set the gameobjects materials properties to render the interior shader with local gameobject parameters
[ExecuteInEditMode]
public class InteriorMapping : MonoBehaviour 
{
    private Material buildingMaterial;
	
	void Start() 
	{
        buildingMaterial = GetComponent<MeshRenderer>().sharedMaterial;
	}
	
	
	void Update() 
	{
        buildingMaterial.SetVector("_ForwardDir", transform.forward);
        buildingMaterial.SetVector("_UpDir", transform.up);
        buildingMaterial.SetVector("_RightDir", transform.right);
    }
}
