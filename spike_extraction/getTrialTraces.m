function getTrialTraces(file_path, tank_path, save_path)
% function getTrialTraces(file_path, tank_path, save_path)
%
% Batch function for splitting neural recording files containing original data from n electrodes into chunks for cleaning
% Works on multiple recordings from multiple subjects (ferrets)
%
% Args:
%   file_path: directory containing files with timestamps in separate subdirectories for each ferret 
%
% Example:
%   function getTrialTraces()
%   function getTrialTraces('data\behavior\pitch')
%   function getTrialTraces('data\behavior\pitch', 'E:\Data\UCL_Behaving')
%   function getTrialTraces('data\behavior\pitch', 'E:\Data\UCL_Behaving', 'G:\Analysis\TrialTraces')
%
% Notes:
%   Files with timestamps are assumed to be text files of format found in this repository, but it should be easy to adapt for other file formats
%   
%
% Version History
%   2014: Created, Stephen Town
%   2022: Updated with documentation (ST)

%%% Input Handling
%
% If no input, select file path with timestamps - otherwise check input is correct
if nargin < 1
    file_path = uigetdir(pwd,'Select directory containing behavioral timestamps (organised in subfolders by ferret)');
else
    if ~isfolder(file_path)
        error('Could not find %s', file_path)
    end
end

% If no input, select tank directory - otherwise check input is correct
if nargin < 2
    tank_path = uigetdir(pwd,'Select directory containing tanks (not the tanks themselves)');
else
    if ~isfolder(tank_path)
        error('Could not find %s', tank_path)
    end
end

% If no input, select save directory - otherwise check input is correct
if nargin < 3
    save_path = uigetdir(pwd,'Where should output files be saved?');
else
    if ~isfolder(save_path)
        error('Could not find %s', save_path)
    end
end
    
% Create directory structure for passing paths to main function
dirs = struct('tanks', tank_path, 'save', save_path)


%%% Batch Organization
%
% Get list of ferrets
ferrets  = dir( fullfile( file_path, 'F*'));

% For each ferret
for j = length(ferrets) : -1 : 1,

    % List test sessions (note that each file name contains the relevant block in the tank)
    dirs.timestamps = fullfile(testPath, ferrets(j).name);
    files = dir( fullfile(dirs.timestamps, '*.txt'));
    
    % For each file, get trial trace            
    run_batch_for_ferret( dirs, files, ferrets(j).name);
end

cleanTrialTraces

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MAIN function
function run_batch_for_ferret(dirs, files, ferret)
% function run_batch_for_ferret(dirs, files, ferret)
%
% Works on multiple recordings from one subject (ferret)
%
% Args:
%   dirs: struct containing relevant paths for input data and output saving
%   files: struct containing names of files with timestamp data
%   ferret: string, name of ferret (e.g. F1201_Florence)
%
% Notes:
% This script assumes a specific recording configuration used in this project. 
% Specifically, every recording is stored in a block within a tank, and each 
% block contains two stores, one for neural recordings from left auditory 
% cortex (SU_2) and one for recordings from right auditory cortex (SU_3). Both
% stores are assumed to have 16 channels, and be independent. We also assume 
% a standard sample rate (24414 Hz), which is fixed for this project but may 
% be changed for different datasets.
%
% Offset: The timestamps in the behavioral files are the times at which a trial
% was initiated by an animal. However, we want to center the trial traces around
% the time of stimulus onset. In this project, there was a constant delay between
% these two timepoints (0.5 seconds) but this may vary if adapting the code for
% other uses.
%

% Check tank exists for this ferret
tank = fullfile(dirs.tank, ferret);
if ~isdir(tank), 
    warning('%s directory not found', tank);
    return
end

% Connect to TDT (do this once and keep connection open for all blocks)   
TTfig = figure('visible','off');
TT = actxcontrol('TTank.X'); 
TT.ConnectServer('Local','Me'); 
TT.OpenTank(tank , 'R' );   % R-Read, W-Write, C-Control, M-Monitor    

% Parameters for reading data
fRec = 24414.0625;
nChan = 32;    
store = [repmat('SU_2',16,1); repmat('SU_3',16,1)];
chans = repmat(transpose(1:16), 2, 1);

