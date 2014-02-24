function [ENVIR, MMS_CONST] = mms_init()
% MMS_INIT reads initial environment and constants for MMS FIELDS processing
% 	[ENVIR, MMS_CONST] = MMS_INIT() returns environment variables 
%       and constants useful for MMS processing.
%
%       The struct ENVIR will contain the following:
%	  .DATA_PATH_ROOT	  - Root dir of data files
%	  .CDF_BASE		  - Root dir of CDF tools
%	  .DROPBOX_ROOT		  - Root dir of our output files (temporary location)
%	  .LOG_PATH_ROOT	  - Root dir of log files
% 	  .CAL_PATH_ROOT	  - Root dir of calibration files
%
%	The struct MMS_CONST will contain the following:
%	  .Version.X		  - Major Software version used.
%		  .Y		  - Major Calibration version used.
%		  .Z		  - File version (should perhaps be removed).
%	  .Bitmask.OnlyDCE = 0x01 - Only DCE was found at these points in time. 
%
%	Example:
%		[ENVIR, MMS_CONST] = MMS_INIT();
%

ENVIR = [];
MMS_CONST = [];

% Version numbering, start with X, Y, Z = 0, 0, 0. When releasing new
% software update values here and subsequent output files created will have
% these numbers. 
% When simply re-running a dataset, the Z value should be increased by one.

MMS_CONST.Version.X = 0; % Major new Software version
MMS_CONST.Version.Y = 0; % New Calibration version
MMS_CONST.Version.Z = 0; % File revision, increased by 1 for each re-run.

% Bitmask constant values
MMS_CONST.Bitmask.OnlyDCE = 1; % Bits 0x01.

ENVIR.CDF_BASE = getenv('CDF_BASE'); % get environment variable.
ENVIR.DATA_PATH_ROOT = getenv('DATA_PATH_ROOT'); % Get path to data.
ENVIR.LOG_PATH_ROOT = getenv('LOG_PATH_ROOT'); % Get path to logs.
ENVIR.DROPBOX_ROOT = getenv('DROPBOX_ROOT'); % Get path to output location, (temporary location, other scripts then move it once fully written and our script is done). 
ENVIR.CAL_PATH_ROOT = getenv('CAL_PATH_ROOT'); % Get path to cal.

% Setup logging.
% Create a logfile at log_path_root, named after current run date and IRFU.log
irf.log('log_out',strcat(ENVIR.LOG_PATH_ROOT,'/',date,'_IRFU.log'));
% Set log level to debug initially.
irf.log('debug');

if(~exist('mms_sdc_cdfwrite.mexa64','file'))
    irf.log('warning','MMS_SDC_CDFWRITE.MEXA64 file does not exist. Building it.');
    
    % Set important CFLAGS and Includes here. Linking to the CDF_BASE cdf.h
    % and on the currect system built version of libcdf.so. If a local
    % version of mexopts.sh is set which does not link to Matlabs lib then
    % they must also be included here. (Version 7.11 of Matlab had this
    % issue).
    
    % Locate the path to source and output
    pathToINIT=which('mms_init');
    [s, filename, ext]=fileparts(pathToINIT);
    mex(['CFLAGS=-fPIC -fno-omit-frame-pointer -std=c99 -D_GNU_SOURCE -pthread -fexceptions'], ...
        ['-I',ENVIR.CDF_BASE,'/include/'] ,['-L',ENVIR.CDF_BASE,'/lib/'], ['-Wl,-rpath,',ENVIR.CDF_BASE,'/lib/'],...
        '-outdir',[s,'/'],'-lcdf', [s,'/mms_sdc_cdfwrite.c']);

%     % Another way would be to call on the external mex in bash. But this
%     require CFLAGS -std=c99 to be configured beforehand in mexopts.sh.
%     oldDir=pwd;
%     cd('irfu-matlab/mission/mms');
%     [status,cmdout]=unix([matlabroot,'/bin/mex -I$CDF_BASE/include/ -L$CDF_BASE/lib/ -Wl,-rpath,$CDF_BASE/lib/ -lcdf mms_sdc_cdfwrite.c']);
%     cd(oldDir);
end