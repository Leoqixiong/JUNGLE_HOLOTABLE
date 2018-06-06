using UnityEngine;

class DetonationSpawner : MonoBehaviour {
	public GameObject myFusion;
	public GameObject myFusion2;

	void Update () {
		if(Input.GetMouseButtonUp(0)){
			Instantiate(myFusion, Vector3.zero, Random.rotation);
		}
	
		if(Input.GetMouseButtonUp(1)){
			Instantiate(myFusion2, Vector3.zero, Random.rotation);
		}
	}
}