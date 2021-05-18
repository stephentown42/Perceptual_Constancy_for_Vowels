function varargout = GoFerret(varargin)
% GOFERRET MATLAB code for GoFerret.fig
%      GOFERRET, by itself, creates a new GOFERRET or raises the existing
%      singleton*.
%
%      H = GOFERRET returns the handle to a new GOFERRET or the handle to
%      the existing singleton*.
%
%      GOFERRET('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GOFERRET.M with the given input arguments.
%
%      GOFERRET('Property','Value',...) creates a new GOFERRET or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before GoFerret_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to GoFerret_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help GoFerret

% Last Modified by GUIDE v2.5 07-Feb-2016 16:53:53

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GoFerret_OpeningFcn, ...
                   'gui_OutputFcn',  @GoFerret_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before GoFerret is made visible.
function GoFerret_OpeningFcn(hObject, ~, handles, varargin)
clearvars -global
handles.output = hObject;
guidata(hObject, handles);

 if isempty(whos('global','gf')) == 0,
     clear gf
 end

 global gf
 
 gf.defaultPaths = path;

% Load folder options
load_userList(handles)
load_subjectList(handles)



%%%%%%%%%%%%%%% 1/5 User selects directory for stage files %%%%%%%%%%%%%%%%

% Load available directories

function load_userList(handles)

    % home_dir directory
    % Please note that the home_dir directory is specific for each computer.
    % Adding GoFerret will require lines home_dir to be redefined (twice) below

    home_dir = strcat('C:\Users\',getenv('username'),'\Documents\MATLAB\Applications\GoFerret');

    % Check file path and prompt user if directory cannot be found. 
    % If user input is incorrect, an error will be generated.
    
    try
        cd (home_dir)
        addpath(home_dir)
        
    catch err
        
        if strcmp(err.identifier,'MATLAB:cd:NonExistentDirectory')
                        
            msgbox(sprintf('%s\n\n%s',...
                            'home directory cannot be found.',...
                            'Please enter directory manually in command window'),...
                   'Warning','warn')       
               
            home_dir = input('Please enter home directory as string: ');            
        end        
        
        rethrow(err)       
    end

    % Writes files from directory (home_dir) to left listbox
   
    dir_struct                  = lsDir(home_dir);
    [sorted_names,sorted_index] = sortrows({dir_struct.name}');
    handles.file_names          = sorted_names;
    handles.is_dir              = [dir_struct.isdir];
    handles.sorted_index        = sorted_index;
    
    guidata(handles.figure1,handles)
    set(handles.userList,   'String',handles.file_names,'Value',1)
    set(handles.userEdit,   'String',home_dir)
    
    
% Select task folder (e.g. ST_TimbreDiscrim)   
function userList_Callback(~,~,handles)                     %#ok<*DEFNU>
    
    global gf

    % Return to home_dir directory
    %  Redefine on new computers
    
    home_dir = strcat('C:\Users\',getenv('username'),'\Documents\MATLAB\Applications\GoFerret'); 
    cd(home_dir)
    
    dir_struct           = lsDir(home_dir);
    [~,sorted_index]     = sortrows({dir_struct.name}');    
    handles.is_dir       = [dir_struct.isdir];
    handles.sorted_index = sorted_index;

    % Open selected file and load filenames (m files only)
    index_selected  = get(handles.userList,'Value');
    file_list       = get(handles.userList,'String');
    filename        = file_list{index_selected};
    
    if  handles.is_dir(handles.sorted_index(index_selected))
        
        cd(filename)
        addpath(pwd)
        
        gf.directory = pwd;
        load_stageList(gf.directory, handles)
    end


% Load available stage files
function load_stageList(dir_path,handles)

    % Writes matlab files from stage directory (dir_path) to center listbox

    dir_path = strcat(dir_path,'\stages'); % Goes directly into stage file: could cause problems if GoFerret structure is not adhered to             
    cd(dir_path)
    
    dir_struct                  = dir('*.m'); % Matlab files only
    [sorted_names,sorted_index] = sortrows({dir_struct.name}');
    handles.file_names          = sorted_names;
    handles.is_dir              = [dir_struct.isdir];
    handles.sorted_index        = sorted_index;
    
    guidata(handles.figure1,handles)
    
    % Select first 
    set(handles.stageList,'String',handles.file_names,'Value',1)
    
    % Set edit box as selected file
    index_selected  = get(handles.stageList,'Value');
    file_list       = get(handles.stageList,'String');
    
    set(handles.stageEdit,'String',file_list{index_selected})
    
    % Enables default to first file without further user input
    global gf
    gf.filename = file_list{index_selected};
    gf.filename = gf.filename(1:length(gf.filename)-2); % Remove extension
    
    % Load Parameters list for default file
    load_parameterList(gf.directory,handles)
    
    
%%%%%%%%%%%%%%%%%%%%%%%% 2/5 Select stage file %%%%%%%%%%%%%%%%%%%%%%%%%%%%

function stageList_Callback(~, ~, handles)
  
    global gf

    index_selected  = get(handles.stageList,'Value');
    file_list       = get(handles.stageList,'String');
    gf.filename     = file_list{index_selected};
    
    %remove '.m' extension
    gf.filename     = gf.filename(1:length(gf.filename)-2);
    
    load_parameterList(gf.directory,handles)
   
    
    function load_parameterList(dir_path, handles)

    global gf    
        
    % Writes text files from parameters directory (dir_path) to right listbox
    
    dir_path = strcat(dir_path,'\parameters'); % Goes directly into stage file: could cause problems if GoFerret structure is not adhered to             
    cd(dir_path)
    
    dir_struct                  = dir(sprintf('%s*',gf.filename)); % all file names with the 'level #' prefix
    [sorted_names,sorted_index] = sortrows({dir_struct.name}');
    handles.file_names          = sorted_names;
    handles.is_dir              = [dir_struct.isdir];
    handles.sorted_index        = sorted_index;
    
    guidata(handles.figure1,handles)
    set(handles.parameterList,'String',handles.file_names,'Value',1)
    set(handles.parameterEdit,'String',pwd)
    
    % Select first file
    set(handles.parameterList,'String',handles.file_names,'Value',1)
    
    % Set edit box as selected file
    index_selected  = get(handles.parameterList,'Value');
    file_list       = get(handles.parameterList,'String');
    
    set(handles.parameterEdit,'String',file_list{index_selected})
    
    % Enables default to first file without further user input
    gf.paramFile = file_list{index_selected};
    

    

    
%%%%%%%%%%%%%%%%%%%%%%%% 3/5 Select parameter file %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function parameterList_Callback(~, ~, handles)

    global gf

    index_selected  = get(handles.parameterList,'Value');
    file_list       = get(handles.parameterList,'String');
    gf.paramFile    = file_list{index_selected};
    
        


%%%%%%%%%%%%%%%%%%%%%%%%%%% 4/5 Select subject %%%%%%%%%%%%%%%%%%%%%%%%%%

function load_subjectList(handles)

    save_dir = 'C:\Data\Behavior';
    
    dir_struct                  = lsDir(fullfile(save_dir,'F*'));
    [sorted_names,sorted_index] = sortrows({dir_struct.name}');
    handles.file_names          = sorted_names;
    handles.is_dir              = [dir_struct.isdir];
    handles.sorted_index        = sorted_index;
    
    guidata(handles.figure1,handles)
    
    set(handles.subjectList,'String',handles.file_names,'Value',1)
    
    % Set temporary as default
    set(handles.editSaveDir,'String',save_dir)
    set(handles.subjectEdit,'String','Temporary')  
    

function subjectList_Callback(~, ~, handles)    
    
    global gf
    
    index_selected  = get(handles.subjectList,'Value');
    file_list       = get(handles.subjectList,'String');
    gf.subjectDir   = file_list{index_selected};
    
    saveDir = fullfile('C:\Data\Behavior',gf.subjectDir);
    
    set(handles.editSaveDir,'String',saveDir)
    
    
function subjectEdit_Callback(~, ~, handles)
    
global gf
    
gf.subjectDir = get(handles.subjectEdit,'string');
save_dir      = fullfile('C:\Data\Behavior',gf.subjectDir);

if isdir(save_dir)
    set(handles.editSaveDir,'String',save_dir)
else
    msgbox('Subject is not valid - save directory not changed','Warning','warn')
end



%%%%%%%%%%%%%%%%% 5/5 Close interface and enter online GUI %%%%%%%%%%%%%%%%
function startH_Callback(~, ~, handles)

global gf

gf.saveDir  = get(handles.editSaveDir,'string');  
gf.calibDir = get(handles.calibDir,'string');  
gf.tankDir  = get(handles.tankDir,'string'); 

% Add directory and subfolders to path definition
addpath( genpath( gf.directory ))

close(handles.figure1)

parameters

       
    
% --- Outputs from this function are returned to the command line.
function varargout = GoFerret_OutputFcn(~, ~, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



%%%%%%%%%%%%%%%%%%%%%%%%% Browse functions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function browseSaveDir_Callback(~, ~, ~)

    path = uigetdir;


function userBrowse_Callback(~, ~, ~)

    path = uigetdir;

function stageBrowse_Callback(~, ~, ~)

    path = uigetdir;

function parameterBrowse_Callback(~, ~, ~)

    path = uigetdir;

function userEdit_Callback(~, ~, ~)
function userEdit_CreateFcn(~, ~, ~)
function stageEdit_Callback(~, ~, ~)
function stageEdit_CreateFcn(~, ~, ~)
function userList_CreateFcn(~, ~, ~)
function stageList_CreateFcn(~, ~, ~)
function parameterList_CreateFcn(~, ~, ~)
function editSaveDir_Callback(~, ~, ~)
function editSaveDir_CreateFcn(~, ~, ~)
function parameterEdit_Callback(~, ~, ~)
function parameterEdit_CreateFcn(~, ~, ~)
function subjectEdit_CreateFcn(~,~,~)  
function subjectList_CreateFcn(~,~,~)
function calibDir_Callback(~,~,~)
function calibDir_CreateFcn(~,~,~)
function tankDir_Callback(~,~,~)
function tankDir_CreateFcn(~,~,~)


% --- Executes on button press in flush.
function flush_Callback(hObject, eventdata, handles)
    
    
% Options
time = 10;  
    
% Establish connection with TDT 
DA = actxcontrol('TDevAcc.X');
DA.ConnectServer('Local');
DA.SetSysMode(2);
pause(3)

% Set time
invoke(DA,'SetTargetVal','RZ6.pulseThi',time*1e3)

% Trigger
tags = {'centerValve','leftValve','rightValve'};

for i = 1 : 3        
    invoke(DA,'SetTargetVal',sprintf('RZ6.%s', tags{i}),1)    
    invoke(DA,'SetTargetVal',sprintf('RZ6.%s', tags{i}),0)
    
    pause(time+1)
end
    
% Set device to idle 
DA.SetSysMode(0);

% Close connections and windows
DA.CloseConnection;
