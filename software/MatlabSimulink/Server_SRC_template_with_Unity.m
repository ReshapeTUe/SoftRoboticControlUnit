%%Femke van Beek, 05-07-2021, Server code for Matlab-Unity communication%%
clear all; close all; clc;

%Note: first run the Pi, then start this script. If you are running Unity,
%start that last. To use the escape key to stop the script, you need to
%install the Psychtoolbox from here: 

%%%%START INPUT SECTION

%%%Pi is client
IP_address_client = '192.168.4.1';                                          %most Pi's have address 192.168.4.1
Port_client = 12345;                                                        %Most Pi's use 12345
%%Unity is server
IP_address_server = '127.0.0.1';                                            %If Unity is running on the same machine, this is 127.0.0.1
Port_server = 26950;                                                        %User determined. Make sure that this matches up with the port in Unity
PiFs=110;                                                                   %Hz of Pi communication. I usually put this about 10% higher than the frequency on the Pi, to account for some computation time on Matlab's side

%Define variable names of incoming and outgoing variables. Variable names are only internal to matlab, so choose whatever works for you.
%The variable order is the order in which signals will be sent to the Pi.
%Leave PiIn empty when you only want to actuate, and not sense data

%Settings of data going out to Pi (data going from Matlab to Pi)
PiOutHeaderOrig.Variable = ["PresDes0","VT"];                                 %actuators that you would like to control
PiOutHeaderOrig.Channel = [3,1];                                              %i2c channels that your actuators use for communication
PiOutHeaderOrig.VEAB = [1,0];                                                 %set to 1 for VEAB channels, and 0 for all other channels
PiOutHeaderOrig.Baseline = [0.49,0];                                          %baseline values [with scaling set to None!] that should be sent out when nothing is happening, and when the program is closed. So 0=-5V, and 1=+5V. For regulators, this is normally 0.5 (or 0.49 to avoid leakage)
PiOutHeaderOrig.StoringData = false;

%Settings of data coming in from Pi (data going from Pi to Matlab)
PiInHeaderOrig.Variable = ["PresDes0"];                                     %sensors that you would like to read data from. Leave empty if you don't have these
PiInHeaderOrig.Channel = [3];                                               %i2c channels that your sensors use for communication
PiInHeaderOrig.VEAB = [1];                                                  %set to 1 for automatic VEAB sensor scaling, and 0 for all other channels
PiInHeaderOrig.StoringData = false;

%settings of VEAB actuators. Make sure that actuator array lengths correspond with number of VEAB PiOutHeader variables
Pressure.actuatorMin = [-2];                                                %Min relative pressure for actuators [kPa per actuator]
Pressure.actuatorMax = [23];                                                %Max relative pressure for actuators [kPa per actuator]
Pressure.regulatorMin = [-100];                                             %Min relative pressure output for regulators [kPa per regulator]
Pressure.regulatorMax = [100];                                              %Max relative pressure output for regulators [kPa per regulator]
Pressure.InVEABConversion = 1./16.89;                                       %value that VEAB sensor data needs to be multiplied by to get to proper matlab range. For the old boards, this is 1/10, for the new boards it's something like 1/16.67
Pressure.OutScaling = "Actuator";                                           %Choose "Actuator" to normalize to actuator bounds (0 is min, 1 is max), "KPa" to scale to KPa, or "None" for directly showing Pi commands;
Pressure.InScaling = "Actuator";                                            %Choose "Actuator" to normalize to actuator bounds (0 is min, 1 is max), "KPa" to scale to KPa, or "None" for directly showing Pi sensor data;

%Settings of data coming in from Unity  (data going from Unity to Matlab)
UnityInHeader.Variable = ["Pressure1","VT"];                                %variable name that you will use in rest of code
UnityInHeader.StoringData = false;

%Settings of data going out to Unity (data going from Matlab to Unity)
UnityOutHeader.Id = [];                                                    %ids that you want to see in your message
UnityOutHeader.Variable = [];                                              %variable name that you will use in rest of code
UnityOutHeader.StoringData = false;

