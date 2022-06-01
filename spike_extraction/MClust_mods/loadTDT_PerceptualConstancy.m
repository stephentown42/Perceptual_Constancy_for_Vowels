function [varargout] = loadTDT_PerceptualConstancy(file, timeRange, type)
% [t,wv] = myLoadingEngine(‘myfile.dat’, 1:10, 2) 
%
%
% File: .mat file containing 
%           ts - an n-element vector of ts for a tetrode set
%           wvs  - an n x 4 x 32 matrix containing the wvs of
%                        each event for four channels, each with 32 points
%           
%
% timeRange: returns events within a vector input 
% 
% type: 
%     1.	implies that records_to_get is a t list.  
%     2.	implies that records_to_get  is a record number list 
%     3.	implies that records_to_get  is range of ts (a vector with 2 elements: a start and an end t)
%     4.	implies that records_to_get  is a range of records (a vector with 2 elements: a start and an end record number)
%     5.	asks to return the count of spikes (records_to_get should be [] in this case)
%
% t: list of ts
% w: n x 4 x 32 wvs

try

    % Get data
%     load(file,'wv','unique_t');
    load(file,'wv','t');

    % Make sure that data are formatted correctly
%     t = unique_t; clear unique_t
    t = reshape(t, numel(t),1);
    
    if size(wv,3) == 1
        wv = repmat(wv, 1, 1, 4);
        wv = permute(wv,[1,3,2]);
    end
        
    
    % Case arguments
    if exist('type','var'),

        switch type

            % Time range is a vector of ts
            case 1

                if exist('timeRange','var'),     

                    idxs = find( bsxfun(@eq, t, timeRange'));
                    t    = t(idxs);
                    wv   = wv(idxs,:,:);                
                end

                varargout{1} = t;
                varargout{2} = wv;

            % Time range is a vector of indices 
            case 2

                if exist('timeRange','var'),   
                    t  = t(timeRange);
                    wv = wv(timeRange,:,:);                      
                end

                varargout{1} = t;
                varargout{2} = wv;


            % Filter by time range if variable exists
            case 3 

                if exist('timeRange','var'),                

                    start = findnearest( min(timeRange), t, 1);
                    stop  = findnearest( max(timeRange), t, -1);

                    % Check for valid time range
                    if isempty(start) || isempty(stop),
                        warning('Time range does not overlap with times of spikes')
                        return
                    end

                    t  = t(start : stop);
                    wv = wv(start : stop,:,:);
                end

                varargout{1} = t;
                varargout{2} = wv;


            % Filter by index    
            case 4
                if exist('timeRange','var'),                            
                    t  = t( min(timeRange):max(timeRange));
                    wv = wv( min(timeRange):max(timeRange),:,:);
                end

                varargout{1} = t;
                varargout{2} = wv;

            % Result number of spikes    
            case 5
                varargout{1} = length(t);
        end

    else
        varargout{1} = t;
        varargout{2} = wv;    
    end
    
catch err
    err
    keyboard
end