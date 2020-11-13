function [parameterList,phoenixProtocol] = xASL_bids_PhoenixProtocolReader(pathData,bUseDCMTK)
%xASL_bids_PhoenixProtocolReader Function that reads raw DICOM data and extracts the phoenix protocol parameters.
%
% FORMAT: [parameterList,phoenixProtocol] = xASL_bids_PhoenixProtocolReader(pathData,bUseDCMTK);
%
% INPUT:
%        pathData           - path to DICOM dataset (REQUIRED)
%        bUseDCMTK          - use DCMTK toolbox to get the phoenix protocol (OPTIONAL, DEFAULT: true)
%
% OUTPUT:
%        parameterList      - list of parameters from the reduced phoenix protocol
%        phoenixProtocol    - cell array containing the phoenix protocol
%
% -----------------------------------------------------------------------------------------------------------------------------------------------------
% DESCRIPTION:      Function that reads raw DICOM data and extracts the phoenix protocol parameters.
%                   Only works for Siemens DICOM data with phoenix protocol (tag = [0x29,0x1020]).
%
% -----------------------------------------------------------------------------------------------------------------------------------------------------
%
% EXAMPLE:          pathData = '...\test-data';
%                   [parameterList,phoenixProtocol] = xASL_bids_PhoenixProtocolReader(pathData,true);
%
% REFERENCES:       ...
% __________________________________
% Copyright @ 2015-2020 ExploreASL


    %% Input Check
    
    % Check number of input parameters
    if nargin < 1
        error('Missing input parameters...');
    end

    % Check bUseDCMTK
    if nargin < 2
        bUseDCMTK = true;
    end

    % Check if the input path is a character array or a string
    if ~(ischar(pathData) || isstring(pathData))
        error('Input path is neither a char array not a string...');
    end
    
    % Get file parts
    [filePath,fileName,fileExtension] = fileparts(pathData);
    
    % Check extension
    if ~strcmp(fileExtension,'.dcm')
        error('Input path is not a DICOM file...');
    end

    %% Defaults
    
    debug = false;
    parameterList = {'Name','Value'};
    startOfProtocol = '### ASCCONV BEGIN';
    endOfProtocol = '### ASCCONV END';

    %% Read Phoenix Protocol
    if bUseDCMTK
        headerDCMTK = xASL_io_DcmtkRead(pathData);
        phoenixProtocol = headerDCMTK.PhoenixProtocol;
        phoenixProtocol = [strsplit(phoenixProtocol,'\n')]';
    else
        py.importlib.import_module('pydicom');
        ds = py.pydicom.dcmread(pathData,false,true);
        phoenixProtocol = char(ds{2691104}.value); % 2691104 = (0x29,0x1020)
        phoenixProtocol = [strsplit(phoenixProtocol,'\\n')]';
    end
    
    % Remove tabs
    for line=1:numel(phoenixProtocol)
        phoenixProtocol{line,1} = strrep(phoenixProtocol{line,1},'\t','');
    end
    

    %% Extract parameters
    
    parIterator = 2;
    protocolStarted = false;
    protocolEnded = false;
    
    % Iterate over phoenix protocol
    for line=1:numel(phoenixProtocol)
        
        % Current line
        curLine = string(phoenixProtocol{line,1});
        
        % Print current line in debug mode
        if debug
            fprintf('%s\n',string(phoenixProtocol(line,1)));
        end
        
        % Check if protocol ended
        if curLine.contains(endOfProtocol)
            protocolEnded = true;
        end
        
        % Export parameter
        if (protocolStarted && ~protocolEnded)
            % Extraction
            extrLine = char(curLine);
            % Search for equals sign
            posInLine = strfind(curLine, ' = ');
            % Get key and value
            keyLine = extrLine(1:posInLine-1);
            valLine = extrLine(posInLine+3:end);
            % Assign them to the parameter list
            parameterList{parIterator,1} = keyLine;
            parameterList{parIterator,2} = valLine;
            parIterator = parIterator+1;
        end
        
        % Check if protocol started
        if curLine.contains(startOfProtocol)
            protocolStarted = true;
        end
        
    end
    


end






