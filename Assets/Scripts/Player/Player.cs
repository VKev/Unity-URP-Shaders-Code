using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.InputSystem;

public class Player : MonoBehaviour
{
    
    public float moveSpeed;
    public bool interactWithGrass;
    private Camera cam;
    private InputSystem inputSystem;

    private InputAction moveAction;
    private InputAction flyAction;

    private Rigidbody rb;
    // Start is called before the first frame update
    void Awake()
    {
        inputSystem = new InputSystem();
        rb = GetComponent<Rigidbody>();
        cam = Camera.main;
    }

    private void OnEnable()
    {


        moveAction = inputSystem.Player.Move;
        moveAction.Enable();

        flyAction = inputSystem.Player.Fly;
        flyAction.Enable();


        //inputSystem.Screen.CursorLock.performed += lockCursor;
        //inputSystem.Screen.CursorLock.Enable();
    }
    private void OnDisable()
    {
        moveAction.Disable();
        flyAction.Disable();


        //inputSystem.Screen.CursorLock.Disable();
    }

    // Update is called once per frame
    void Update()
    {
        if (interactWithGrass)
        {
            Shader.SetGlobalVector("_PlayerWpos", transform.position);
            
        }
    }
    private void FixedUpdate()
    {
        Vector3 movInputDir = new Vector3( moveAction.ReadValue<Vector2>().x,0, moveAction.ReadValue<Vector2>().y);
        Vector3 movDir = Quaternion.AngleAxis(cam.transform.eulerAngles.y,Vector3.up)* movInputDir;
        float flyDir = flyAction.ReadValue<float>();
        rb.velocity = (movDir + Vector3.up * flyDir) * moveSpeed * Time.fixedDeltaTime;


    }
    private void OnApplicationFocus(bool focus)
    {
        if (focus)
        {
            Cursor.lockState = CursorLockMode.Locked;
        }
        else
        {
            Cursor.lockState= CursorLockMode.None;
        }
    }
}
