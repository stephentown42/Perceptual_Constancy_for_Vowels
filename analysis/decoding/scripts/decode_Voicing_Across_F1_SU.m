function decode_Voicing_Across_F1_SU(filename)

try 

% Define paths
rootDir = Cloudstation('Vowels\Perceptual_Constancy\Voicing');

% Load data set
if nargin == 0
    filename = 'PSTHs_SU_20-Nov-17_16-27-05.mat';
end
load( fullfile(rootDir,'Ephys', filename))

% Save directory
saveDir = fullfile(rootDir,'Decoding\Results\2Way_Comparisons_excGolay_matched\Voicing_Across_F1_SU');

if ~isdir(saveDir), mkdir(saveDir); end

% Options
options.startTimes = -0.5 : 0.05 : 1;
options.durations  = 0.01 : 0.01 : 0.5;
options.BW         = 0.01;
options.nIteration = 100;

% Start log file
logName = sprintf('Log_%s.txt',datestr(now,'yy-mm-dd_HH-MM-SS'));
log = fopen( fullfile(rootDir, logName),'wt+');

% For each ferret
for ferret = 1 : numel(S)
    
    F = S(ferret);
    
    % For each channel
    for chan = 1 : 32        
        
        nDepths = numel(F.chan(chan).depths);
        fid = fopen( fullfile(rootDir, logName),'a+');
        
        % For each depth
        for depth = 1 : nDepths
   
            % Get subset of data
            T     = F.chan(chan).site(depth);
            fName = sprintf('%s_C%02d_%.3fmm', F.ID,chan,T.depth); 
            
            % Skip if already done
            savePath = fullfile(saveDir, [fName '.mat']);
            
            if exist(savePath, 'file')
                fprintf(fid,'%s exists - skipping\n', fName);
                continue
            end  
            
            % Skip if no data            
            if ~isfield(T,'Filename')
                fprintf(fid, 'No data found for %s\n', fName); 
                continue
            end
            
            if isempty(T.Filename)
                fprintf(fid, 'No blocks found for %s\n', fName); 
                continue
            end            
                                          
            % Update user
            fprintf(fid,'Processing %s\n', fName);
            
            % Draw
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
    
% Set up result grid
nDur = numel(opt.durations);
nSTs = numel(opt.startTimes);

voicing_pCorrect = nan(nDur, nSTs, opt.nIteration+1);
    
% Concatenate data across blocks
F1      = cell2mat(transpose(T.F1));
Voicing = cell2mat(transpose(T.Voicing));
nHist   = cell2mat(transpose(T.nHist));
nHistEdges = round(opt.nHistEdges,2);

% Match stimulus probabilities by taking the voiced stimulus before
% whispered stimulus
whispIdx  = find(Voicing == 0);
voicedIdx = whispIdx - 1;

if voicedIdx(1) == 0, voicedIdx(1) = whispIdx(1)+1; end % Correct if first stim was whispered

% Compensate for consecutive trials
nRep = sum(ismember(whispIdx, voicedIdx));

if nRep > 0
    allVoiced = find(Voicing == 1);
    unusedVoiced = setdiff(allVoiced, voicedIdx);
    unusedVoiced = unusedVoiced(1:nRep);    % JUst take the first n instances
    
    voicedIdx = [voicedIdx; unusedVoiced];
end

% Apply filter
trialIdx = unique([voicedIdx; whispIdx]);
F1       = F1(trialIdx);
Voicing  = Voicing(trialIdx);
nHist    = nHist(trialIdx,:);


% Note the range of f0s across which we're testing
[~, opt.Voicing, opt.nVoicing] = nUnique(Voicing);
[~, opt.F1s, opt.nF1s] = nUnique(F1);

% Shuffle trial IDs
nTrials = numel(F1);

for i = 1 : opt.nIteration   
    
    shuffleIdx = randperm(nTrials);
%     F1         = [F1 F1(shuffleIdx(:))]; 
    Voicing   = [Voicing Voicing(shuffleIdx(:))]; 
end

% Set up waitbar
% nPoints = nDur * nSTs * (opt.nIteration+1);
% wh = waitbar(0,'Starting');
% kount = 0;

% For each duration
for i = 1 : nDur   
    
    % For each start time
    for j = 1: nSTs
                
        % Resample PSTH             
        startIdx = find( nHistEdges == round(opt.startTimes(j),2));
        endIdx   = find( nHistEdges == round(opt.startTimes(j)+opt.durations(i),2)) - 1;   % -1 to avoid the extra bin
        
        ij_Hist = nHist(:,startIdx:endIdx);                
                  
        for k = 1 : opt.nIteration+1
        
%             % Update user
%             kount    = kount + 1;
%             progress = kount/nPoints;
%             waitbar(progress, wh, sprintf('%.1f Complete', progress*100) )        
        
            % Run decoder
%             vowel_pCorrect(i,j,k) = myDecode(ij_Hist, F1(:,k));
            voicing_pCorrect(i,j,k) = myDecode(ij_Hist, Voicing(:,k));
        end
    end
end

% close(wh)

% Draw result
% f = figure('units','centimeters','Position',[8 2 28 13]);
% subplot(121)
% hold on
% drawmap(opt.startTimes, opt.durations, vowel_pCorrect)
% title('Vowel')
% 
% subplot(122)
% hold on
% drawmap(opt.startTimes, opt.durations, space_pCorrect)
% title('Space')



% Save
save(savePath,'opt','voicing_pCorrect')

catch err
    err
    keyboard
end


function pCorrect = myDecode(EA, stateList)

try    
    
draw = false;

% Get numbers
[nTrial, nTime]  = size(EA);
[nState, States, ~] = nUnique(stateList);

decodeState = nan(nTrial, 1);
pH          = nan(nState, nTime);

% Generate master templates
for i = 1 : nState
    masterTemplates(i,:) = mean( EA(stateList == States(i),:),1);
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
if draw
    figure;
    ax(1) = axes('nextPlot','add');
    hs(1) = scatter(timeAx, p(1,:),'r');
    hs(2) = scatter(timeAx, p(2,:),'b');
    xlabel('Time (s)')
    ylabel('p(H|D)')
    legend(hs,{'H1','H2'})
    
    ax(2) = axes('position',ax(1).Position);
    
    plot(timeAx, EA(trial,:),'k','parent',ax(2))
    
    set(ax(2),'color','none','yaxislocation','right');
    ylabel('Firing Rate (Hz)')
end

catch err
    err
    keyboard
end


function drawmap(x,y,z)

colormap('jet')
surf(x,y,z,'EdgeColor','none')
ylabel('Duration (s)')
xlabel('Start Time (s)')
set(gca,'ydir','normal','clim',[0 100])
view([0 90])
ylabel(colorbar,'% Correct')
axis tight

