using UnityEngine;
using System.Collections;

public class FlyCam : MonoBehaviour {

	/*
	EXTENDED FLYCAM
		Desi Quintans (CowfaceGames.com), 17 August 2012.
		Based on FlyThrough.js by Slin (http://wiki.unity3d.com/index.php/FlyThrough), 17 May 2011.
 
	LICENSE
		Free as in speech, and free as in beer.
 
	FEATURES
		WASD/Arrows:	Movement
		Space:    		Climb
		C:    			Drop
        Shift:    		Move faster
        Control:    	Move slower
        End:    		Toggle cursor locking to screen (you can also press Ctrl+P to toggle play mode on and off).
	*/

	//...and updated by me!
	
	public float cameraSensitivity = 90;
	public float climbSpeed = 4;
	public float normalMoveSpeed = 10;
	public float slowMoveFactor = 0.25f;
	public float fastMoveFactor = 3;
	
	private float rotationX = 0.0f;
	private float rotationY = 0.0f;



	void Start() {
		Cursor.lockState = CursorLockMode.Locked;
	}



	void Update () {
		rotationX += Input.GetAxis("Mouse X") * cameraSensitivity * Time.deltaTime;
		rotationY += Input.GetAxis("Mouse Y") * cameraSensitivity * Time.deltaTime;
		rotationY = Mathf.Clamp(rotationY, -90, 90);
		
		transform.localRotation = Quaternion.AngleAxis(rotationX, Vector3.up);
		transform.localRotation *= Quaternion.AngleAxis(rotationY, Vector3.left);


		//Move forward/back with different speeds
		Vector3 move_horizontal = transform.right * normalMoveSpeed * Input.GetAxis("Horizontal") * Time.deltaTime;
		Vector3 move_vertical = transform.forward * normalMoveSpeed * Input.GetAxis("Vertical") * Time.deltaTime;

		if (Input.GetKey (KeyCode.LeftShift) || Input.GetKey (KeyCode.RightShift)) {
			move_horizontal *= fastMoveFactor;
			move_vertical *= fastMoveFactor;
		}
		else if (Input.GetKey (KeyCode.LeftControl) || Input.GetKey (KeyCode.RightControl)) {
			move_horizontal *= slowMoveFactor;
			move_vertical *= slowMoveFactor;
		}

		transform.position += move_horizontal;
		transform.position += move_vertical;
		

		//Move up/down
		if (Input.GetKey (KeyCode.Space)) {
			transform.position += transform.up * climbSpeed * Time.deltaTime;
		}
		if (Input.GetKey (KeyCode.C)) {
			transform.position -= transform.up * climbSpeed * Time.deltaTime;
		}


		//Display/lock cursor
		if (Input.GetKeyDown (KeyCode.End)) {
			if (Cursor.lockState == CursorLockMode.Locked) {
				Cursor.lockState = CursorLockMode.None;
				Cursor.visible = true;
			}
			else {
				Cursor.lockState = CursorLockMode.Locked;
				Cursor.visible = false;
			}
		}
	}
}
