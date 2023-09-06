using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Xml.Serialization;
using UnityEngine;
using UnityEngine.InputSystem;
using static UnityEngine.GraphicsBuffer;

public class CameraMovement : MonoBehaviour
{
    public float rotateSpeed;
    public float zoomSpeed;
    public float maxZoomIn;
    public float maxZoomOut;

    private InputSystem inputSystem;

    private InputAction lookAction;
    private InputAction zoomAction;


    public GameObject cameraPos;


    public float zoomAmount = 0;
    private Vector2 rotateAngle;
    private Vector2 rotateAngular;

    private bool isCursorLock = true;

    private void Awake()
    {
        inputSystem = new InputSystem();
    }

    private void Start()
    {
        Cursor.lockState = CursorLockMode.Locked;
        Cursor.visible = false;
    }

    private void OnEnable()
    {


        lookAction = inputSystem.Player.Look;
        lookAction.Enable();

        zoomAction = inputSystem.Player.Zoom;
        zoomAction.Enable();


        inputSystem.Screen.CursorLock.performed += lockCursor;
        inputSystem.Screen.CursorLock.Enable();
    }

    private void OnDisable()
    {
        lookAction.Disable();
        zoomAction.Disable();

        inputSystem.Screen.CursorLock.Disable();
    }

    void lockCursor(InputAction.CallbackContext context)
    {
        if (!isCursorLock)
        {
            Cursor.lockState = CursorLockMode.Locked;
            Cursor.visible = false;
            isCursorLock = true;
        }
        else
        {
            Cursor.lockState = CursorLockMode.None;
            Cursor.visible = true;
            isCursorLock = false;
        }

    }
    // Update is called once per frame
    private void Update()
    {
        if (isCursorLock)
        {
            Vector2 mouseDelta = lookAction.ReadValue<Vector2>();
            rotateAngle.x = mouseDelta.x * Time.deltaTime * rotateSpeed;//rotateAngle.x += mouseDelta.x * Time.deltaTime * rotateSpeed;
            rotateAngle.y = mouseDelta.y * Time.deltaTime * rotateSpeed;


            cameraPos.transform.RotateAround(cameraPos.transform.parent.position, Vector3.up, rotateAngle.x);
            cameraPos.transform.RotateAround(cameraPos.transform.parent.position, Vector3.right, -rotateAngle.y);

            transform.position = cameraPos.transform.position;


            transform.LookAt(cameraPos.transform.parent);
        }
        

    }
}