function [ outFileName ] = mms_sdc_sdp_cdf_writing( HeaderInfo )
% MMS_SDC_SDP_CDF_WRITING writes the data to the corresponding CDF file.
%
%	filename_output = MMS_SDC_SDP_CDF_WRITING( HeaderInfo)
%   will write an MMS CDF file containing the data stored to a temporary 
%   output folder defined by ENVIR.DROPBOX_ROOT. HeaderInfo contains start 
%   time as well as information about source files ("Parents").
%
%   Example:
%   filename_output = mms_sdc_sdp_cdf_writing( HeaderInfo);
%
%	Note 1: It is assumed that other SDC processing scripts will move the
%   created output file to its final destination (from /ENIVR.DROPBOX_ROOT/
%   to /path/as/defined/by/	SDC Developer Guide, v1.7).
%
% 	See also MMS_SDC_SDP_CDF_IN_PROCESS, MMS_SDC_SDP_INIT.

% Verify that we have all information requried.
narginchk(1,1);

global ENVIR;
global MMS_CONST; if isempty(MMS_CONST), MMS_CONST = mms_constants(); end
global DATAC; % Simply recall all data from memory.

instrumentId = 'sdp';
scId = DATAC.scId;
procId = DATAC.procId; procName =  MMS_CONST.SDCProcs{procId};

% NOTE MOVE TO DROPBOX FOLDER BEFORE TRYING TO WRITE ANYTHING AS
% CDF MAY TRY TO WRITE TEMPORARY FILES IN THE CURRENT WORKING
% DIRECTORY WHEN EXECUTING.
oldDir = pwd; cd(ENVIR.DROPBOX_ROOT);
outFileName = get_file_name();
irf.log('notice',['Writing to DROPBOX_ROOT/',outFileName,'.cdf']);

switch procId
  case {MMS_CONST.SDCProc.sitl, MMS_CONST.SDCProc.ql}
    %% FIXME: DUMMY DATA FOR NOW.
    % For now store data temporarly
    epochTT = DATAC.dce.time;
    data1(:,1) = DATAC.dce.e12.data;
    data1(:,2) = DATAC.dce.e34.data;
    data1(:,3) = DATAC.dce.e56.data;
    bitmask = DATAC.dce.e12.bitmask;
    
    if procId==MMS_CONST.SDCProc.sitl
      % No QUALITY for SITL
      mms_sdc_sdp_cdfwrite( outFileName, int8(scId), procName, epochTT, ...
        data1, data1, uint16(bitmask) );
    else
      mms_sdc_sdp_cdfwrite( outFileName, int8(scId), procName, epochTT, ...
        data1, data1, uint16(bitmask), ...
        uint16(mms_sdc_sdp_bitmask2quality('e',bitmask)) );
    end
  case MMS_CONST.SDCProc.usc
    %% FIXME: DUMMY DATA FOR NOW.
    % For now store data temporarly
    epochTT = DATAC.dcv.time;
    psp_p(:,1) = DATAC.dcv.v1.data;
    psp_p(:,2) = DATAC.dcv.v2.data;
    psp_p(:,3) = DATAC.dcv.v3.data;
    psp_p(:,4) = DATAC.dcv.v4.data;
    psp_p(:,5) = DATAC.dcv.v5.data;
    psp_p(:,6) = DATAC.dcv.v6.data;
    bitmask = DATAC.dcv.v1.bitmask;
    ESCP = DATAC.dcv.v1.data;
    PSP = DATAC.dcv.v2.data;
    Delta = DATAC.dcv.v3.data;
    
    mms_sdc_sdp_cdfwrite( outFileName, int8(scId), procName, epochTT, ...
      ESCP, PSP, Delta, psp_p, uint16(bitmask) );  
  otherwise
    errStr = 'unrecognized procId';
    irf.log('critical', errStr); error(errStr)
end

% Update some of the global parameters that are not static.

% Generation date is today (when script runs).
GATTRIB.Generation_date = {0, 'CDF_CHAR', datestr(now,'yyyymmdd')};

% Data version is the version number. Version number should be "X.Y.Z"
GATTRIB.Data_version = {0, 'CDF_CHAR', verStr};

