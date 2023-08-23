using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Xml.Serialization;
using UnityEngine;
using UnityEngine.InputSystem;

public class CameraMovement : MonoBehaviour
{
    public float rotateSpeed;
    public float moveSpeed;
    private InputSystem inputSystem;
    private InputAction moveAction;
    private InputAction lookAction;
    private InputAction flyAction;

    private Rigidbody rb;

    private Vector2 rotateAngle;

    private bool isCursorLock = true;

    private void Awake()
    {
        inputSystem = new InputSystem();
        rb = GetComponent<Rigidbody>();
    }

    private void Start()
    {
        Cursor.lockState = CursorLockMode.Locked;
        Cursor.visible = false;
    }

    private void OnEnable()
    {
        moveAction = inputSystem.Player.Move;
        moveAction.Enable();

        lookAction = inputSystem.Player.Look;
        lookAction.Enable();

        flyAction = inputSystem.Player.Fly;
        flyAction.Enable();



        inputSystem.Screen.CursorLock.performed += lockCursor;
        inputSystem.Screen.CursorLock.Enable();
    }

    private void OnDisable()
    {
        moveAction.Disable();
        lookAction.Disable();
        flyAction.Disable();

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
            rotateAngle.x += mouseDelta.x * Time.deltaTime * rotateSpeed;
            rotateAngle.y += mouseDelta.y * Time.deltaTime * rotateSpeed;

            transform.localRotation = Quaternion.Euler(-rotateAngle.y, rotateAngle.x, 0);
        }
        Vector2 movDir = moveAction.ReadValue<Vector2>();
        float flyDir = flyAction.ReadValue<float>();
        rb.velocity = (transform.forward * movDir.y + transform.right * movDir.x + Vector3.up * flyDir) * moveSpeed * Time.fixedDeltaTime;

    }
    private void FixedUpdate()
    {
        Vector2 movDir = moveAction.ReadValue<Vector2>();
        float flyDir = flyAction.ReadValue<float>();
        rb.velocity = (transform.forward * movDir.y + transform.right * movDir.x + Vector3.up * flyDir) * moveSpeed * Time.fixedDeltaTime;

    }
}