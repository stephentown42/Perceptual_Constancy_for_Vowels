function cleanTrialTraces(file_path, save_path)
% function cleanTrialTraces(file_path, save_path)
%
% Clean chunks of high-pass neural activity recorded on multiple channel
%
% Args:
%   file_path: directory containing trial trace files (.mat) with chunked data
%   save_path: directory in which to save cleaned data
%
% Returns:
%   Saves .mat files containing cleaned data
%
% Version History:
%   2014: Created by Stephen Town
%   2022: Updated for GitHub by ST


%%% Input Handling
%
% If no input, select directory containing trial trace files
if nargin < 1
    file_path = uigetdir(pwd, 'Please select directory with trial traces');
end

if nargin < 2
    save_path = uigetdir(pwd, 'Please select directory to save clean traces');
end

% Channels for analysis
SU2_chans = 1:16;
SU3_chans = 17:32;
chans     = [SU2_chans' SU3_chans'];

%%% Main loop
%
% For each file containing trial traces
files = dir( fullfile( file_path, '*.mat'));
for i = 1 : length(files)
    
    % Path names
    filename = files(i).name;
    saveName = fullfile(save_path, filename);
    
    saveNameL = regexprep(saveName,'.mat','_SU2.mat');
    saveNameR = regexprep(saveName,'.mat','_SU3.mat');
    
    % Skip if data extracted
    if exist(saveNameL,'file') && exist(saveNameR,'file'),
        continue
    end
    
    % Load trialTrace data
    load( fullfile( file_path, filename))
    
    % Set constants and arrays
    nTrials = size(trialTraces,1);                                              %#ok<*NODEF>
    
    % Preassign clean trials
    cleanTrials_SU2 = cell(nTrials, 1);
    cleanTrials_SU3 = cell(nTrials, 1);
    
    % Transpose so that every row is a channel and every column a trial
    trialTraces = transpose(trialTraces);
    
    % Clean data for each trial
    try
        
        h  = waitbar(0, filename);
        
        for j = 1 : nTrials
            
            waitbar((j/nTrials), h, sprintf('%s',filename))
            
            % Arrange input
            tdata = cell2mat(trialTraces(:,j));
            tdata = transpose(tdata);
            [~, nChan] = size(tdata);
            
%             % Bug fix for aborted trials
%             if ~isempty(tdata)
%                 
%                 % Remove empty channels
%                 for k = nChan : -1 : 1,
%                     if isempty(tdata{k}),
%                         tdata(k) = [];
%                     end
%                 end
%                 
%                 % Reorganize tdata
%                 nChan = size(tdata,1);
%                 tdata = cell2mat(tdata);
%                 tdata = reshape(tdata, nSamp, nChan);
%             end
            
            if ~isempty(tdata)
                % Select channels and clean data
                SU2_data = tdata(:, SU2_chans);
                SU2_clean = CleanData(double(SU2_data), 0);
                cleanTrials_SU2{j} = single(SU2_clean(:,1:length(SU2_chans)));    % Send voltages but not principle components to array
                
                % Select channels and clean data
                if nChan > 16,
                    SU3_data = tdata(:, SU3_chans);
                    SU3_clean = CleanData(double(SU3_data), 0);
                    cleanTrials_SU3{j} = single(SU3_clean(:,1:length(SU3_chans)));         % Send voltages but not principle components to array
                end
            end
        end
        
        % Check output sizes
        if size(M,1) ~= size(cleanTrials_SU2,1)
            warning('output does not match input')
        end
        
        
        % Save data
        waitbar(1,h, 'Saving...');
        save(saveNameL,'cleanTrials_SU2','T','M', 'chans','-v7.3')
        save(saveNameR,'cleanTrials_SU3','T','M', 'chans','-v7.3')
        clear trialTraces T cleanTrials cleanTrials_SU2 cleanTrials_SU3
        close(h)
        
    catch err
        err
        keyboard
    end
end

