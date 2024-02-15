using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using System.IO;
using System;
using System.Text;


public class ComposeMessage : MonoBehaviour
{

    //incoming data is handled in ClientHandle. Outgoing data is handled in ClientSend

    //this thread handles continuous outgoing data
    static float updateTimestep;
    static float update = 0.0f;
    static double currentSignal;
    static int counter = 0;

    //initialize simulation variables
    private float tempSignal;

    StringBuilder sb = new StringBuilder();


    public void Start()
    {
            updateTimestep = 1.0f / Settings.updateFrequency;

            currentSignal = 0;

        if (Settings.storingData == true)
        {
            Settings.filePath = Settings.filePath + "_pp"+ Settings.participant + "_" + DateTime.Now.ToString("yyyy-mm-dd-hh-mm-ss") + ".txt";
            sb.Append("Time, Frame, MessageSent");

            if (Settings.receivingData == true)
            {
                for (int i = 0; i < Settings.nrInputSignals; i++) {
                    sb.Append(",");
                    sb.Append($"MessageReceived_{i}");
                }
            }

            sb.AppendLine();
        }

    }

    public void Update()
    {

        update += Time.deltaTime;               //this controls the timing of the loop
        if (update > updateTimestep)
        {

            //for now, it is just 0. Here, you can add your own logic
            tempSignal = 1.5f;

            currentSignal = (double)tempSignal;


        if (Settings.dataToConsole)
        {
            Debug.Log($"Trying to send: {tempSignal}");
        }

        if (Settings.storingData == true)
        {
            sb.Append(Time.realtimeSinceStartup);
            sb.Append(",");
            sb.Append(counter);
            sb.Append(",");
            sb.Append(currentSignal);

            if (Settings.receivingData == true)
            {
                for (int i=0; i < Settings.nrInputSignals; i++) {
                    sb.Append(",");
                    sb.Append(ClientHandle.pressureReceived[i]);
                }

             }

            //here more data can be stored, if this is also reflected in the header
            sb.AppendLine();

        }

        SendInputToServer(currentSignal);
        update = 0.0f;
        counter++;
    }

    }

    private void SendInputToServer(double _pressureMessage)
    {
        ClientSend.SendData(_pressureMessage);
        //Debug.Log("Sending out pressure");
    }

    private void OnApplicationQuit()
    {
        if (Settings.storingData == true)
        {

            if (!File.Exists(Settings.filePath))
            {
                File.WriteAllText(Settings.filePath, sb.ToString());
            }
            else
            {
                File.AppendAllText(Settings.filePath, sb.ToString());
            }

        }

        Debug.Log("Quitting");
    }
}