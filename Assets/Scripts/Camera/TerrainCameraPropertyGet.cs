using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TerrainCameraPropertyGet : MonoBehaviour
{
    private GameObject followTerrain;
    private TerrainData followTerrainData;
    private Camera terrainCam;
    public new string tag;
    // Start is called before the first frame update
    void Start()
    {
        followTerrain = GameObject.FindGameObjectWithTag(tag);
        terrainCam= gameObject.GetComponent<Camera>();
        followTerrainData = followTerrain.GetComponent<Terrain>().terrainData;
        terrainCam.farClipPlane += followTerrainData.size.y;
        transform.position = new Vector3(followTerrain.transform.position.x + terrainCam.orthographicSize,
                                       followTerrain.transform.position.y + terrainCam.farClipPlane * 0.5f + followTerrainData.size.y,
                                       followTerrain.transform.position.z + terrainCam.orthographicSize);

        //terrainCam.orthographicSize = followTerrainData.size.x/2;

    }

    // Update is called once per frame
}
