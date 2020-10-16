function [x] = xASL_quant_SliceReadoutTime_ShortestTR(x)
%xASL_quant_SliceReadoutTime_ShortestTR Calculate SliceReadoutTime for shortest TR
%
% FORMAT: [x] = xASL_quant_SliceReadoutTime_ShortestTR(x)
%
% INPUT:
%   x     - struct containing pipeline environment parameters (REQUIRED)
% OUTPUT:
%   x     - struct containing pipeline environment parameters (REQUIRED)
% -----------------------------------------------------------------------------------------------------------------------------------------------------
% DESCRIPTION: When the TR is set to "shortestTR" in the ASL acquisition,
%              each ASL scan will have its unique TR. As this is shortest,
%              there won't be a delay between the readout of the last slice
%              and the end of the TR. Therefore, the time to read out all
%              slices is TR - InitialPostLabelDelay - LabelingDuration, and
%              dividing this by the number of slices gives the
%              SliceReadoutTime
%
% -----------------------------------------------------------------------------------------------------------------------------------------------------
% EXAMPLE: x = xASL_quant_SliceReadoutTime_ShortestTR(x);
% __________________________________
% Copyright 2015-2020 ExploreASL


    %% ---------------------------------------------------
    %% Admin
    if ~isfield(x, 'Q')
        error('x.Q field missing');
    elseif ~isfield(x.Q, 'SliceReadoutTime')
        error('x.Q.SliceReadoutTime missing');
    end

    %% ---------------------------------------------------
    %% Compute SliceReadoutTime in case of shortest TR
    if ~isnumeric(x.Q.SliceReadoutTime) && strcmpi(x.Q.SliceReadoutTime,'shortestTR')
        % Load ASL parms
        ASL_parms = xASL_adm_LoadParms(x.P.Path_ASL4D_parms_mat, x);

        if isfield(ASL_parms,'RepetitionTime')
            %  Load original file to get nSlices
            nSlices = size(xASL_io_Nifti2Im(x.P.Path_ASL4D),3);
            x.Q.SliceReadoutTime = (ASL_parms.RepetitionTime-x.Q.LabelingDuration-x.Q.Initial_PLD)/nSlices;
        else
            warning('ASL_parms.RepetitionTime expected but did not exist!');
        end
    end

    %% ---------------------------------------------------
    %% Check output
    if isnan(x.Q.SliceReadoutTime)
        error('qnt_PLDslicereadout expected but was NaN');
    elseif min(x.Q.SliceReadoutTime)<5 || max(x.Q.SliceReadoutTime)>400
        warning(['qnt_PLDslicereadout=' num2str(x.Q.SliceReadoutTime) ' is outside of its valid range 5-400 ms']);
    end

end
