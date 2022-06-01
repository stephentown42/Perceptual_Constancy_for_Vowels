function getTrialTraces_FRA

% Define paths
filepath = 'C:\Analysis\Behavior';
tankDir  = 'D:\UCL Behaving';

% List ferrets
ferrets = dir( fullfile(filepath,'F*'));

% Open Connect to TDT
% global TT
% TT = actxcontrol('TTank.X'); 
% TT.ConnectServer('Local','Me'); 

% Run program for each ferret
for i = 1 : length(ferrets)
    
    % Extend paths
    bPath = fullfile(filepath, ferrets(i).name);
    tank  = fullfile(tankDir,  ferrets(i).name); 
    
    % Get session files
    files = dir( fullfile( filepath, ferrets(i).name, '*.mat'));
    
    % Run main extraction
    main(tank, bPath, files)    
end
% 
% % Close tank
% TT.CloseTank 
% TT.ReleaseServer 

% Clean
cleanTrialTraces


function main(tank, filepath, files)

global TT

% Save directory
saveDir = 'C:\Analysis\Trial_Traces';

% Open tank
% if ~TT.OpenTank(tank , 'R' ) 
%     warning('%s directory not found', tank); return
% end 

% Define parameters
fRec     = 24414.0625;
nChan    = 32;    
store    = [repmat('SU_2',16,1); repmat('SU_3',16,1)];
chans    = repmat((1:16)',2,1);
offset   = 0.1;

% Try to run extraction
try

    % For each session
    for i = 1 : length(files)

        % Skip if already completed
        saveName = fullfile(saveDir, files(i).name);
        if exist(saveName,'file'), continue; end
        
        % Get block number
        block = strfind( files(i).name, 'Block');
        block = files(i).name(block:end-4);
        
        % Load neural data
        SU2 = TDT2mat(tank, block,'STORE','SU_2');
        SU3 = TDT2mat(tank, block,'STORE','SU_3');
        
        % Get data from structure
        SU2 = SU2.streams.SU_2.data;
        SU3 = SU3.streams.SU_3.data;
        
        % Load behavioral data
        load( fullfile( filepath, files(i).name),'T');     

        % Get stimulus onset times (S) and response times (R)        
        S  = T.StartTime - offset;                    % Convert trial start into stimulus onset
        R  = circshift(S, -1);

        % Calculate length of trials and intervals between trials (iti)
        iti        = R-S;      % Time between stimulus and previous response
        iti        = [0.9; iti];
        iti(end)   = 0.9;                       % First ITI doesn't exist
        iti(iti>3) = 3;                   % Limit analysis between trials to maximum of 3 seconds
        iti_HW     = iti ./ 2;                % Half width of iti

        % Calculate midpoints between trials (M)
        M = [];
        M(:,1) = S - iti_HW(1:end-1);           % Start time
        M(:,2) = S + iti_HW(2:end);                % End time

        % Convert M to samples (Ms)
        Ms = round( M.*fRec);

        % Calculate number of samples within window
        nTrials     = length(S);        
        trialTraces = cell(nTrials, 2);

        % Filter for samples of interest
        for k = 1 : nTrials
            trialTraces{k,1} = SU2(:,Ms(k,1):Ms(k,2));            
            trialTraces{k,2} = SU3(:,Ms(k,1):Ms(k,2));
        end

        % Save trial traces and tidy work space
        save( saveName, 'T','trialTraces','M','-v7.3');            
    end


catch err
    
    err
    TT.CloseTank 
    TT.ReleaseServer 
    keyboard
end