%Switches for plotting etc
print_input = false;                                                        %set to true to display incoming data
print_plot = false;                                                          %set to true to print a plot after finishing communication

%%%%END INPUT SECTION%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Variable initialization. This probably doesn't have to change, so you can fold this
% 
%Initialize header structs
[PiInHeader,PiInHeaderOrig,PiOutHeader,PiOutHeaderOrig,Pressure,UnityInHeader,UnityOutHeader] = initializeStructs(PiInHeaderOrig,PiOutHeaderOrig,Pressure,UnityInHeader,UnityOutHeader);

%Initialize the rest of the variables
frequencyControlObjectPi = rateControl(PiFs);

PiInOn = ~isempty(PiInHeader.Variable);
PiOutOn = ~isempty(PiOutHeader.Variable);
UnityInOn = ~isempty(UnityInHeader.Variable);
UnityOutOn = ~isempty(UnityOutHeader.Variable);

countPiIn = 1;
countPiOut = 1;
countUnityIn = 1;
countUnityOut = 1;
PiBytesRead = [0];
PiBytesWritten = [0,0];
UnityBytesRead = [0];
UnityBytesWritten = [0,0];
stop_flag = 0;
KbName('UnifyKeyNames');
escapeKey = KbName('ESCAPE');
spaceKey = KbName('SPACE');
PiInStarted = false;

if(PiInOn)
    Pi_In_Data = InitializeArrays(PiInHeader);
end

if(PiOutOn)
    Pi_Out_Data = InitializeArrays(PiOutHeader);
end

if(UnityInOn)
    Unity_In_Data = InitializeArrays(UnityInHeader);
end

if(UnityOutOn)
    Unity_Out_Data = InitializeArrays(UnityOutHeader);
end

%start up TCP Server for Unity communication
if( UnityInOn || UnityOutOn)
    TCPServer = tcpserver(IP_address_server,Port_server);
    %configure callback to trigger when data comes in from Unity
    configureCallback(TCPServer,"byte",UnityInHeader.MessageLength,@(src,Header) readUnityData(src,UnityInHeader));
    disp("Unity connected");
end

%start up TCP Client for Pi communication
if( PiInOn || PiOutOn)
    TCPClient = tcpclient(IP_address_client,Port_client);
    disp("Pi connected");
end

%start timer
tic

%% START OF MAIN SECTION. Here, your custom code to generate signals can go

while (stop_flag==0)        %keeps looping as long as ESC key is not pressed
[~,~, keyCode] = KbCheck();    
   
    %% Signal generation for Pi. For now, we just use a simple sine wave and send that to all channels. All signals here are scaled to the settings in Pressure. Commanding 0 here means actuatorMin, and 1 actuatorMax
    
    %The meaning of your signal depends on your settings in
    %"Pressure.OutScaling". Make sure to line that up.

   if(PiOutOn)
     
       if(PiOutHeader.StoringData==true)
        indexPiOut = length([Pi_Out_Data.time])+1; 
       else
        indexPiOut = 1;
       end
        Pi_Out_Data(indexPiOut).time = toc;

        %here we generate the actual data for this time step. You can talk to the individual channels using the
        %variable names directly, or you can loop using the header
        %variable. For now, we are taking data coming from Unity as input
        %for the Pi
        
        %example of adressing individual channels
        %Pi_Out_Data(indexPiOut).("PresDes1")= 0.05*sin(Pi_Out_Data(index).time); 
        
        if(isfield(TCPServer.UserData,'time'))
            Pi_Out_Data(indexPiOut).("PresDes0") = TCPServer.UserData(end).("Pressure1");
            Pi_Out_Data(indexPiOut).("VT") = TCPServer.UserData(end).("VT");
        else
            Pi_Out_Data(indexPiOut).("PresDes0") = 0;
            Pi_Out_Data(indexPiOut).("VT") = 0;
        end

        %example of how to loop through the header variables. If you use this option, double-check
        %that you are using "PiOutHeaderOrig" to loop through, because in "PiOutHeader", dummy
        %channels are added for the VEAB boards which only have a single actuator attached. These dummy channels automatically reveice 0V,
        %so you don't have to define them here.
