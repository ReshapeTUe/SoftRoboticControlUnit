classdef Veab < matlab.System & coder.ExternalDependency
    %
    % System object template for a sink block.
    % 
    % This template includes most, but not all, possible properties,
    % attributes, and methods that you can implement for a System object in
    % Simulink.
    %
    % NOTE: When renaming the class name Sink, the file name and
    % constructor name must be updated to use the class name.
    %
    
    % Copyright 2016-2018 The MathWorks, Inc.
    %#codegen
    %#ok<*EMCA>
    
    properties
        % Public, tunable properties.
    end
    
    properties (Nontunable)
        i2cbus (1, 1) {mustBePositive, mustBeInteger} = 1
        resolution (1, 1) =  0.002578125
       
    end
    
    properties (Access = private)
        % Pre-computed constants.
    end
    
    methods
        % Constructor
        function obj = Veab(varargin)
            % Support name-value pair arguments when constructing the object.
            setProperties(obj,nargin,varargin{:});
        end
    end
    
    methods (Access=protected)
        function setupImpl(obj) %#ok<MANU>
            if isempty(coder.target)
                % Place simulation setup code here
            else
                % Call C-function implementing device initialization
                % coder.cinclude('sink.h');
                coder.ceval('setupAdc', cast(obj.i2cbus,"uint8"));
            end
        end
        
        function [in1, in2, in3, in4] = stepImpl(obj, out1, out2, out3, out4)  
            %y= [double(0), double(0), double(0), double(0)];
            in1 = double(0);
            in2 = double(0);
            in3 = double(0);
            in4 = double(0);
            s = double(0);
            if isempty(coder.target)
                % Place simulation output code here 
            else
                % Call C-function implementing device output
                %coder.ceval('sink_output',u);

                %s = coder.ceval('getVeab', cast(obj.i2cbus,"uint8"), cast(1,"uint8"), double(obj.resolution));
                %in1 =  cast(s,"double") / 1000;
                %s = coder.ceval('getVeab', cast(obj.i2cbus,"uint8"), cast(2,"uint8"), double(obj.resolution));
                %in2 =  cast(s,"double") / 1000;
                %s = coder.ceval('getVeab', cast(obj.i2cbus,"uint8"), cast(3,"uint8"), double(obj.resolution));
                %in3 =  cast(s,"double") / 1000;
                %s = coder.ceval('getVeab', cast(obj.i2cbus,"uint8"), cast(4,"uint8"), double(obj.resolution));
                %in4 =  cast(s,"double") / 1000;

                coder.ceval('getAllVeab', cast(obj.i2cbus,"uint8"), double(obj.resolution), coder.wref(in1), coder.wref(in2), coder.wref(in3), coder.wref(in4));

                 %coder.ceval('setVeab', cast(obj.i2cbus,"uint8"), cast(1,"uint8"), single(out1), double(obj.resolution));
                 %coder.ceval('setVeab', cast(obj.i2cbus,"uint8"), cast(2,"uint8"), single(out2), double(obj.resolution));
                 %coder.ceval('setVeab', cast(obj.i2cbus,"uint8"), cast(3,"uint8"), single(out3), double(obj.resolution));
                 %coder.ceval('setVeab', cast(obj.i2cbus,"uint8"), cast(4,"uint8"), single(out4), double(obj.resolution));

                 coder.ceval('setAllVeab', cast(obj.i2cbus,"uint8"), cast(4,"uint8"), single(out1), single(out2), single(out3), single(out4), double(obj.resolution));

                 

                %coder.ceval('setVeab', cast(obj.i2cbus,"uint8"), cast(obj.channel,"uint8"), single(u), double(obj.resolution));
            end
        end
        
        function releaseImpl(obj) %#ok<MANU>
            if isempty(coder.target)
                % Place simulation termination code here
            else
                % Call C-function implementing device termination
                %coder.ceval('sink_terminate');
            end
        end
    end
    
    methods (Access=protected)
        %% Define input properties
        function num = getNumInputsImpl(~)
            num = 4;
        end
        
        function num = getNumOutputsImpl(~)
            num = 4;
        end
        
        function flag = isInputSizeMutableImpl(~,~)
            flag = false;
        end
        
        function flag = isInputComplexityMutableImpl(~,~)
            flag = false;
        end
        
        function validateInputsImpl(~, u)
            if isempty(coder.target)
                % Run input validation only in Simulation
                validateattributes(u,{'double'},{'scalar'},'','u');
            end
        end
        
        function icon = getIconImpl(~)
            % Define a string as the icon for the System block in Simulink.
            icon = 'Veab';
        end
    end
    
    methods (Static, Access=protected)
        function simMode = getSimulateUsingImpl(~)
            simMode = 'Interpreted execution';
        end
        
        function isVisible = showSimulateUsingImpl
            isVisible = false;
        end
    end
    
    methods (Static)
        function name = getDescriptiveName()
            name = 'Veab';
        end
        
        function b = isSupportedContext(context)
            b = context.isCodeGenTarget('rtw');
        end
        
        function updateBuildInfo(buildInfo, context)
            if context.isCodeGenTarget('rtw')
                % Update buildInfo
                srcDir = fullfile(fileparts(mfilename('fullpath')),'src');
                includeDir = fullfile(fileparts(mfilename('fullpath')),'include');
                addIncludePaths(buildInfo,includeDir);
                % Use the following API's to add include files, sources and
                % linker flags
                addIncludeFiles(buildInfo,'veab.h',includeDir);
                addSourceFiles(buildInfo,'veab.cpp',srcDir);
                %addLinkFlags(buildInfo,{'-lSource'});
                %addLinkObjects(buildInfo,'sourcelib.a',srcDir);
                %addCompileFlags(buildInfo,{'-D_DEBUG=1'});
                %addDefines(buildInfo,'MY_DEFINE_1')
            end
        end
    end
end