% Parameters for processing data
padTime  = [0, 0];
padSamps = padTime .* fRec;
offset   = 0.5;

% Try to run extraction
try

% For each recording block
for i = length(files) : -1 : 1,
            
    % Import behavioral data containing timestamps for trials
    fprintf('Extracting trial traces for %s\n', files(i).name)
    bdata = readtable(fullfile( filepath, files(i).name),'VariableNamingRule','preserve');
    
    % Check that input data has the appropriate column names (change this code if adapting for new input data)
    if ~any(strcmp(t.Properties.VariableNames, 'StartTime'))
        error('Cannot identify trial start time variable (maybe look at input data fields)')
    end
        
    if ~any(strcmp(t.Properties.VariableNames, 'RespTime'))
        error('Cannot identify response time variable (maybe look at input data fields)')
    end
    
        
    % Extract response times
    R  = bdata.RespTime;
    
    % Deal with cases where no response was made (code = -1)
    if all(R==-1), continue; end
    
    while R(end) == -1,
        bdata.data(end,:) = [];
        R  = bdata.RespTime;
    end
        
    % Get stimulus onset times (S) and response times (R)
    S = bdata.data(:, strcmp(bdata.colheaders, 'StartTime'));
    S  = S - offset;                    % Convert trial start into stimulus onset
    R  = bdata.data(:, strcmp(bdata.colheaders, 'RespTime'));
    
    % Calculate length of trials and intervals between trials (iti)
    iti    = S - circshift(R,1);      % Time between stimulus and previous response
    iti(1) = 2;                       % First ITI doesn't exist
    iti    = [iti; 2];                % Last ITI doesn't exist
    iti(iti>3) = 3;                   % Limit analysis between trials to maximum of 3 seconds
    iti_HW = iti ./ 2;                % Half width of iti
    
    % Calculate midpoints between trials (M)
    M = [];
    M(:,1) = S - iti_HW(1:end-1);           % Start time
    M(:,2) = R + iti_HW(2:end);             % End time
    
    % Convert M to samples (Ms)
    Ms = round( M.*fRec);
    
    % Calculate number of samples within window
    nMax = fRec .* (R(end)+2) ./ 2048;%ceil( diff(Ms,[],2) ./ 2048);
    nTrials = length(S);
    
    % Get block number
    fileName = regexprep( files(i).name,'.txt','');
    spaceSep = strfind(fileName,' ');
    block    = fileName(spaceSep(end)+1:end);
    
    if ~TT.SelectBlock( block),
        warning('Could not open %s %s',tank,block);
        continue
    end    
    
    %  Save workspace
    saveName  = fullfile(saveDir, strcat(fileName,'.mat'));
    
    if exist(saveName,'file'), continue; end
    
    % Get trace data for each channel    
    trialTraces = cell(nTrials, nChan);
    count = 0;
    h     = waitbar(0, fileName);
    
    for j = 1 : nChan,
        
        % Extract trace
        x  = [];
        ev = [];
        ev = TT.ReadEventsV(nMax, store(j,:), chans(j), 0, 0, 0, 'ALL');
        x  = TT.ParseEvV(0, ev);     % Matrix: N columns = N events; Q points = Q rows
        x  = reshape(x, numel(x), 1);
        
        if ev        
            
            % Check length
            if length(x)/24414.0625 < max(M(:,2))
               warning('\t Skipping %s - chan %02d', fileName, j)
               continue
            end
            
            % Filter for samples of interest
            for k = 1 : nTrials,
                trialTraces{k,j} = x(Ms(k,1):Ms(k,2));
            end
        end
        
        count = count + 1;
        waitbar((count/(nChan)), h, sprintf('%s',fileName))
    end
    
    
    waitbar(1,h, 'Saving...');
    save( saveName, 'bdata','trialTraces','M','-v7.3');
    clear bdata trialTraces M
    close(h)
end

TT.CloseTank 
TT.ReleaseServer 
close(TTfig)

catch err
    
    err
    TT.CloseTank 
    TT.ReleaseServer 
    close(TTfig)
    keyboard
end