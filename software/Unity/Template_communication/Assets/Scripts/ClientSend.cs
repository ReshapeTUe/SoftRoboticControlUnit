using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ClientSend : MonoBehaviour
{
    private static void SendTCPData(Packet _packet)
    {
       // _packet.WriteLength();
        if (Settings.sendingData == true)
        {
            Client.instance.tcp.SendData(_packet);
        }
    }

    #region Packets
    //public static void WelcomeReceived()
    //{
    //    using (Packet _packet = new Packet((int)ClientPackets.welcomeReceived))
    //    {
    //        //_packet.Write(Client.statWelcomeMessage);
    //        //SendTCPData(_packet);
    //        //commenting out because we are not sending this any more
    //        Debug.Log("Sending welcome data.");
    //    }
    //}

    public static void SendData(double _pressure)
    {
            using (Packet _packet = new Packet())
            {
                _packet.Write(_pressure);
                SendTCPData(_packet);
                //Debug.Log("writing a pressure");
            }

    }
    #endregion
}