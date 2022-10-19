using UnityEngine;
using System.Collections;

public class DeathStar : MonoBehaviour 
{
    public float height;
    public float distance;
    public float rotationSpeed;


	
	void Start() 
	{
        transform.position = new Vector3(distance, height, distance);
	}
	
	

	void Update() 
	{
        transform.RotateAround(Vector3.zero, Vector3.up, rotationSpeed * Time.deltaTime);
    }
}
