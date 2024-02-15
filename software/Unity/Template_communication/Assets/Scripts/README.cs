//This is the Readme file for the Matlab-Unity communication template

/*To enable communication, drop the 'Communication' object somewhere in your hierarchy. It should contain the following scripts:
 * Settings
 * ComposeMessage
 * ThreadManager
 * Client
 * (README)
 
The other scripts should still be present in your Scripts folder, but they do not need to be attached to the Communication object

 The only pieces of code that should need editing, are 'Settings' and 'Compose Message'

'Settings' can be interacted with mainly through the GUI via checkboxes etc. If you'd like to add new variables, follow the existing structure in the Settings file. It
looks overly complicated, but it is necessary to make sure that interactable variables are available to multiple scripts at the same time.
Do note that your settings will be read only once, when the Unity program is started. So, changing them while runnning will not affect anything.
For reading in data from matlab, make sure that the size of your message matches with the 'Nr input signals' variable. 

'Compose Message' is the main script where custom code goes and where data storage is organized. For storing data other than the variables that you are sending and receiving,
make sure that you add the variables to both the header (in the Start call) and in the actual Update loop. Also be careful of adding the right number of commas, and make sure
that the last call of the line is the sb.AppendLine call.

The Update loop is the main place where your custom code goes. tempSignal is now a fixed value, but this could be anything. If you change the data type or the number of signals,
do make sure to also adapt the following:
- your data storage
- the arguments in the SendInputToServer function call (for now it expects to only see one double value)
- the SendData function call in the ClientSend script. You can call _packetWrite repeatedly for writing multiple values (of different data types, it should automatically recognize your data type).
Once you have written all your data to your packet, end the function with calling SendTCPData(_packet) once (like it is now).

 */
