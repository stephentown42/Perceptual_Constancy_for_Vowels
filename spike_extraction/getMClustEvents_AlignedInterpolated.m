function getMClustEvents_AlignedInterpolated(file_path, save_path)
% function getMClustEvents_AlignedInterpolated(file_path, save_path)
%
% Get candidate events for spike sorting from cleaned neural data
%
% Args:
%   file_path: directory containing cleaned activity in .mat files
%   save_path: directory in which to output files

%
% Version History:
%   2014: Created by Stephen Town
%   2022: Updated docs for GitHub (ST) 


%%% Input Handling
%
% If no input, select file path with timestamps - otherwise check input is correct
if nargin < 1
    file_path = uigetdir(pwd,'Select directory containing cleaned neural data');
else
    if ~isfolder(file_path)
        error('Could not find %s', file_path)
    end
end

% If no input, select save directory - otherwise check input is correct
if nargin < 2
    save_path = uigetdir(pwd,'Where should MClust events be saved?');
else
    if ~isfolder(save_path)
        error('Could not find %s', save_path)
    end
end


% List files to extract file times from
files = dir( fullfile( file_path, '*.mat'));

% Check there are actually some files to analyze
if isempty(files)
    error('Could not find any files in %s', file_path)
end

% Fixed parameters
fRec = 24414.0625;
wInt = 1;
interpFactor = 4;

interpInt  = wInt / interpFactor; 
window     = -15 : wInt : 16;
interpWind = -15 : interpInt  : 16;

nW = numel(window)+1;               % These are regardless of method (interpolated or not)
alignmentZero = find(window == 0);


try
    
    for i = 1 : length(files)
        
        % Check for existing files
        saveDir = fullfile( save_path, regexprep(files(i).name,'.mat','_ev'));

        if isdir(saveDir), continue;
        else mkdir(saveDir)
        end
        
        tag = [];
        
        % Load cleaned data for each file
        % (Note that each file represents one hemisphere
        filename = fullfile( file_path, files(i).name);
        load( filename)
        
        % Assign tag based on contents
        if exist('cleanTrials_SU2','var'), tag = 'cleanTrials_SU2'; end
        if exist('cleanTrials_SU3','var'), tag = 'cleanTrials_SU3'; end
        if exist('trialTraces','var'),     tag = 'trialTraces';     end
        
        if isempty(tag),
            warning('Could not detect cleanTrialsR or cleanTrialsL - invalid file')
        end
        
        % Rename variable
        eval( sprintf('data = %s;', tag))
        eval( sprintf('clear %s', tag))
        
        % Preassign
        nTrials  = length(data);  %#ok<*USENS>
        ev_times   = cell( nTrials, 16);
        waveforms  = cell( nTrials, 16);
        
        % For each trial
        for j = 1 : size(M, 1),
            
            % Trial start time
            startTime = M(j, 1);
            
            % Select the data on all channels for that trial
            trialData = data{j};    % This is inefficient but whatever
            
            % Deal with aborted trials
            if ~isempty(trialData),
                
                % For each channel (This needs to be vectorized)
                for k = 1 : 16
                    
                    % Identify threshold crossings
                    trace = transpose(trialData(:,k));                    
                    threshold = std(single(trace));
                    
                    lb = min([-20 -2.5 * threshold]);
                    ub = min([-100 -6 * threshold]);
                    
                    % Identify thrshold crossings
                    lcIdx = find(trace < lb);
                    ucIdx = find(trace < ub);
                                                            
                    % Remove events exceeding the upper threshold                    
                    lcIdx = setdiff(lcIdx, ucIdx);                                   %#ok<*FNDSB>
                          
                    % Move to next trial if no events were found
                    if isempty(lcIdx); continue; end
                    
                    % Identify crossing points in samples
                    crossThreshold = lcIdx([0 diff(lcIdx)]~=1);
                    
                    % Remove events where window cannot fit
                    crossThreshold(crossThreshold < nW) = [];
                    crossThreshold(crossThreshold > (length(trace)-nW)) = [];
                    
                    % Make row vector
                    if iscolumn(crossThreshold),
                        crossThreshold = transpose(crossThreshold);
                    end
                    
                    % Get interim waveforms
                    wvIdx = bsxfun(@plus, transpose(crossThreshold), window);
                    wv    = trace(wvIdx);
                    
                    % Move to next trial if no waveforms are valid
                    if isempty(wv); continue; end
                                        
                    % Interpolate waveforms
                    wv = spline(window, wv, interpWind);
                    
                    % Align events
                    [~, peakIdx] = min(wv,[],2); 
                    peakIdx = round(peakIdx / interpFactor);     % Return interpolated peakIdx to original sample rate
                    alignmentShift = transpose(peakIdx) - alignmentZero;
                    alignedCrossings = crossThreshold + alignmentShift;
                    
                    % Reset events where window cannot fit (i.e. do not
                    % throw away, just include without alignment)
                    alignedCrossings(alignedCrossings < nW) = crossThreshold(alignedCrossings < nW);                     
                    alignedCrossings(alignedCrossings > (length(trace)-nW)) = crossThreshold(alignedCrossings > (length(trace)-nW));
                    
                    % Make row vector
                    if iscolumn(alignedCrossings),
                        alignedCrossings = transpose(alignedCrossings);
                    end
                    
                    % Get event times and waveforms
                    ev_t   = crossThreshold ./ fRec;   % Keep event times as the actual threshold crossing
                    wvIdx  = bsxfun(@plus, transpose(alignedCrossings), window); % But sample aligned waveforms
                    wv     = trace(wvIdx);
                                        
                    % Interpolate waveforms
                    wv = spline(window, wv, interpWind);
                    
                    % Remove waveforms with any point over upper bound
                    ev_t( any( wv<ub, 2))  = [];
                    wv( any( wv<ub, 2), :)  = [];
                    ev_t( any( wv>-ub, 2)) = [];
                    wv( any( wv>-ub, 2), :) = [];                                        
                                       
                    % Send to structure
                    ev_times{j,k}  = ev_t + startTime;
                    waveforms{j,k} = wv;
                end
            end
        end
        
        % For each channel
        for j = 1 : 16,
                        
            % Remove empty cells
            for k = size(ev_times,1) : -1 : 1,
                
                if isempty(waveforms{k,j}),
                    ev_times{k,j} = 0;
                    waveforms{k,j} = single(zeros(1,size(wv,2)));   % Note this will give an error if wv is empty or undefined (probably on first trial) - to fix, change size(wv,2) to length(window) or length(interpWind) depending on method
                end
            end
            
            t   = cell2mat(transpose(ev_times(:,j)));
            wv  = cell2mat(waveforms(:,j));
            
            % Save data
            saveName = fullfile( saveDir, sprintf('Chan_%02d.mat',j));
            save( saveName, 't', 'wv')            
        end
    end
    
catch err
    
    err
    keyboard
    
end