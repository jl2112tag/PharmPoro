classdef PharmPoro_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        PharmPoroUIFigure          matlab.ui.Figure
        FeatureTrainingPanel       matlab.ui.container.Panel
        psEditField_bottom         matlab.ui.control.NumericEditField
        psEditField_3Label         matlab.ui.control.Label
        psEditField_middle         matlab.ui.control.NumericEditField
        psEditField_2Label         matlab.ui.control.Label
        psEditField_top            matlab.ui.control.NumericEditField
        psEditFieldLabel           matlab.ui.control.Label
        ResetButton_2              matlab.ui.control.Button
        TrainButton                matlab.ui.control.Button
        TabletBottomButton         matlab.ui.control.Button
        MetalPlateButton           matlab.ui.control.Button
        TabletTopButton            matlab.ui.control.Button
        StatusEditField            matlab.ui.control.EditField
        UITable                    matlab.ui.control.Table
        SystemReadyLampLabel       matlab.ui.control.Label
        SystemReadyLamp            matlab.ui.control.Lamp
        AcquisitionSetttingsPanel  matlab.ui.container.Panel
        AutoNumberingSwitch        matlab.ui.control.Switch
        AutoNumberingSwitchLabel   matlab.ui.control.Label
        DescriptionEditField       matlab.ui.control.EditField
        DescriptionEditFieldLabel  matlab.ui.control.Label
        SampleNameEditField        matlab.ui.control.EditField
        SampleNameEditFieldLabel   matlab.ui.control.Label
        ResetButton                matlab.ui.control.Button
        STOPButton                 matlab.ui.control.Button
        ACQUIREButton              matlab.ui.control.Button
        AverageNumberEditField     matlab.ui.control.NumericEditField
        IntervalsecLabel           matlab.ui.control.Label
        RemoveBaselineButton       matlab.ui.control.Button
        BaselineButton             matlab.ui.control.Button
        BaselineLamp               matlab.ui.control.Lamp
        BaselineLampLabel          matlab.ui.control.Label
        SubtractBaselineCheckBox   matlab.ui.control.CheckBox
        UIAxes                     matlab.ui.control.UIAxes
    end

    
    properties (Access = private)
        tabletNumber % total number of acquisitions
        TcellAcq % Acquistion table cell
        matBaseline % Baseline matrix [time stamps; amplitudes]
        processStop % Is Stop-button pressed?
    end
    
    methods (Access = private)
        
      
        function updateTcellAcq(app,TcellNew)
            TcellAcq = app.TcellAcq;
            TcellAcq = [TcellAcq, TcellNew];
            app.TcellAcq = TcellAcq;
        end

        function addMeasurement(app) % single scan#
                fig = app.PharmPoroUIFigure;
                %curCol = size(app.TcellAcq,2);
                measMat = readWaveform(app);
                timeAxis = table2array(measMat(1,2:end));
                eAmp = table2array(measMat(2,2:end));
                timeStamps = table2array(measMat(2,1));
                clear("measMat");

                ax = app.UIAxes;
                legend(ax,'off')
                hold(ax,"on")
                axis(ax,"tight")

                plot(ax,timeAxis, eAmp, 'linewidth',1);
                drawnow


                % measNum = size(eAmp,1);
                % TcellNew = cell(22,measNum);
                % tabletNumber = tabletNumber + measNum;
                % digitNum = ceil(log10(measNum+1));
                % digitNumFormat = strcat('%0',num2str(digitNum),'d');
                % 
                % for idx = 1:measNum
                %     sampleName = app.SampleNameEditField.Value;
                %     description = app.DescriptionEditField.Value;
                %     description = strcat(sprintf(digitNumFormat,idx),'_',description);
                %     timeStamp = timeStamps(idx);
                %     datetimeValue = datetime(timeStamp, 'ConvertFrom', 'posixtime');
                %     datetimeValue.Format = 'yyyy-MM-dd HH:mm:ss.SSS';
                %     datetimeValue = char(datetimeValue);
                % 
                %     matBaseline = app.matBaseline;
                % 
                %     % Baseline subtraction check
                %     if app.SubtractBaselineCheckBox.Value
                % 
                %         if isempty(matBaseline)
                %             uialert(fig,'No valid baseline','Acquisition aborted');
                %             return;
                %         end
                % 
                %         if ~isempty(eAmp)
                %             try
                %                 eAmp(idx,:) = eAmp(idx,:) - matBaseline(2,:);
                %             catch
                %                 uialert(fig,'Inconsist Waveform length','Baseline subtraction aborted');
                %                 return;
                %             end
                %         end                    
                %     end
                % 
                % 
                %     % newInput{idx,1} = curCol+idx;
                %     % TcellNew{idx,2} = sampleName;
                %     % TcellNew{idx,3} = description;
                %     % TcellNew{idx,4} = 0; % Instrument profile
                % 
                % end

                % updateTcellAcq(app,TcellNew);
                % app.tabletNumber = tabletNumber;
        end
        
        function measMat = readWaveform(app,single)
            measAverage = app.AverageNumberEditField.Value;
            pythonScript = 'readReflections.py';
            progressFile = 'progress.txt';
            delete(progressFile);
            measurementFile = 'tabletRead.csv';
            pythonRun = true;
            command = sprintf('python %s --average %i', pythonScript, measAverage);
            
            system(command);
            
            while pythonRun
                pause(0.5);
                
                try
                    status = fileread(progressFile);
                catch
                    status = '';
                end

                if contains(status,'done')||app.processStop
                    pythonRun = false;
                end

                app.StatusEditField.Value = status;
                drawnow
            end

            measMat = readtable(measurementFile);
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            % Store main app object
            app.tabletNumber = 1;
        end

        % Close request function: PharmPoroUIFigure
        function PharmPoroUIFigureCloseRequest(app, event)
            
            % Delete the dialog box
            delete(app)            
        end

        % Button pushed function: ACQUIREButton
        function ACQUIREButtonPushed(app, event)
            app.SystemReadyLamp.Color = [0.85,0.33,0.10];
            app.SystemReadyLampLabel.Text = "Scaning...";
            app.processStop = false;
            fig = app.PharmPoroUIFigure;
            drawnow

            addMeasurement(app);
            app.SystemReadyLamp.Color = "Green";
            app.SystemReadyLampLabel.Text = "Ready";
            drawnow         
        end

        % Button pushed function: STOPButton
        function STOPButtonPushed(app, event)
            app.processStop = true;
        end

        % Button pushed function: BaselineButton
        function BaselineButtonPushed(app, event)
            try
                measMat = readWaveform(app);
                timeAxis = table2array(measMat(1,2:end));
                eAmp = table2array(measMat(2,2:end));
                app.matBaseline = [timeAxis;eAmp];
            catch
                app.BaselineLamp.Color = [0.85,0.33,0.10];
                return
            end

            app.BaselineLamp.Color = "Green";

        end

        % Button pushed function: RemoveBaselineButton
        function RemoveBaselineButtonPushed(app, event)
            app.matBaseline = [];
            app.BaselineLamp.Color = [0.85,0.33,0.10];
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create PharmPoroUIFigure and hide until all components are created
            app.PharmPoroUIFigure = uifigure('Visible', 'off');
            app.PharmPoroUIFigure.Position = [100 100 1192 889];
            app.PharmPoroUIFigure.Name = 'PharmPoro';
            app.PharmPoroUIFigure.Icon = 'CaT_logo.png';
            app.PharmPoroUIFigure.CloseRequestFcn = createCallbackFcn(app, @PharmPoroUIFigureCloseRequest, true);

            % Create UIAxes
            app.UIAxes = uiaxes(app.PharmPoroUIFigure);
            title(app.UIAxes, 'Title')
            xlabel(app.UIAxes, 'X')
            ylabel(app.UIAxes, 'Y')
            zlabel(app.UIAxes, 'Z')
            app.UIAxes.Box = 'on';
            app.UIAxes.Position = [26 433 829 418];

            % Create AcquisitionSetttingsPanel
            app.AcquisitionSetttingsPanel = uipanel(app.PharmPoroUIFigure);
            app.AcquisitionSetttingsPanel.Title = 'Acquisition Setttings';
            app.AcquisitionSetttingsPanel.FontWeight = 'bold';
            app.AcquisitionSetttingsPanel.FontSize = 13;
            app.AcquisitionSetttingsPanel.Position = [878 564 298 274];

            % Create SubtractBaselineCheckBox
            app.SubtractBaselineCheckBox = uicheckbox(app.AcquisitionSetttingsPanel);
            app.SubtractBaselineCheckBox.Text = 'Subtract Baseline';
            app.SubtractBaselineCheckBox.FontWeight = 'bold';
            app.SubtractBaselineCheckBox.Position = [15 162 123 22];

            % Create BaselineLampLabel
            app.BaselineLampLabel = uilabel(app.AcquisitionSetttingsPanel);
            app.BaselineLampLabel.HorizontalAlignment = 'right';
            app.BaselineLampLabel.Position = [11 196 51 22];
            app.BaselineLampLabel.Text = 'Baseline';

            % Create BaselineLamp
            app.BaselineLamp = uilamp(app.AcquisitionSetttingsPanel);
            app.BaselineLamp.Position = [71 196 20 20];
            app.BaselineLamp.Color = [0.851 0.3294 0.102];

            % Create BaselineButton
            app.BaselineButton = uibutton(app.AcquisitionSetttingsPanel, 'push');
            app.BaselineButton.ButtonPushedFcn = createCallbackFcn(app, @BaselineButtonPushed, true);
            app.BaselineButton.FontWeight = 'bold';
            app.BaselineButton.Position = [161 193 125 27];
            app.BaselineButton.Text = 'Baseline';

            % Create RemoveBaselineButton
            app.RemoveBaselineButton = uibutton(app.AcquisitionSetttingsPanel, 'push');
            app.RemoveBaselineButton.ButtonPushedFcn = createCallbackFcn(app, @RemoveBaselineButtonPushed, true);
            app.RemoveBaselineButton.FontWeight = 'bold';
            app.RemoveBaselineButton.Position = [161 159 125 27];
            app.RemoveBaselineButton.Text = 'Remove Baseline';

            % Create IntervalsecLabel
            app.IntervalsecLabel = uilabel(app.AcquisitionSetttingsPanel);
            app.IntervalsecLabel.HorizontalAlignment = 'right';
            app.IntervalsecLabel.Position = [8 225 96 22];
            app.IntervalsecLabel.Text = 'Average Number';

            % Create AverageNumberEditField
            app.AverageNumberEditField = uieditfield(app.AcquisitionSetttingsPanel, 'numeric');
            app.AverageNumberEditField.Limits = [0 10000];
            app.AverageNumberEditField.ValueDisplayFormat = '%.0f';
            app.AverageNumberEditField.FontWeight = 'bold';
            app.AverageNumberEditField.BackgroundColor = [0.9294 0.6941 0.1255];
            app.AverageNumberEditField.Position = [165 225 66 22];
            app.AverageNumberEditField.Value = 100;

            % Create ACQUIREButton
            app.ACQUIREButton = uibutton(app.AcquisitionSetttingsPanel, 'push');
            app.ACQUIREButton.ButtonPushedFcn = createCallbackFcn(app, @ACQUIREButtonPushed, true);
            app.ACQUIREButton.BackgroundColor = [1 1 1];
            app.ACQUIREButton.FontSize = 14;
            app.ACQUIREButton.FontWeight = 'bold';
            app.ACQUIREButton.FontColor = [0 0.4471 0.7412];
            app.ACQUIREButton.Position = [11 12 133 33];
            app.ACQUIREButton.Text = 'ACQUIRE';

            % Create STOPButton
            app.STOPButton = uibutton(app.AcquisitionSetttingsPanel, 'push');
            app.STOPButton.ButtonPushedFcn = createCallbackFcn(app, @STOPButtonPushed, true);
            app.STOPButton.BackgroundColor = [1 1 1];
            app.STOPButton.FontSize = 14;
            app.STOPButton.FontWeight = 'bold';
            app.STOPButton.FontColor = [0.851 0.3255 0.098];
            app.STOPButton.Position = [154 12 133 33];
            app.STOPButton.Text = 'STOP';

            % Create ResetButton
            app.ResetButton = uibutton(app.AcquisitionSetttingsPanel, 'push');
            app.ResetButton.Position = [222 118 59 27];
            app.ResetButton.Text = 'Reset';

            % Create SampleNameEditFieldLabel
            app.SampleNameEditFieldLabel = uilabel(app.AcquisitionSetttingsPanel);
            app.SampleNameEditFieldLabel.HorizontalAlignment = 'right';
            app.SampleNameEditFieldLabel.Position = [11 89 81 22];
            app.SampleNameEditFieldLabel.Text = 'Sample Name';

            % Create SampleNameEditField
            app.SampleNameEditField = uieditfield(app.AcquisitionSetttingsPanel, 'text');
            app.SampleNameEditField.Position = [98 89 186 22];

            % Create DescriptionEditFieldLabel
            app.DescriptionEditFieldLabel = uilabel(app.AcquisitionSetttingsPanel);
            app.DescriptionEditFieldLabel.HorizontalAlignment = 'right';
            app.DescriptionEditFieldLabel.Position = [12 58 65 22];
            app.DescriptionEditFieldLabel.Text = 'Description';

            % Create DescriptionEditField
            app.DescriptionEditField = uieditfield(app.AcquisitionSetttingsPanel, 'text');
            app.DescriptionEditField.Position = [98 58 186 22];

            % Create AutoNumberingSwitchLabel
            app.AutoNumberingSwitchLabel = uilabel(app.AcquisitionSetttingsPanel);
            app.AutoNumberingSwitchLabel.HorizontalAlignment = 'center';
            app.AutoNumberingSwitchLabel.Position = [12 120 92 22];
            app.AutoNumberingSwitchLabel.Text = 'Auto Numbering';

            % Create AutoNumberingSwitch
            app.AutoNumberingSwitch = uiswitch(app.AcquisitionSetttingsPanel, 'slider');
            app.AutoNumberingSwitch.Position = [134 121 45 20];

            % Create SystemReadyLamp
            app.SystemReadyLamp = uilamp(app.PharmPoroUIFigure);
            app.SystemReadyLamp.Position = [881 849 20 20];

            % Create SystemReadyLampLabel
            app.SystemReadyLampLabel = uilabel(app.PharmPoroUIFigure);
            app.SystemReadyLampLabel.Position = [910 847 83 22];
            app.SystemReadyLampLabel.Text = 'System Ready';

            % Create UITable
            app.UITable = uitable(app.PharmPoroUIFigure);
            app.UITable.ColumnName = {'Column 1'; 'Column 2'; 'Column 3'; 'Column 4'};
            app.UITable.RowName = {};
            app.UITable.Position = [256 104 432 185];

            % Create StatusEditField
            app.StatusEditField = uieditfield(app.PharmPoroUIFigure, 'text');
            app.StatusEditField.Editable = 'off';
            app.StatusEditField.BackgroundColor = [0.902 0.902 0.902];
            app.StatusEditField.Position = [996 848 173 20];

            % Create FeatureTrainingPanel
            app.FeatureTrainingPanel = uipanel(app.PharmPoroUIFigure);
            app.FeatureTrainingPanel.Title = 'Feature Training';
            app.FeatureTrainingPanel.Position = [878 359 298 190];

            % Create TabletTopButton
            app.TabletTopButton = uibutton(app.FeatureTrainingPanel, 'push');
            app.TabletTopButton.FontWeight = 'bold';
            app.TabletTopButton.Position = [17 132 122 27];
            app.TabletTopButton.Text = 'Tablet Top';

            % Create MetalPlateButton
            app.MetalPlateButton = uibutton(app.FeatureTrainingPanel, 'push');
            app.MetalPlateButton.FontWeight = 'bold';
            app.MetalPlateButton.Position = [17 100 122 27];
            app.MetalPlateButton.Text = 'Metal Plate';

            % Create TabletBottomButton
            app.TabletBottomButton = uibutton(app.FeatureTrainingPanel, 'push');
            app.TabletBottomButton.FontWeight = 'bold';
            app.TabletBottomButton.Position = [17 68 122 27];
            app.TabletBottomButton.Text = 'Tablet Bottom';

            % Create TrainButton
            app.TrainButton = uibutton(app.FeatureTrainingPanel, 'push');
            app.TrainButton.BackgroundColor = [1 1 1];
            app.TrainButton.FontWeight = 'bold';
            app.TrainButton.Position = [13 27 132 31];
            app.TrainButton.Text = 'Train';

            % Create ResetButton_2
            app.ResetButton_2 = uibutton(app.FeatureTrainingPanel, 'push');
            app.ResetButton_2.BackgroundColor = [1 1 1];
            app.ResetButton_2.FontWeight = 'bold';
            app.ResetButton_2.Position = [152 27 132 31];
            app.ResetButton_2.Text = 'Reset';

            % Create psEditFieldLabel
            app.psEditFieldLabel = uilabel(app.FeatureTrainingPanel);
            app.psEditFieldLabel.HorizontalAlignment = 'right';
            app.psEditFieldLabel.Position = [253 134 25 22];
            app.psEditFieldLabel.Text = 'ps';

            % Create psEditField_top
            app.psEditField_top = uieditfield(app.FeatureTrainingPanel, 'numeric');
            app.psEditField_top.ValueDisplayFormat = '%5.2f';
            app.psEditField_top.Position = [151 134 100 22];

            % Create psEditField_2Label
            app.psEditField_2Label = uilabel(app.FeatureTrainingPanel);
            app.psEditField_2Label.HorizontalAlignment = 'right';
            app.psEditField_2Label.Position = [253 102 25 22];
            app.psEditField_2Label.Text = 'ps';

            % Create psEditField_middle
            app.psEditField_middle = uieditfield(app.FeatureTrainingPanel, 'numeric');
            app.psEditField_middle.ValueDisplayFormat = '%5.2f';
            app.psEditField_middle.Position = [151 102 100 22];

            % Create psEditField_3Label
            app.psEditField_3Label = uilabel(app.FeatureTrainingPanel);
            app.psEditField_3Label.HorizontalAlignment = 'right';
            app.psEditField_3Label.Position = [253 70 25 22];
            app.psEditField_3Label.Text = 'ps';

            % Create psEditField_bottom
            app.psEditField_bottom = uieditfield(app.FeatureTrainingPanel, 'numeric');
            app.psEditField_bottom.ValueDisplayFormat = '%5.2f';
            app.psEditField_bottom.Position = [151 70 100 22];

            % Show the figure after all components are created
            app.PharmPoroUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = PharmPoro_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.PharmPoroUIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.PharmPoroUIFigure)
        end
    end
end