% FIXME: ADD Generated by as gitversion of software.
irfVersion = irf('version');
GATTRIB.Generated_by = {0, 'CDF_CHAR',irfVersion};

% Parents is the source file logical id, if multiple sources add subsequent
% entries for each source file. 
% Multiple.Parents={0, 'CDF_CHAR', [['CDF>',source1CDF.GloablAttributes.Logigal_file_id{1,1}]; ['CDF>',source2CDF.GloablAttributes.Logigal_file_id{1,1}]]}
%GATTRIB.Parents = {0, 'CDF_CHAR', ['CDF>',dataOut.GlobalAttributes.Logical_file_id{1,1}]};


if(HeaderInfo.numberOfSources == 1)
    GATTRIB.Parents = {0, 'CDF_CHAR', ['CDF>',HeaderInfo.parents_1]};
elseif(HeaderInfo.numberOfSources == 2)
    diffLength = length(HeaderInfo.parents_1)-length(HeaderInfo.parents_2);
    if(diffLength>0)
        GATTRIB.Parents = {0, 'CDF_CHAR', [['CDF>',HeaderInfo.parents_1]; ['CDF>',HeaderInfo.parents_2, blanks(diffLength)]]};
    elseif(diffLength<0)
        GATTRIB.Parents = {0, 'CDF_CHAR', [['CDF>',HeaderInfo.parents_1, blanks(abs(diffLength))]; ['CDF>',HeaderInfo.parents_2]]};
    else
        GATTRIB.Parents = {0, 'CDF_CHAR', [['CDF>',HeaderInfo.parents_1]; ['CDF>',HeaderInfo.parents_2]]};
    end
end

% Update all the new values to GlobalAttributes
irf.log('debug','MATLAB:mms_sdc_sdp_cdf_writing:UpdatingGlobalAttributes');
cdfupdate(outFileName,'GlobalAttributes',GATTRIB);

% Return to previous working directory.
cd(oldDir);

  function fileName = get_file_name
    % Generate output file name incrementing the file version if necessary
    
    switch procId
      case {MMS_CONST.SDCProc.sitl, MMS_CONST.SDCProc.ql}
        subDir = procName; suf = 'dce2d';
      case MMS_CONST.SDCProc.usc
        subDir = 'l2'; suf = 'uscdcv';
      otherwise
        errStr = 'unrecognized procId';
        irf.log('critical', errStr); error(errStr)
    end
    scIdStr = sprintf('mms%d',scId);
    tmMode = DATAC.tmMode; tmModeStr = MMS_CONST.TmModes{tmMode};
    startTime =  HeaderInfo.startTime;
    verStr = sprintf('%d.%d.',MMS_CONST.Version.X,MMS_CONST.Version.Y);
    fileName = [scIdStr '_' instrumentId, '_' tmModeStr '_' subDir '_' ...
      suf '_' startTime '_v' ];
    
    % Check for preexisting files and increment file version
    dataPathPref = [ENVIR.DATA_PATH_ROOT, filesep,'science',filesep, ...
      scIdStr, filesep, instrumentId, filesep, tmModeStr, filesep, ...
      subDir, filesep, startTime(1:4), filesep, startTime(5:6), filesep];
    if tmMode ~= MMS_CONST.TmMode.srvy
      dataPathPref = [dataPathPref,startTime(7:8), filesep];
    end
    
    preExistingFiles = dir([dataPathPref fileName verStr '*.cdf']);
    if numel(preExistingFiles)
      maxRev = 0;
      for iFile = 1:numel(preExistingFiles)
        rev = get_rev(preExistingFiles(iFile).name);
        if rev>maxRev, maxRev = rev; end
      end
      newVer = maxRev + 1;
    else newVer = 0;
    end
    verStr = [verStr num2str(newVer)];
    fileName = [fileName verStr];
    
    function r = get_rev(s)
      % Find revision (Z) from version string in a file name xxx_vX.Y.Z.cdf
      idxDot = find(s=='.');
      if numel(idxDot)~=3
        irf.log('warning',['Bad file name: ' s])
        r = 0; return
      end
      r = str2double(s(idxDot(2)+1:idxDot(3)-1));
    end % GET_REV
  end % get_file_name
end
