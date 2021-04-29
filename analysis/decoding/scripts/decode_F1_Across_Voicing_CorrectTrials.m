function decode_F1_Across_Voicing_CorrectTrials
%
% Modified from decode_F1_vs_F0_ErrorTest_Optimized ST: 10th May 2018
% Modified from decode_F1_Across_F0_ErrorTrials ST: 11th May 2018


try 
    
% Define paths
dirs.root   = Cloudstation('Vowels\Perceptual_Constancy\Voicing');
dirs.ephys  = fullfile(dirs.root,'Ephys');
dirs.psth   = fullfile(dirs.ephys,'PSTHs');
dirs.decode = fullfile( dirs.root, 'Decoding\Results\2Way_Comparisons_excGolay_matched');
dirs.save   = fullfile(dirs.decode,'F1_Across_Voicing_ErrorTrials');

if ~isdir(dirs.save), mkdir(dirs.save); end

% Load data set
filename = 'PSTHs_15-Jan-17_12-55-39.mat';
load( fullfile(dirs.ephys, filename))

% Start log file
logName = sprintf('Log_%s.txt',datestr(now,'yy-mm-dd_HH-MM-SS'));
log = fopen( fullfile(dirs.ephys, logName),'wt+');

% Options
options.startTimes = -0.5 : 0.05 : 1;
options.durations  = 0.01 : 0.01 : 0.5;
options.BW         = 0.01;
options.nIteration = 0;


% For each ferret
for ferret = 1 : numel(S)
    
    F = S(ferret);
    
    % For each channel
    parfor chan = 1 : 32
        
        nDepths = numel(F.chan(chan).depths);
        fid = fopen( fullfile(dirs.ephys, logName),'a+');
        
        % For each depth
        for depth = 1 : nDepths
   
            % Get subset of data
            T     = F.chan(chan).site(depth);
            fName = sprintf('%s_C%02d_%.3fmm', F.ID,chan,T.depth); 
            
            % Skip if already done
            savePath = fullfile(dirs.save, [fName '_correct.mat']);
            
%             if exist(savePath, 'file')
%                 fprintf(fid,'%s exists - skipping\n', fName);
%                 continue
%             end            
            
            % Skip if no data            
            if ~isfield(T,'Filename')
                fprintf(fid,'No data found for %s\n', fName); 
                continue
            end
            
            if isempty(T.Filename)
                fprintf(fid,'No blocks found for %s\n', fName); 
                continue
            end            
            
            % Update user
            fprintf(fid,'Processing %s\n', fName);
            
            % Decode
            main(T, options, savePath);
            
        end
        
        fclose(fid);
    end
end

fclose(log);

catch err
    err
    keyboard
end
   


function main(T, opt, savePath)

