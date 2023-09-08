using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraPropertyGet : MonoBehaviour
{
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        Shader.SetGlobalMatrix("_CameraViewMatrix", Camera.main.worldToCameraMatrix);
    }
}
