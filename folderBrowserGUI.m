...%% Legal Disclaimer
...% NIST-developed software is provided by NIST as a public service. 
...% You may use, copy and distribute copies of the software in any medium,
...% provided that you keep intact this entire notice. You may improve,
...% modify and create derivative works of the software or any portion of
...% the software, and you may copy and distribute such modifications or
...% works. Modified works should carry a notice stating that you changed
...% the software and should note the date and nature of any such change.
...% Please explicitly acknowledge the National Institute of Standards and
...% Technology as the source of the software.
...% 
...% NIST-developed software is expressly provided "AS IS." NIST MAKES NO
...% WARRANTY OF ANY KIND, EXPRESS, IMPLIED, IN FACT OR ARISING BY
...% OPERATION OF LAW, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTY
...% OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, NON-INFRINGEMENT
...% AND DATA ACCURACY. NIST NEITHER REPRESENTS NOR WARRANTS THAT THE
...% OPERATION OF THE SOFTWARE WILL BE UNINTERRUPTED OR ERROR-FREE, OR
...% THAT ANY DEFECTS WILL BE CORRECTED. NIST DOES NOT WARRANT OR MAKE ANY 
...% REPRESENTATIONS REGARDING THE USE OF THE SOFTWARE OR THE RESULTS 
...% THEREOF, INCLUDING BUT NOT LIMITED TO THE CORRECTNESS, ACCURACY,
...% RELIABILITY, OR USEFULNESS OF THE SOFTWARE.
...% 
...% You are solely responsible for determining the appropriateness of
...% using and distributing the software and you assume all risks
...% associated with its use, including but not limited to the risks and
...% costs of program errors, compliance with applicable laws, damage to 
...% or loss of data, programs or equipment, and the unavailability or
...% interruption of operation. This software is not intended to be used in
...% any situation where a failure could cause risk of injury or damage to
...% property. The software developed by NIST employees is not subject to
...% copyright protection within the United States.

classdef folderBrowserGUI < matlab.apps.AppBase
    %Folder browser GUI with sort numbered files
    %   Example usage:
    %             dialogText='Select waveforms folder';
    %             defaultExt='dat';
    %             defaultDir='C:\'
    %             folderBrowser=folderBrowserGUI(defaultDir,dialogText,defaultExt)
    %             folderBrowser=SelectFolder(folderBrowser,SomeUIFig);
    %             waveformNames=getFileNames(folderBrowser,'withext');
    %             waveformPaths=getFullFileNamesWithPath(folderBrowser,'withext');
    
    properties %(Access=protected)
        defaultDir
        dialogText
        defaultExt
        fileNames
        directoryName
        UIFigure     matlab.ui.Figure
    end
   
    
    methods
        function folderBrowser=folderBrowserGUI(defaultDir,dialogText,defaultExt)
            if nargin > 0
                folderBrowser.defaultDir=defaultDir;
                folderBrowser.dialogText=dialogText;
                folderBrowser.defaultExt=defaultExt;
            end
        end
        
        function folderBrowser=setDefaultDir(folderBrowser,defaultDir)
            folderBrowser.defaultDir=defaultDir;
        end
        
        function folderBrowser=setDialogText(folderBrowser,dialogText)
            folderBrowser.dialogText=dialogText;
        end
        
        function folderBrowser=setDefaultExt(folderBrowser,defaultExt)
            folderBrowser.defaultExt=defaultExt;
        end
        
        function fileNames=getFileNames(folderBrowser,ext)
            % return cell arry of file names
            if nargin > 1 && strcmp(ext,'withoutext')
                for f_in=1:length(folderBrowser.fileNames)
                    folderBrowser.fileNames{f_in}= folderBrowser.fileNames{f_in}(1:end-4);
                end
            end
            fileNames=folderBrowser.fileNames;
            
        end
        
        function directoryName=getCurrentDir(folderBrowser)
            directoryName=folderBrowser.directoryName;
        end
        
        function fullFileNames=getFullFileNamesWithPath(folderBrowser,ext)
            % return cell arry of file names with paths
            if nargin > 1 && strcmp(ext,'withoutext')
                for f_in=1:length(folderBrowser.fileNames)
                    filesN{f_in}= folderBrowser.fileNames{f_in}(1:end-4);
                end
            else
                filesN=folderBrowser.fileNames;
            end
            for I=1:length(filesN)
                fullFileNames{I}=fullfile(folderBrowser.directoryName,filesN{I});
            end
            fullFileNames=fullFileNames.';
        end
        
        function folderBrowser=SelectFolder(folderBrowser,UIFigure)
            folderBrowser.directoryName = uigetdir(folderBrowser.defaultDir,folderBrowser.dialogText);
            if folderBrowser.directoryName~=0
                default_ext=strcat('*.',folderBrowser.defaultExt);
                dirSearch=fullfile(folderBrowser.directoryName,default_ext);
                dr = dir(dirSearch);
                if isempty(dr)
                    if nargin > 1
                        uialert(UIFigure,folderBrowser.directoryName,['No ', folderBrowser.defaultExt,' files found in']);
                    end
                    %return;
                else
                    for f_in=1:length(dr)
                        file_name_cell{f_in}= dr(f_in).name;
                    end
   
                    folderBrowser.fileNames=utilFun.sortByNumbers(file_name_cell.');
                    
                end
            else
                    folderBrowser.fileNames=[];
            end
        end
        
        end

end