%         for sig=1:length(PiOutHeaderOrig.Variable)
%             Pi_Out_Data(indexPiOut).(PiOutHeaderOrig.Variable(sig))= 0.05*sin(Pi_Out_Data(indexPiOut).time); 
%         end
         
   end
         
    %% Write to Pi.
         
    if(PiOutOn)
        
        [Pi_Out_Data,PiBytesWritten] = WritePiData(TCPClient, Pi_Out_Data,PiOutHeader,PiBytesWritten,Pressure);

    end

    %% Read from Pi.
    
    if(PiInOn)
        
       [Pi_In_Data,PiBytesRead,PiInStarted]  = ReadPiData(TCPClient, Pi_In_Data, PiInHeader, PiBytesRead,Pressure,PiInStarted);

    end
    %% 
    
    if keyCode(escapeKey)
        stop_flag = 1;
        if(PiOutOn)
        SetPiToBaseline(TCPClient, PiOutHeader);
        pause(1);
        end
        clear TCPClient
        if(UnityInOn||UnityOutOn)
           if(UnityInOn)
               Unity_In_Data = TCPServer.UserData;
           end
           clear TCPServer
        end
    end
    
     %this sets the framerate to a fixed value. Make sure that this
     %frequency matches up with the code running on the Pi
     waitfor(frequencyControlObjectPi);   
    
end
%%%END OF MAIN SECTION. Probably you don't have to touch anything after
%%%this line


%clean up dummy variables at the end of the run
if(PiInOn)
    if(isfield(Pi_In_Data,'Dummy'))
        Pi_In_Data = rmfield(Pi_In_Data,'Dummy');
    end
end

if(PiOutOn)
    if(isfield(Pi_Out_Data,'Dummy'))
        Pi_Out_Data = rmfield(Pi_Out_Data,'Dummy');
    end
end

%this is the end of the control loop. Everything below is plotting and
%functions

%% Here the plotting starts

if print_plot==true

if(PiInOn)
    if(PiInHeader.StoringData==true)
    plotData(Pi_In_Data,PiInHeaderOrig,"Received from Pi");
    end
end

if(PiOutOn)
    if(PiOutHeader.StoringData==true)
    plotData(Pi_Out_Data,PiOutHeaderOrig,"Sent to Pi");
    end
end

if(PiInOn && PiOutOn)
     figure()
    hold on
    for id = 1: length(PiOutHeaderOrig.Variable)
            p1=plot([Pi_Out_Data(:).time],[Pi_Out_Data(:).(PiOutHeaderOrig.Variable(id))],'LineStyle','--');
    end
    for id = 1: length(PiInHeaderOrig.Variable)
            p2=plot([Pi_In_Data(:).time],[Pi_In_Data(:).(PiInHeaderOrig.Variable(id))],'LineStyle',':');
    end
    legend([p1,p2],["Desired","Measured"]);
    xlabel('Time [s]');
    if(PiOutHeader.Scaling=="Actuator")
        ylabel('Pressure normalized to actuator');
    elseif(PiOutHeader.Scaling=="KPa")
        ylabel('Pressure [KPa]');  
    elseif(PiOutHeader.Scaling=="None")
        ylabel('Pressure normalized to Pi');
    end
    title("Desired vs measured data");
end

if(PiInOn && PiOutOn)
figure()
hold on
p1=plot(PiBytesRead,'g:');
p2=plot(PiBytesWritten,'b:');
legend([p1,p2],{'Pi Bytes read','Pi bytes written'});
title('Bytes communicated')
end

end

%% Functions, probably no need to touch these ever, so you can fold this

