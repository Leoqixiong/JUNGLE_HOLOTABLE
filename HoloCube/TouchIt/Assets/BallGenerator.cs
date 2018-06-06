using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BallGenerator : MonoBehaviour {
    List<GameObject> BallArray = new List<GameObject>();
    List<Vector3> BallOrigin = new List<Vector3>();
    int span = 3;
    
	// Use this for initialization
	void Start () {
        int index = - (span - 1) / 30;

        int total = span * span * span;
		for (int i = 0; i < total; i++)
        {
            GameObject c = GameObject.CreatePrimitive(PrimitiveType.Sphere);

            if (true)
            {
                c.transform.position = new Vector3((-1 + (i / 3) % 3) / 10f, 
                                                   (-1 + (i % 3)) / 10f, 
                                                   (-1 + (i / 9)) / 10f);
            }
            else
            {
                c.transform.position = new Vector3(index, index, index) +  new Vector3(
                                                   ((i / span) % span) / 10f,
                                                   (i % span) / 10f,
                                                   (i / (span * span)) / 10f
                                                   );
            }

            c.transform.localScale = new Vector3(0.03f, 0.03f, 0.03f);
            c.AddComponent<Rigidbody>();
            c.GetComponent<Rigidbody>().useGravity = false;
            c.GetComponent<Rigidbody>().drag = 2f;
            c.transform.parent = this.gameObject.transform;
            // c.GetComponent<Renderer>().material.color = new Color(0.1f + (i / total), 0.1f + (i / total), 0.1f + (i / total));

            BallArray.Add(c);
            BallOrigin.Add(c.transform.position);
        }

        Camera.main.projectionMatrix = Camera.main.projectionMatrix * Matrix4x4.Scale(new Vector3(-1, -1, 1));
    }
	
	// Update is called once per frame
	void Update ()
    {
        for (int i = 0; i < BallArray.Count; i++)
        {
            // BallArray[i].transform.position = Vector3.Lerp(BallArray[i].transform.position, BallOrigin[i], 0.05f);
            BallArray[i].GetComponent<Rigidbody>().AddForce((BallOrigin[i] - BallArray[i].transform.position) * 2, ForceMode.Force); 
        }
	}
}
