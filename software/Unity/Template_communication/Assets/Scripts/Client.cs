using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.Net;
using System.Net.Sockets;
using System;

public class Client : MonoBehaviour
{

    // Client app is the one sending messages to a Server/listener.   
    // Both listener and client can send messages back and forth once a   
    // communication is established.  
    //public string welcomeMessage = "Client received the welcome";
    //public static string statWelcomeMessage;

    [HideInInspector]                   //this is a trick to hide the variable from the Unity Inspector
    //public string currentIp;
    //public int currentPort;
    public int myId = 1;
    public static int ExtraId = 1;      //I don't fully understand how these Ids and Instances overlap, for now this works for a single client

    //Initialization variables
    public static Client instance;
    public static int dataBufferSize = 4096;
    public TCP tcp;
    private delegate void PacketHandler(Packet _packet);
    private static Dictionary<int, PacketHandler> packetHandlers;

    private void Awake()
    {
        //statWelcomeMessage = welcomeMessage;

        //currentIp = Settings.ip;
        //currentPort = Settings.port;

        if (instance == null)
        {
            instance = this;
            Debug.Log("client running awake loop");
        }
        else if (instance != this)
        {
            Debug.Log("Instance already exists, destroying object!");
            Destroy(this);
        }

    }

    private void Start()
    {
        tcp = new TCP();
        Client.instance.ConnectToServer();
        Debug.Log("Connecting to server");

    }

    public void ConnectToServer()
    {
        InitializeClientData();
        Debug.Log("connect to server in Client loop");
        tcp.Connect();
    }

    public class TCP
    {
        public TcpClient socket;

        private NetworkStream stream;
        private Packet receivedData;
        private byte[] receiveBuffer;

        public void Connect()
        {
            socket = new TcpClient
            {
                ReceiveBufferSize = dataBufferSize,
                SendBufferSize = dataBufferSize
            };

            receiveBuffer = new byte[dataBufferSize];
            socket.BeginConnect(Settings.ip, Settings.port, ConnectCallback, socket);
        }

        private void ConnectCallback(IAsyncResult _result)
        {
            socket.EndConnect(_result);

            if (!socket.Connected)
            {
                return;
            }

            stream = socket.GetStream();

            receivedData = new Packet();

            stream.BeginRead(receiveBuffer, 0, dataBufferSize, ReceiveCallback, null);
        }

        public void SendData(Packet _packet)
        {
            try
            {
                if (socket != null)
                {
                    stream.BeginWrite(_packet.ToArray(), 0, _packet.Length(), null, null);
                }
            }
            catch (Exception _ex)
            {
                Debug.Log($"Error sending data to server via TCP: {_ex}");
            }
        }

        private void ReceiveCallback(IAsyncResult _result)
        {
            try
            {
                int _byteLength = stream.EndRead(_result);
                if (_byteLength <= 0)
                {
                    return;
                }

                byte[] _data = new byte[_byteLength];
                Array.Copy(receiveBuffer, _data, _byteLength);

                receivedData.Reset(HandleData(_data));
                stream.BeginRead(receiveBuffer, 0, dataBufferSize, ReceiveCallback, null);
            }

            catch (Exception _ex)
            {
                Console.WriteLine($"Error receiving TCP data: {_ex}");
            }
        }

        private bool HandleData(byte[] _data)
        {
            int _packetLength = 0;

            receivedData.SetBytes(_data);

            if (receivedData.UnreadLength() >= 4)
            {
                _packetLength = receivedData.ReadInt();
                if (_packetLength <= 0)
                {
                    return true;
                }
            }

            while (_packetLength > 0 && _packetLength <= receivedData.UnreadLength())
            {
                byte[] _packetBytes = receivedData.ReadBytes(_packetLength);
                ThreadManager.ExecuteOnMainThread(() =>
                {
                    using (Packet _packet = new Packet(_packetBytes))
                    {
                        int _packetID = _packet.ReadInt();
                        packetHandlers[_packetID](_packet);
                    }
                });

                _packetLength = 0;

                if (receivedData.UnreadLength() >= 4)
                {
                    _packetLength = receivedData.ReadInt();
                    if (_packetLength <= 0)
                    {
                        return true;
                    }
                }
            }

            if (_packetLength <= 1)
            {
                return true;
            }

            return false;

        }

    }

    //this Dictionary was set up to handle multiple clients, but for now we are only using a single client.
    //Therefore, the clientid is current hardcoded in ClientHandle. If you want to received other types of
    //data from the server, initialize those data types here.
    private void InitializeClientData()
    {
        packetHandlers = new Dictionary<int, PacketHandler>()
        {
            {(int)ServerPackets.incomingData,ClientHandle.ReceivePressure }
        };

        Debug.Log("Initialized Packets for receiving server info, woohoo!.");
    }

}