try

    % Concatenate data across blocks
    F1      = cell2mat(transpose(T.F1));
    Voice   = cell2mat(transpose(T.Voicing));
    nHist   = cell2mat(transpose(T.nHist));
    Correct = cell2mat(transpose(T.Correct));
        
    nHistEdges = round(opt.nHistEdges,2);

    % Filter for correct trials
    errIdx = Correct == 1;
    nHist  = nHist(errIdx, :);
    Voice  = Voice(errIdx);    
    F1     = F1(errIdx);    
    
    % Return if there were not enough trials
    if numel(F1) < 2, return; end
    
    
    % Select minimum number of trials
    [nF1s, opt.F1s,  opt.nF1s] = nUnique(F1);
    minTrials = min(opt.nF1s);
    vIdx = [];
    
    % For each vowel       
    for i = 1 : nF1s
        
        temp_idx = find(F1 == opt.F1s(i));
        temp_idx = temp_idx( randperm(opt.nF1s(i), minTrials));
        vIdx = [vIdx temp_idx];
    end
    
    % Filter for match index
    nHist  = nHist(vIdx(:), :);
    Voice  = Voice(vIdx(:));    
    F1     = F1(vIdx(:));    
        
    % Note the range of f0s across which we're testing
    [~, opt.F1s, opt.nF1s] = nUnique(F1);
    [~, opt.Voices, opt.nVoices] = nUnique(Voice);
    
    % Shuffle trial IDs
    nTrials = numel(F1);
    F1 = [F1 nan(nTrials, opt.nIteration)];
    
    for i = 1 : opt.nIteration
        
        shuffleIdx = randperm(nTrials);
        F1(:,i+1)    = F1(shuffleIdx(:));
    end    
    
    % Set up result grid
    nDur = numel(opt.durations);
    nSTs = numel(opt.startTimes);
    
    vowel_pCorrect = nan(nDur, nSTs, opt.nIteration+1);
    kount = 0;
    
    % For each duration
    for i = 1 : nDur
        
        % For each start time
        for j = 1: nSTs
            
            % Resample PSTH
            startIdx = find( nHistEdges == round(opt.startTimes(j),2));
            endIdx   = find( nHistEdges == round(opt.startTimes(j)+opt.durations(i),2)) - 1;   % -1 to avoid the extra bin
            
            ij_Hist = nHist(:,startIdx:endIdx);
            
            for k = 1 : opt.nIteration+1
                
                % Update user
                kount    = kount + 1;
                
                % Run decoder
                vowel_pCorrect(i,j,k) = myDecode(ij_Hist, F1(:,k));
            end
        end
    end
    
    % Save
    save(savePath,'opt','vowel_pCorrect')

catch err
    err
    keyboard
end



function pCorrect = myDecode(EA, stateList)

try    
    
% draw = false;

% Get numbers
[nTrial, nTime]  = size(EA);
[nState, States, ~] = nUnique(stateList);

decodeState = nan(nTrial, 1);
masterTemplates = nan(nState, nTime);
n = nan(nState,1);

% Generate master templates
for i = 1 : nState
    masterTemplates(i,:) = mean( EA(stateList == States(i),:));
    n(i) = sum(stateList == States(i));
end

% For each trial
for trial = 1 : nTrial

    % Generate adjusted templates
    trialPSTH = EA(trial,:);
    trialState = stateList(trial);
    trialStateIdx = States == trialState;
    
    adjustedTemplate = masterTemplates;
    adjustedTemplate(trialStateIdx,:) = adjustedTemplate(trialStateIdx,:) .* n(trialStateIdx);  % Recover sum
    adjustedTemplate(trialStateIdx,:) = adjustedTemplate(trialStateIdx,:)  - trialPSTH; % Take away test trial
    adjustedTemplate(trialStateIdx,:) = adjustedTemplate(trialStateIdx,:) ./ (n(trialStateIdx)-1);  % Return to mean
    
    % Get distances
    dist = bsxfun(@minus, adjustedTemplate, trialPSTH);
    dist = sum(abs(dist), 2);
    pIdx = find(dist == nanmin(dist));
    
    if numel(pIdx) == 1
        decodeState(trial) = States(pIdx);    % Identity by maximum p
    else
        decodeState(trial) = States( randperm(nState,1)); % Guess if all p vlaues = 0
    end
end

% Calculate % correct
correct  = bsxfun(@eq, decodeState, stateList);
pCorrect = mean(correct) * 100;
% fprintf('%.1f%% Correct\n', pCorrect)



% Draw out
% if draw
%     figure;
%     ax(1) = axes('nextPlot','add');
%     hs(1) = scatter(timeAx, p(1,:),'r');
%     hs(2) = scatter(timeAx, p(2,:),'b');
%     xlabel('Time (s)')
%     ylabel('p(H|D)')
%     legend(hs,{'H1','H2'})
%     
%     ax(2) = axes('position',ax(1).Position);
%     
%     plot(timeAx, EA(trial,:),'k','parent',ax(2))
%     
%     set(ax(2),'color','none','yaxislocation','right');
%     ylabel('Firing Rate (Hz)')
% end

catch err
    err         %#ok<*NOPRT>
    keyboard
end