function [PiInHeader,PiInHeaderOrig,PiOutHeader,PiOutHeaderOrig,Pressure,UnityInHeader,UnityOutHeader] = initializeStructs(PiInHeaderOrig,PiOutHeaderOrig,Pressure,UnityInHeader,UnityOutHeader)

% Copy PiHeaders to new variable, so we can add dummy variables while still
% keeping the original header order
PiInHeaderOrig.Scaling = Pressure.InScaling;
PiOutHeaderOrig.Scaling = Pressure.OutScaling;

PiInHeader = PiInHeaderOrig;
PiOutHeader = PiOutHeaderOrig;

%first set conversion rate for sensor data to ones, and then change this for VEAB sensor
%data later on
PiInHeader.InConversion = ones(1,length(PiInHeader.Variable));
PiInHeader.InConversion(PiInHeader.VEAB==1) = Pressure.InVEABConversion;

%figure out from PiOutHeader which pressure properties belong with which
%variables
Pressure.Variables = PiOutHeader.Variable(PiOutHeader.VEAB==1);

%%figure out if we need dummy on input or output side to account for 2
%%channels on VEAB boards
VEAB.InChannels = PiInHeader.Channel(PiInHeader.VEAB==1);
VEAB.InUnique = unique(VEAB.InChannels);

VEAB.nrInChannelsPerBoards = zeros(length(VEAB.InUnique),1);
VEAB.DummyOnInBoard = zeros(length(VEAB.InUnique),1);

for VIn = 1:length(VEAB.InUnique)
    VEAB.nrInChannelsPerBoards(VIn) = sum(VEAB.InChannels==VEAB.InUnique(VIn));
    
    if(VEAB.nrInChannelsPerBoards(VIn)==1)
        VEAB.DummyOnInBoard(VIn) = 1;
        VEAB.IndexDummy(VIn) = find(PiInHeader.Channel==VEAB.InUnique(VIn));
        PiInHeader.Variable = [PiInHeader.Variable(1:VEAB.IndexDummy(VIn)),"Dummy",PiInHeader.Variable(VEAB.IndexDummy(VIn)+1:end)];
        PiInHeader.Channel = [PiInHeader.Channel(1:VEAB.IndexDummy(VIn)),VEAB.InUnique(VIn),PiInHeader.Channel(VEAB.IndexDummy(VIn)+1:end)];
        PiInHeader.VEAB = [PiInHeader.VEAB(1:VEAB.IndexDummy(VIn)),1,PiInHeader.VEAB(VEAB.IndexDummy(VIn)+1:end)];
        PiInHeader.InConversion = [PiInHeader.InConversion(1:VEAB.IndexDummy(VIn)),Pressure.InVEABConversion,PiInHeader.InConversion(VEAB.IndexDummy(VIn)+1:end)];
    end

    if(VEAB.nrInChannelsPerBoards(VIn)>2)
        error("Too many VEAB input Channels on board %i",VEAB.nrInChannelsPerBoards(VIn));
    end
end

VEAB.OutChannels = PiOutHeader.Channel(PiOutHeader.VEAB==1);
VEAB.OutUnique = unique(VEAB.OutChannels);

VEAB.nrOutChannelsPerBoards = zeros(length(VEAB.OutUnique),1);
VEAB.DummyOnOutBoard = zeros(length(VEAB.OutUnique),1);

