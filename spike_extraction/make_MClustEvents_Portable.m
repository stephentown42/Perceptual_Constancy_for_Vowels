function make_MClustEvents_Portable

% Define paths
dirs.source = 'C:\Analysis\MClust Events AlignedInterpolated';
dirs.target = 'E:\Portable MClust Events AlignedInterpolated';

% Get session directories
sessions = dir( fullfile(dirs.source,'*'));

% For each file
for i = 1 : numel(sessions)
   
    % Extend paths
    dirs.session.source = fullfile( dirs.source, sessions(i).name);
    dirs.session.target = fullfile( dirs.target, sessions(i).name);
    
    % Check if target file exists       
%     if isdir( dirs.target_file)
%         keyboard
%     else
        mkdir(dirs.session.target)
%     end
    
    % List waveform files
    files = dir( fullfile(dirs.session.source,'*.mat'));
    
    % For each file
    for j = 1 : numel(files)
        
        % Preassign to keep it tidy
        t = [];
        
        % Load only spike times
        load( fullfile(dirs.session.source, files(j).name),'t')
        
        % Save spike times
        save( fullfile(dirs.session.target, files(j).name),'t')
    end   
end

