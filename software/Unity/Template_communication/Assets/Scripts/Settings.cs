using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Settings : MonoBehaviour
{

    [Tooltip("Participant id")]
    public string _participant = "1";
    [Tooltip("Condition to start with. Normally, this is always 0, but it might be different when starting after a crash")]
    public int _conditionStart = 0;
    [Tooltip("Should match receiving end. 127.0.0.1 means local")]
    public string _ip = "127.0.0.1";
    [Tooltip("Should match receiving end. Port 26950 is usually open")]
    public int _port = 26950;
    [Tooltip("Set to true to send data out")]
    public bool _sendingData = true;
    [Tooltip("Set to true to receive data")]
    public bool _receivingData = false;
    [Tooltip("Set to true to store data in text file")]
    public bool _storingData = false;
    [Tooltip("Path of data file")]
    public string _filePath = "Data/Testfile";
    [Tooltip("Update frequency for ComposeMessage loop. VR headset should be running at 90 Hz, so 90 is default.")]
    public float _updateFrequency = 90.0f;
    [Tooltip("Set to true to print data to console on each loop")]
    public bool _dataToConsole = true;
    [Tooltip("Nr of input signals if receiving data from Matlab")]
    public int _nrInputSignals = 0;

    //initialize static copy of fields, because we can only display non-static fields in Unity
    public static string participant;
    public static int conditionStart;
    public static string ip;
    public static int port;
    public static bool sendingData;
    public static bool receivingData;
    public static bool storingData;
    public static string filePath;
    public static float updateFrequency;
    public static bool dataToConsole;
    public static int nrInputSignals;

    private void Awake()
    {
        participant = _participant;
        conditionStart = _conditionStart;
        ip = _ip;
        port = _port;
        sendingData = _sendingData;
        receivingData = _receivingData;
        storingData = _storingData;
        filePath = _filePath;
        updateFrequency = _updateFrequency;
        dataToConsole = _dataToConsole;
        nrInputSignals = _nrInputSignals;
    }
}