for VOut = 1:length(VEAB.OutUnique)
    VEAB.nrOutChannelsPerBoards(VOut) = sum(VEAB.OutChannels==VEAB.OutUnique(VOut));
    
    if(VEAB.nrOutChannelsPerBoards(VOut)==1)
        VEAB.DummyOnOutBoard(VOut) = 1;
        VEAB.IndexDummy(VOut) = find(PiOutHeader.Channel==VEAB.OutUnique(VOut));
        PiOutHeader.Variable = [PiOutHeader.Variable(1:VEAB.IndexDummy(VOut)),"Dummy",PiOutHeader.Variable(VEAB.IndexDummy(VOut)+1:end)];
        PiOutHeader.Channel = [PiOutHeader.Channel(1:VEAB.IndexDummy(VOut)),VEAB.OutUnique(VOut),PiOutHeader.Channel(VEAB.IndexDummy(VOut)+1:end)];
        PiOutHeader.VEAB = [PiOutHeader.VEAB(1:VEAB.IndexDummy(VOut)),1,PiOutHeader.VEAB(VEAB.IndexDummy(VOut)+1:end)];
        PiOutHeader.Baseline = [PiOutHeader.Baseline(1:VEAB.IndexDummy(VOut)),PiOutHeader.Baseline(VEAB.IndexDummy(VOut)),PiOutHeader.Baseline(VEAB.IndexDummy(VOut)+1:end)];
    end

    if(VEAB.nrOutChannelsPerBoards(VOut)>2)
        error("Too many VEAB output Channels on board %i",VEAB.nrOutChannelsPerBoards(VOut));
    end
end

%Initialization Unity variables
% UnityInHeader.UniqueIds=unique(UnityInHeader.Id,'stable');
% for u=1:length(UnityInHeader.UniqueIds)
%     UnityInHeader.UniqueIdNrs=sum(UnityInHeader.Id==UnityInHeader.UniqueIds(u));
% end
UnityInHeader.MessageLength = 8*length(UnityInHeader.Variable);

UnityOutHeader.UniqueIds=unique(UnityOutHeader.Id,'stable');
for u=1:length(UnityOutHeader.UniqueIds)
    UnityOutHeader.UniqueIdNrs=sum(UnityOutHeader.Id==UnityOutHeader.UniqueIds(u));
end
UnityOutHeader.MessageLength = 4 + 4*length(UnityOutHeader.UniqueIds) + 8*length(UnityOutHeader.Id);

%Some sanity checks to see if the input looks ok
if(length(Pressure.actuatorMin)~=length(Pressure.actuatorMax))
error("Length of the minimum and maximum actuator pressure does not match")
end

if(length(VEAB.OutChannels)~=length(Pressure.actuatorMin) || length(VEAB.OutChannels)~=length(Pressure.actuatorMax))
    error("Your VEAB output variables do not match the number of regulators.")
end

if~(length(PiInHeaderOrig.Variable)==length(PiInHeaderOrig.Channel) && length(PiInHeaderOrig.Channel)==length(PiInHeaderOrig.VEAB))
    error("Your PiInHeaderOrig variables do not all have the same length.")
end

% if~(length(UnityInHeader.Id)==length(UnityInHeader.Variable))
%     error("Your UnityInHeader variables do not all have the same length.")
% end

if~(length(UnityOutHeader.Id)==length(UnityOutHeader.Variable))
    error("Your UnityOutHeader variables do not all have the same length.")
end

end

function Data = InitializeArrays(Header)
    Data(1).time = [];
    counter = 1;
    for iN=1:length(Header.Variable)
            Data.(Header.Variable(counter))=[];
            counter = counter+1;
    end
end

