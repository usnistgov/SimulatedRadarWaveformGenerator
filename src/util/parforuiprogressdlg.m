classdef parforuiprogressdlg
% parforuiprogressdlg: ui progress bar for parfor with appdesigner 
% requires uifigure input as parent figure
%   progBar = parforuiprogressdlg(uiFig, title,numOfIter,progMsg)
%   creates ui progress bar with numOfIter iterations
%   A temporary file in tempdir is used to communicate among threads.

%
%   progBar.iterate(X) updates the progress bar by X iterations.
%
%   Example:
%   --------
%      uiFig=uifigure; %
%      numOfIter=20; %number of iterations
%      title='Processing'; %dialog title
%      progMsg='Working on:'; %dialog message 
%      progBar =parforuiprogressdlg(uiFig, title,numOfIter,progMsg)  %create the uiprogressbar
%     parfor i=1:numOfIter,
%         pause(rand);       
%         progBar.iterate(1);  % increase iteration
%     end
%
%   Derived from parfor_progressbar Copyright (c) 2016, Daniel Terry All rights reserved
%   https://www.mathworks.com/matlabcentral/fileexchange/53773-parfor-progressbar
%
%   See also: uiprogressdlg, uifigure, parfor.

% Public properties
properties (SetAccess=protected, GetAccess=public)
    progBar;       % uiprogressdlg, requires uifigure
    numOfIter;     % Total number of iterations
    iterMessage;   % message displayed with progressbar, format [this.iterMessage, '%d out of %d']  
end

properties (Dependent, GetAccess=public)
    value;  % current iteration value
end


% Internal properties
properties (SetAccess=protected, GetAccess=protected, Hidden)
    tempFile;  % Path to temporary file for inter-process communication
    hTimer;   % Timer object that checks tempFile for completed iterations
end



methods
    %========================  CONSTRUCTOR  ========================%
    function this = parforuiprogressdlg(uiFig, title,numOfIter,iterMessage)
    % Construct uiprogress bar with numOfIter iterations
        % Create a unique inter-process communication file.
       for i=1:10
            f = sprintf('%s%d.txt', mfilename, round(rand*1000));
            this.tempFile = fullfile(tempdir, f);
           if ~exist(this.tempFile,'file'), break; end
       end

        if exist(this.tempFile,'file')
            error('Too many temporary files. Clear out tempdir.');
        end
    
        %Creates a new ui progress bar
        this.numOfIter = numOfIter;
        this.iterMessage=iterMessage;
        this.progBar = uiprogressdlg(uiFig,'Title',title,...
            'Message','1','Cancelable','off');
        
        % Create timer to periodically update the waitbar in the GUI thread.
        this.hTimer = timer( 'ExecutionMode','fixedSpacing', 'Period',0.2, ...
                             'BusyMode','drop', 'Name',mfilename, ...
                             'TimerFcn',@(~,~)this.tupdate() );
        start(this.hTimer);
    end    
    
    %=========================  DESTRUCTOR  ========================%
    function delete(this)
        this.close();
    end
    
    function close(this)
    % Closer the progress bar and clean up internal state.
    
        % Stop the timer
        if isa(this.hTimer,'timer') && isvalid(this.hTimer)
            stop(this.hTimer);
            pause(0.01);
            delete(this.hTimer);
        end
        this.hTimer = [];
        
        % Delete the IPC file.
        if exist(this.tempFile,'file')
            delete(this.tempFile);
        end
        
        % Close the progBar

            close(this.progBar);

        this.progBar = [];
    end
    
    
    %======================  GET/SET METHODS  ======================%
    function value = get.value(this)
        % Read current number of iterations from tempFile
        if ~exist(this.tempFile, 'file')
            value = 0;  % File may not exist before the first iteration
        else
            fid = fopen( this.tempFile, 'r' );
            value = sum(fscanf(fid, '%d')) ; 
            fclose(fid);
        end
    end
    
    

    function iterate(this, iterStep)
    % Update the progress bar by iterStep iterations, set default iterStep=1
        if nargin<2,  iterStep = 1;  end
    
        fid = fopen(this.tempFile, 'a');
        fprintf(fid, '%d\n', iterStep);
        fclose(fid);
    end
    
    
end %public methods



%=====================  INTERNAL METHODS  =====================%
methods (Access=protected, Hidden)
    
    
    function tupdate(this)
    % Check the IPC file and update the progressbar and its message
    val=this.value;
    numIter=this.numOfIter;
        if (val/numIter<1) %~(this.progBar.CancelRequested) && (val/numIter<1)
            this.progBar.Value = val/numIter;
            this.progBar.Message = sprintf([this.iterMessage, '%d out of %d'],val,numIter);
        else
            % Kill the timer if the progressbar is closed.
            close(this);
        end
    end
    
    
end %private methods




end %classdef