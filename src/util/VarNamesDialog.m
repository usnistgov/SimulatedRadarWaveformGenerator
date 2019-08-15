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

classdef VarNamesDialog < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        VariableNames               matlab.ui.Figure
        WaveformdatavariableprefixLabel  matlab.ui.control.Label
        WaveformDataVariable        matlab.ui.control.EditField
        SignalstatusvariablePrefixLabel  matlab.ui.control.Label
        SignalStatusVariable        matlab.ui.control.EditField
        WaveformtablevariableLabel  matlab.ui.control.Label
        WaveformTableVariable       matlab.ui.control.EditField
        OK                          matlab.ui.control.Button
        DatasetreleasenoLabel       matlab.ui.control.Label
        DataSetRelease              matlab.ui.control.EditField
    end

    
    properties (Access = private)
        CallingApp
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, mainapp, WaveformDataVariable, SignalStatusVariable, WaveformTableVariable, DataSetRelease)
            % adjust dailog box relative position [left bottom width height]
            dialogPos=app.VariableNames.Position;
            mainPos=mainapp.MultiRadarWaveformGenerator.Position;
            dialogPos(1)=mainPos(1)+round(mainPos(3)/2)-round(dialogPos(3)/2);
            dialogPos(2)=mainPos(2)+round(mainPos(4))-round(dialogPos(4)/2);
            app.VariableNames.Position=dialogPos;
%             app.VariableNames.Position(1:2)= mainapp.MultiRadarWaveformGenerator.Position(1:2)...
%                 +round(mainapp.MultiRadarWaveformGenerator.Position(3:4)/2)- round(app.VariableNames.Position(3:4)/2);
            app.CallingApp = mainapp;
            app.WaveformDataVariable.Value=WaveformDataVariable;
            app.SignalStatusVariable.Value=SignalStatusVariable;
            app.WaveformTableVariable.Value=WaveformTableVariable;
            app.DataSetRelease.Value=DataSetRelease;
        end

        % Button pushed function: OK
        function OKButtonPushed(app, event)
            setPrefixVars(app.CallingApp, app.WaveformDataVariable.Value, app.SignalStatusVariable.Value,...
                app.WaveformTableVariable.Value,app.DataSetRelease.Value);
            
            % Delete the dialog box
            delete(app)
        end

        % Close request function: VariableNames
        function VariableNamesCloseRequest(app, event)
            delete(app)
            
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create VariableNames and hide until all components are created
            app.VariableNames = uifigure('Visible', 'off');
            app.VariableNames.Position = [100 100 346 205];
            app.VariableNames.Name = 'Variable Names';
            app.VariableNames.Resize = 'off';
            app.VariableNames.CloseRequestFcn = createCallbackFcn(app, @VariableNamesCloseRequest, true);
            app.VariableNames.Interruptible = 'off';

            % Create WaveformdatavariableprefixLabel
            app.WaveformdatavariableprefixLabel = uilabel(app.VariableNames);
            app.WaveformdatavariableprefixLabel.HorizontalAlignment = 'right';
            app.WaveformdatavariableprefixLabel.Position = [15 167 168 22];
            app.WaveformdatavariableprefixLabel.Text = 'Waveform data variable prefix:';

            % Create WaveformDataVariable
            app.WaveformDataVariable = uieditfield(app.VariableNames, 'text');
            app.WaveformDataVariable.Position = [188 167 143 22];

            % Create SignalstatusvariablePrefixLabel
            app.SignalstatusvariablePrefixLabel = uilabel(app.VariableNames);
            app.SignalstatusvariablePrefixLabel.HorizontalAlignment = 'right';
            app.SignalstatusvariablePrefixLabel.Position = [16 126 157 22];
            app.SignalstatusvariablePrefixLabel.Text = 'Signal status variable Prefix:';

            % Create SignalStatusVariable
            app.SignalStatusVariable = uieditfield(app.VariableNames, 'text');
            app.SignalStatusVariable.Position = [188 126 143 22];

            % Create WaveformtablevariableLabel
            app.WaveformtablevariableLabel = uilabel(app.VariableNames);
            app.WaveformtablevariableLabel.HorizontalAlignment = 'right';
            app.WaveformtablevariableLabel.Position = [16 84 134 22];
            app.WaveformtablevariableLabel.Text = 'Waveform table variable';

            % Create WaveformTableVariable
            app.WaveformTableVariable = uieditfield(app.VariableNames, 'text');
            app.WaveformTableVariable.Position = [188 84 143 22];

            % Create OK
            app.OK = uibutton(app.VariableNames, 'push');
            app.OK.ButtonPushedFcn = createCallbackFcn(app, @OKButtonPushed, true);
            app.OK.Position = [115 16 100 22];
            app.OK.Text = 'OK';

            % Create DatasetreleasenoLabel
            app.DatasetreleasenoLabel = uilabel(app.VariableNames);
            app.DatasetreleasenoLabel.HorizontalAlignment = 'right';
            app.DatasetreleasenoLabel.Position = [20 47 105 22];
            app.DatasetreleasenoLabel.Text = 'Dataset release no.';

            % Create DataSetRelease
            app.DataSetRelease = uieditfield(app.VariableNames, 'text');
            app.DataSetRelease.Position = [187 47 143 22];

            % Show the figure after all components are created
            app.VariableNames.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = VarNamesDialog(varargin)

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.VariableNames)

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.VariableNames)
        end
    end
end