function [DataStorage, BytesRead,PiInStarted] = ReadPiData(ServerObject, DataStorage, Header, BytesRead,Pressure,PiInStarted)          

    BytesRead = [BytesRead,ServerObject.NumBytesAvailable];

    if(ServerObject.NumBytesAvailable > 0)

        if(PiInStarted==false)
            %this is an attempt to get rid of the giant mountain of data
            %that is always waiting at the start. But it doesn't seem to
            %help :-)
            flush(ServerObject,"input");
            PiInStarted=true;
            return;
        else
            data_temp=read(ServerObject,ServerObject.NumBytesAvailable);
        end
        data_length = 8*length(Header.Variable);
        length_left = length(data_temp);
        
        %now we start processing because we have received at least 1 full packet
        flush(ServerObject,"input");                            %to start clean in the next loop and be prepared for sending data out 
        
        %this is the main loop for data processing
        while length_left > 0                       %chop up packets in case we have received more than 1
            
            %get correct index to start at
            if(Header.StoringData==true)
            index = length([DataStorage.time])+1; 
            else
            index = 1;
            end
            %index = length([DataStorage.time])+1;    
            data_temp_now = data_temp(1:data_length);
            DataStorage(index).time = toc; 
            currentPiLength = length(Header.Variable);
                  
                  for id=1:currentPiLength
                    
                        data_temp_now_mes = typecast(uint8(data_temp_now(8*(id-1)+1:8*id)),'double');
                        %go from voltage to proper scaling of sensor
                        %signals
                        data_temp_now_mes = data_temp_now_mes .* Header.InConversion(id);

                        if(Header.Variable(id)=="Dummy")
                           data_temp_now_normalized = NaN;
                        elseif(Header.VEAB(id)==1)
                            if(Pressure.InScaling == "Actuator")
                                data_temp_now_normalized = pressureToActuator(data_temp_now_mes,Pressure,id);
                            elseif(Pressure.InScaling == "KPa")
                                %TODO implement scaling to KPa
                                data_temp_now_normalized = pressureToKPa(data_temp_now_mes,Pressure);
                            elseif(Pressure.InScaling == "None")
                                data_temp_now_normalized = data_temp_now_mes;  
                            else
                                error("Incorrect option for Pressure.InScaling") 
                            end
                        else
                           data_temp_now_normalized = data_temp_now_mes;
                        end
                        DataStorage(index).(Header.Variable(id)) = data_temp_now_normalized;

                  end
                data_temp = data_temp(data_length+1:end); 
                length_left = length_left - (data_length);
        end
    
    end

end
 
function SetPiToBaseline(ServerObject,PiOutHeader)

    data_temp_now =zeros(1,length(PiOutHeader.Variable));

    for Id = 1:length(PiOutHeader.Variable)
        data_temp_now(Id) = PiOutHeader.Baseline(Id);
    end

    outToPi = data_temp_now;
    write(ServerObject,typecast(outToPi,'uint8'));
end

function [Pi_Out_Data,PiBytesWritten] = WritePiData(ServerObject, Pi_Out_Data, PiOutHeader,PiBytesWritten,Pressure)
       
    index = length([Pi_Out_Data.time]);
    %clean up Pi before sending out data
    %flush(ServerObject,"output");
    data_temp_now =zeros(1,length(PiOutHeader.Variable));  
     
    pressure_counter=1;
     for Id = 1:length(PiOutHeader.Variable)
            current_variable=PiOutHeader.Variable(Id);                        
            %if the variable is a dummy variable, we command it to send
            %0.5V
            if(current_variable=="Dummy")
                data_temp_now(Id) = 0.49;
            elseif(PiOutHeader.VEAB(Id)==1)
                data_before_scaling = Pi_Out_Data(index).(current_variable);
                %this converts your commanded signal to the proper input for the pi
                if(Pressure.OutScaling=="Actuator")
                    data_temp_now(Id) = actuatorToPi(data_before_scaling, Pressure,pressure_counter);
                elseif(Pressure.OutScaling=="KPa")
                    data_temp_now(Id) = KPaToPi(data_before_scaling, Pressure,pressure_counter);
                elseif(Pressure.OutScaling=="None")
                    data_temp_now(Id) = data_before_scaling;
                else
                    error("Incorrect option for Pressure.OutScaling") 
                end
                
                %check to make sure that input is between 0 and 1. If not, we
                %cut it down
                if(data_temp_now(Id)>1)
                    data_temp_now(Id) = 1;
                    disp('Data for variable %s is >1, resetting to 1',PiOutHeader.Variable(Id));
                end
                if(data_temp_now(Id)<0)
                    data_temp_now(Id) = 0;
                    disp('Data for variable %s is <0, resetting to 0',PiOutHeader.Variable(Id));
                end
                
                pressure_counter = pressure_counter+1;
            else
                %Here we could potentially add bounds on the non-VEAB
                %signals
                data_temp_now(Id) = Pi_Out_Data(index).(current_variable);
            end
            
            %easy line if we want to see the actual data that we send,
            %instead of scaled data
            %Pi_Out_Data(index).(current_variable) = data_temp_now(Id);
            
     end

    write(ServerObject,typecast(data_temp_now,'uint8'));
    PiBytesWritten(end+1) = ServerObject.NumBytesWritten - sum(PiBytesWritten) ;
end

function pressureToActuator = pressureToActuator(pressureFromPi, Pressure,sensorId)
    
    minToPi = (Pressure.actuatorMin(sensorId) - Pressure.regulatorMin(sensorId)) ./ (Pressure.regulatorMax(sensorId) - Pressure.regulatorMin(sensorId));
    maxToPi = (Pressure.actuatorMax(sensorId) - Pressure.regulatorMin(sensorId)) ./ (Pressure.regulatorMax(sensorId) - Pressure.regulatorMin(sensorId));
    pressureToActuator = (pressureFromPi - minToPi) ./ (maxToPi - minToPi);
    
end

function pressureToKPa = pressureToKPa(pressureFromPi,Pressure,id)
    
        RegulatorRange = Pressure.regulatorMax(id) - Pressure.regulatorMin(id);
        pressureToKPa = RegulatorRange.*pressureFromPi + Pressure.regulatorMin(id);
end

function actuatorToPi = actuatorToPi(pressureFromMatlab, Pressure,id)

        if(~isnan(pressureFromMatlab))
        minToPi = (Pressure.actuatorMin(id) - Pressure.regulatorMin(id)) ./ (Pressure.regulatorMax(id) - Pressure.regulatorMin(id));
        maxToPi = (Pressure.actuatorMax(id) - Pressure.regulatorMin(id)) ./ (Pressure.regulatorMax(id) - Pressure.regulatorMin(id));   
        actuatorToPi = minToPi + (maxToPi - minToPi).* pressureFromMatlab;
        else
            %if we see a NaN, this is a Dummy channel, and we want to send
            %0V to it
        actuatorToPi = 0.5;
        end

end

function KPaToPi = KPaToPi(pressureFromMatlab, Pressure,id)

        RegulatorRange = Pressure.regulatorMax(id) - Pressure.regulatorMin(id);

        if(~isnan(pressureFromMatlab))
        KPaToPi = pressureFromMatlab/RegulatorRange + 0.5;
        else
            %if we see a NaN, this is a Dummy channel, and we want to send
            %0V to it
        KPaToPi = 0.5;
        end

end

function readUnityData(src,Header)
       tempData = read(src, Header.MessageLength, "uint8");
       
       if(Header.StoringData==true)
           if(isfield(src.UserData,'time'))
               currentSize = length([src.UserData.time]);
           else
               currentSize = 0;
           end
       else
           currentSize = 0;
       end

       src.UserData(currentSize+1).time = toc;
       
%        %skip length message
%        start_now = 4;
%        counter = 1;
       for u=1:length(Header.Variable)
%            %skip id message 
%            start_now = start_now+4;
%             for l=1:Header.UniqueIdNrs(u)
                src.UserData(currentSize+1).(Header.Variable(u)) = typecast(uint8(tempData((u-1)*8+1:u*8)),'double');
%                 %move to next variable
%                 start_now = start_now + 8;
%                 counter = counter + 1;
       %     end
       end

 end

function plotData(Data,Header,label)

    figure()
    hold on
    for id = 1: length(Header.Variable)
            plot([Data(:).time],[Data(:).(Header.Variable(id))]);
    end
    legend(Header.Variable)
    xlabel('Time [s]');
    if(Header.Scaling=="Actuator")
        ylabel('Pressure normalized to actuator');
    elseif(Header.Scaling=="KPa")
        ylabel('Pressure [KPa]');  
    elseif(Header.Scaling=="None")
        ylabel('Pressure normalized to Pi');
    end
    title(label);

    mean_frequency = (length([Data.time])-2)./([Data(end).time]-[Data(3).time]);
    disp(strcat('Mean frequency ',label, ' is ',num2str(mean_frequency)));

end