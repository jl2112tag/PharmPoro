classdef PharmPoro_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        PharmPoroUIFigure              matlab.ui.Figure
        RESETButton                    matlab.ui.control.Button
        plotType                       matlab.ui.control.StateButton
        HoldPlotButton                 matlab.ui.control.StateButton
        PLOTButton                     matlab.ui.control.Button
        TimePositionEditField          matlab.ui.control.NumericEditField
        TimePositionEditFieldLabel     matlab.ui.control.Label
        ManualSelectionButton          matlab.ui.control.StateButton
        Peak3Button                    matlab.ui.control.Button
        Peak2Button                    matlab.ui.control.Button
        Peak1Button                    matlab.ui.control.Button
        TABULATETHEMEASUREMENTButton   matlab.ui.control.Button
        ResetPlotButton                matlab.ui.control.Button
        LOADButton                     matlab.ui.control.Button
        REMOVEButton                   matlab.ui.control.Button
        SAVEButton                     matlab.ui.control.Button
        PeakFindingPanel               matlab.ui.container.Panel
        RefractiveIndexEditField       matlab.ui.control.NumericEditField
        RefractiveIndexEditFieldLabel  matlab.ui.control.Label
        ThicknessEditField             matlab.ui.control.NumericEditField
        ThicknessEditFieldLabel        matlab.ui.control.Label
        mmLabel                        matlab.ui.control.Label
        psLabel_1                      matlab.ui.control.Label
        psLabel_2                      matlab.ui.control.Label
        psLabel_3                      matlab.ui.control.Label
        CALCULATEButton_2              matlab.ui.control.Button
        TabletBottomEditField          matlab.ui.control.NumericEditField
        TabletBottomEditFieldLabel     matlab.ui.control.Label
        SubstrateEditField             matlab.ui.control.NumericEditField
        SubstrateEditFieldLabel        matlab.ui.control.Label
        TabletTopEditField             matlab.ui.control.NumericEditField
        TabletTopEditFieldLabel        matlab.ui.control.Label
        psLabel_0                      matlab.ui.control.Label
        MinimumPeakDistanceEditField   matlab.ui.control.NumericEditField
        MinimumPeakDistanceEditFieldLabel  matlab.ui.control.Label
        FINDPEAKSButton                matlab.ui.control.Button
        StatusEditField                matlab.ui.control.EditField
        UITable                        matlab.ui.control.Table
        SystemReadyLampLabel           matlab.ui.control.Label
        SystemReadyLamp                matlab.ui.control.Lamp
        AcquisitionSetttingsPanel      matlab.ui.container.Panel
        NumberingEditField             matlab.ui.control.NumericEditField
        NumberingSwitch                matlab.ui.control.Switch
        NumberingSwitchLabel           matlab.ui.control.Label
        SampleNameEditField            matlab.ui.control.EditField
        SampleNameEditFieldLabel       matlab.ui.control.Label
        ResetButton                    matlab.ui.control.Button
        STOPButton                     matlab.ui.control.Button
        ACQUIREButton                  matlab.ui.control.Button
        AverageEditField               matlab.ui.control.NumericEditField
        IntervalsecLabel               matlab.ui.control.Label
        RemoveButton                   matlab.ui.control.Button
        BaselineButton                 matlab.ui.control.Button
        BaselineLamp                   matlab.ui.control.Lamp
        BaselineLampLabel              matlab.ui.control.Label
        SubtractBaselineCheckBox       matlab.ui.control.CheckBox
        UIAxes1                        matlab.ui.control.UIAxes
        UIAxes2                        matlab.ui.control.UIAxes
        UIAxes3                        matlab.ui.control.UIAxes
    end

    
    properties (Access = private)
        timeAxis
        eAmp
        timeAxis_BL
        eAmp_BL
        processStop % Is Stop-button pressed?
        hPlot % Description
        Tcell % Description
        cellIndices % Description
    end
    
    methods (Access = private)
        
      

        function dispWaveform(app,mode)
                fig = app.PharmPoroUIFigure;

                try 
                    if mode == 'Baseline'
                        timeAxis = app.timeAxis_BL;
                        eAmp = app.eAmp_BL;
                    else
                        timeAxis = app.timeAxis;
                        eAmp = app.eAmp;
                    end
                catch
                    msg = 'Datasets are not ready.'
                    return;
                end

                ax = app.UIAxes1;
                holdPlot = app.HoldPlotButton.Value;

                if holdPlot == false
                   cla(ax)
                end

                legend(ax,'off')
                hold(ax,"on")
                % axis(ax,"tight")

                hPlot = plot(ax,timeAxis, eAmp, 'linewidth',1);
                drawnow
                app.hPlot = hPlot;
        end
        
        function readWaveform(app,mode)
            measAverage = app.AverageEditField.Value;
            pythonScript = 'readReflections.py';
            progressFile = 'progress.txt';
            delete(progressFile);
            measurementFile = 'tabletRead.csv';
            msg = strcat(mode," started");
            measMat = [];
            app.StatusEditField.Value = msg;
            drawnow

            runPython = true;
            command = sprintf('python %s --average %i &', pythonScript, measAverage);

            system(command);
            pause(2.0);

            while runPython
                pause(0.5);

                try
                    msg = fileread(progressFile);
                catch
                    msg = "Python run error!";
                    runPython = false;
                end

                if app.processStop
                    msg = "Measurement aborted!";
                    runPython = false;
                end

                if contains(msg,'done')
                    msg = "Measurement done!";
                    runPython = false;
                    measMat = readtable(measurementFile);
                end

                app.StatusEditField.Value = msg;
                drawnow
            end                

            if isempty(measMat)
                return;
            end

            timeAxis = table2array(measMat(1,2:end));
            eAmp = table2array(measMat(2,2:end));
            eAmp = eAmp*-1;
            %timeStamps = table2array(measMat(2,1));

            if isequal(mode,"Baseline")
                app.timeAxis_BL = timeAxis;
                app.eAmp_BL = eAmp;
            else
                app.timeAxis = timeAxis;
                app.eAmp = eAmp;
            end

            if app.SubtractBaselineCheckBox.Value
                subtractBaseline(app);
            end

        end
        
        function displayPointInfo(app,src,data)
            pos = ceil(data.CurrentPosition);
            pos(1)
            app.PositionEditField.Value = mat2str([pos(1),pos(2)])
            
        end
        
        
        function disPosX(app,pt)
            app.TimePositionEditField.Value = pt(1);
        end
        
        function resetPos(app)
            app.TabletTopEditField.Value = 0;
            app.SubstrateEditField.Value = 0;
            app.TabletBottomEditField.Value = 0;
            app.ThicknessEditField.Value = 0;
            app.RefractiveIndexEditField.Value = 1;            
        end
        
        function updateTable(app)
            Tcell = app.Tcell;
            app.UITable.Data = Tcell;            
        end
        
        function subtractBaseline(app)
            fig = app.PharmPoroUIFigure;

            try
                timeAxis_BL = app.timeAxis_BL;
                eAmp_BL = app.eAmp_BL;
                timeAxis = app.timeAxis;
                eAmp = app.eAmp;
            catch
                msg = 'Datasets are not ready';
                uialert(fig,msg,'Warning');
                app.SubtractBaselineCheckBox.Value = false;
                return;
            end

            if size(timeAxis_BL) == size(timeAxis)
                eAmp = eAmp - eAmp_BL;
                app.eAmp = eAmp;
            else
                msg = 'The baseline time axis does not match the sample measurement.';
                uialert(fig,msg,'Warning');
                app.SubtractBaselineCheckBox.Value = false;
            end
        end
        
        function plotTable(app)
            Tcell = app.Tcell;
            ax2 = app.UIAxes2;
            ax3 = app.UIAxes3;

            cla(ax2);
            cla(ax3);

            if isempty(Tcell)
                return
            end

            binNum = cell2mat(Tcell(:,1));
            t_indices = cell2mat(Tcell(:,3));
            n_indices = cell2mat(Tcell(:,4));

            if app.plotType.Value
                histogram(ax2,t_indices);
                histogram(ax3,n_indices);

                xlabel(ax2,"Thickness (mm)");
                ylabel(ax2,"Bin Count");
                xlabel(ax3,"Refractive Index");
                ylabel(ax3,"Bin Count");

            else
                scatter(ax2,binNum,t_indices,"filled");
                scatter(ax3,binNum,n_indices,"filled");

                xlabel(ax2, "Bin Number");
                ylabel(ax2, "Thickness (mm)");
                xlabel(ax3, "Bin Number");
                ylabel(ax3, "Refractive Index");
            end
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)

        end

        % Button pushed function: ACQUIREButton
        function ACQUIREButtonPushed(app, event)
            app.SystemReadyLamp.Color = [0.85,0.33,0.10];
            app.SystemReadyLampLabel.Text = "Scaning...";
            app.processStop = false;
            resetPos(app);
            fig = app.PharmPoroUIFigure;
            mode = "Measurement";

            readWaveform(app,mode);
            dispWaveform(app,mode);
            app.SystemReadyLamp.Color = "Green";
            app.SystemReadyLampLabel.Text = "Ready";
            drawnow         
        end

        % Button pushed function: STOPButton
        function STOPButtonPushed(app, event)
            app.processStop = true;

            try
                system('taskkill /F /IM python.exe');
                app.StatusEditField.Value = 'Python process killed externally.';
            catch
                app.StatusEditField.Value = 'Python process is not running.';            
            end
            drawnow;
        end

        % Button pushed function: BaselineButton
        function BaselineButtonPushed(app, event)
            mode = "Baseline";

            try
                readWaveform(app,mode);
                dispWaveform(app,mode);
            catch
                app.BaselineLamp.Color = [0.85,0.33,0.10];
                return
            end

            if isempty(app.eAmp_BL)
                app.BaselineLamp.Color = [0.85,0.33,0.10];
            else
                app.BaselineLamp.Color = "Green";
            end
            
        end

        % Button pushed function: RemoveButton
        function RemoveButtonPushed(app, event)
            app.timeAxis_BL = [];
            app.eAmp_BL = [];
            app.BaselineLamp.Color = [0.85,0.33,0.10];
            app.SubtractBaselineCheckBox.Value = false;
        end

        % Button pushed function: FINDPEAKSButton
        function FINDPEAKSButtonPushed(app, event)
            timeAxis = app.timeAxis;
            eAmp = app.eAmp;
            timeDiff = mean(diff(timeAxis));
            minPkdis_ps = app.MinimumPeakDistanceEditField.Value;
            minPkdis = round(minPkdis_ps/timeDiff);
            numPks = 6;
            ax = app.UIAxes1;
            fig = app.PharmPoroUIFigure;
            %assignin('base',"eAmp",eAmp)

            [~,loc_p1] = max(eAmp);
            [~,loc_p3_gap] = max(eAmp(loc_p1+minPkdis:end));
            loc_p3 = loc_p3_gap + loc_p1+minPkdis-1;
            [~,loc_p2_gap] = max(eAmp((loc_p1+minPkdis:loc_p3-minPkdis)));
            loc_p2 = loc_p2_gap + loc_p1+minPkdis-1;

            locs_peak = [loc_p1,loc_p2,loc_p3];
            plot(ax,timeAxis(locs_peak),eAmp(locs_peak),'rv','MarkerFaceColor','auto')
            legend(ax,'THz waveform','Reflection peaks')

            if size(locs_peak,2) == 3
                app.TabletTopEditField.Value = timeAxis(locs_peak(1));
                app.SubstrateEditField.Value = timeAxis(locs_peak(2));
                app.TabletBottomEditField.Value = timeAxis(locs_peak(3));
            else
                msg = "Three peaks are required for calcuation!"
                uialert(fig,msg,'Warning');
                return;
            end
        end

        % Button pushed function: CALCULATEButton_2
        function CALCULATEButton_2Pushed(app, event)
            app.ThicknessEditField.Value = 0;
            app.RefractiveIndexEditField.Value = 1;
            c = 3*10^8;
            theta = 8.8; % terahertz beam incident angle in degree
            
            try
                p1 = app.TabletTopEditField.Value * 10^-12;
                p2 = app.SubstrateEditField.Value * 10^-12;
                p3 = app.TabletBottomEditField.Value * 10^-12;
            catch
                return
            end

            if p1 < p2 && p2 < p3
                thickness = 1/2*c*(p2-p1)*cos(deg2rad(theta));
                n_eff = 1/(sqrt((2*thickness/(c*(p3-p1)))^2   +  (sin(deg2rad(theta))^2)));

                app.ThicknessEditField.Value = thickness*1000;
                app.RefractiveIndexEditField.Value = n_eff;
            else
                return;
            end

        end

        % Button pushed function: TABULATETHEMEASUREMENTButton
        function TABULATETHEMEASUREMENTButtonPushed(app, event)
            idx = app.NumberingEditField.Value;

            idxStr = sprintf('%04d',idx);
            Tcell = app.Tcell;
            entryNum = size(Tcell,1)+1;
            
            sampleName = app.SampleNameEditField.Value;
            
            if app.NumberingSwitch.Value == "On"
                sampleName = strcat(sampleName,'_',idxStr);
                idx = idx + 1;
                app.NumberingEditField.Value = idx;
            end

            newEntry =  cell(1,7);
            newEntry{1} = int16(entryNum);
            newEntry{2} = sampleName;
            newEntry{3} = app.ThicknessEditField.Value;
            newEntry{4} = app.RefractiveIndexEditField.Value;
            newEntry{5} = app.TabletTopEditField.Value;
            newEntry{6} = app.SubstrateEditField.Value;
            newEntry{7} = app.TabletBottomEditField.Value;
            Tcell = [Tcell;newEntry];
            app.Tcell = Tcell;

            updateTable(app);
        end

        % Button pushed function: ResetPlotButton
        function ResetPlotButtonPushed(app, event)
            dispWaveform(app);
            app.ManualSelectionButton.Value = false;
        end

        % Button pushed function: Peak1Button
        function Peak1ButtonPushed(app, event)
            xPos = app.TimePositionEditField.Value;
            app.TabletTopEditField.Value = xPos;
        end

        % Button pushed function: Peak2Button
        function Peak2ButtonPushed(app, event)
            xPos = app.TimePositionEditField.Value;
            app.SubstrateEditField.Value = xPos;
        end

        % Button pushed function: Peak3Button
        function Peak3ButtonPushed(app, event)
            xPos = app.TimePositionEditField.Value;
            app.TabletBottomEditField.Value = xPos;
        end

        % Value changed function: ManualSelectionButton
        function ManualSelectionButtonValueChanged(app, event)
            value = app.ManualSelectionButton.Value;
            if value
                hPlot = app.hPlot;
                hPlot.ButtonDownFcn = @(h,e)disPosX(app,e.IntersectionPoint);
            else
                hPlot = app.hPlot;
                app.TimePositionEditField.Value = 0;
            end
        end

        % Button pushed function: ResetButton
        function ResetButtonPushed(app, event)
             app.NumberingEditField.Value = 1;
        end

        % Value changed function: NumberingEditField
        function NumberingEditFieldValueChanged(app, event)
            value = app.NumberingEditField.Value;
        end

        % Button pushed function: REMOVEButton
        function REMOVEButtonPushed(app, event)
            indices = app.cellIndices;
            Tcell = app.Tcell;

            if isempty(indices)
                return;
            end

            % remove the selected row
            curRow = indices(1);
            Tcell(curRow,:) = [];
            numRow = size(Tcell,1);

            if curRow >= numRow && curRow ~= 1
                indices = [curRow-1, indices(2)];
                app.cellIndices = indices;
            end



            if numRow >= 1
                Tcell(:,1) = num2cell((1:numRow));
                app.NumberingEditField.Value = numRow + 1;
            else
                app.cellIndices = [];
                app.NumberingEditField.Value = 1;
            end

            app.Tcell = Tcell;
            updateTable(app);
            drawnow
        end

        % Cell selection callback: UITable
        function UITableCellSelection(app, event)
            indices = event.Indices;
            app.cellIndices = indices;

            if isempty(indices)
                return
            end

            if indices(2) == 1
                app.UITable.ColumnEditable = false;
            else
                app.UITable.ColumnEditable = true;
            end
        end

        % Cell edit callback: UITable
        function UITableCellEdit(app, event)
            indices = event.Indices;
            newData = event.NewData;
            app.Tcell(indices(1),indices(2)) = {newData};
            updateTable(app);
        end

        % Button pushed function: PLOTButton
        function PLOTButtonPushed(app, event)
            plotTable(app);
        end

        % Button pushed function: SAVEButton
        function SAVEButtonPushed(app, event)
            % Open a file save dialog box with a filter for CSV files
            filter = {'*.csv';'*.*'};
            [filename, filepath] = uiputfile(filter);
            
            % Check if the user selected a file or cancelled the dialog
            if isequal(filename, 0) || isequal(filepath, 0)
                return;
            end
            
            % Combine the file path and file name
            fullFileName = fullfile(filepath, filename);
            
            % Retrieve the cell array from the app structure
            Tcell = app.Tcell;
            
            % Convert the cell array to a table and specify the column names
            T = cell2table(Tcell, 'VariableNames', {'No', 'Sample Name', 'Thickness(mm)', 'Refractive Index','Peak 1','Peak 2', 'Peak 3'});

            % Write the table to a CSV file
            writetable(T, fullFileName);
            
            disp('File saved successfully.');
        end

        % Value changed function: plotType
        function plotTypeValueChanged(app, event)
            value = app.plotType.Value;
            if value
                app.plotType.Text = "Histogram";
            else
                app.plotType.Text = "Scatter";
            end

            if ~isempty(app.Tcell)
                plotTable(app);
            end
        end

        % Value changed function: NumberingSwitch
        function NumberingSwitchValueChanged(app, event)
            value = app.NumberingSwitch.Value;
            if value == "Off"
                app.NumberingEditField.Value = 1;
            end           
        end

        % Button pushed function: LOADButton
        function LOADButtonPushed(app, event)
            [file, filepath] = uigetfile('*.csv');

            if isequal(file,0)
                return;
            end

            fullpath = strcat(filepath,file);
            Tcell = readtable(fullpath,'PreserveVariableNames', true);
            Tcell = table2cell(Tcell);
            curNum = size(Tcell,1)+1;
            app.NumberingEditField.Value = curNum;

            app.Tcell = Tcell;

            updateTable(app);            
        end

        % Button pushed function: RESETButton
        function RESETButtonPushed(app, event)
            question = "Do you want to reset the table?";
            answer = questdlg(question,'Warning','Yes','No','No');
            
            if answer == "Yes"
                app.Tcell =[];
                app.NumberingEditField.Value = 1;
                updateTable(app);
            else
                return;
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Get the file path for locating images
            pathToMLAPP = fileparts(mfilename('fullpath'));

            % Create PharmPoroUIFigure and hide until all components are created
            app.PharmPoroUIFigure = uifigure('Visible', 'off');
            app.PharmPoroUIFigure.Position = [100 100 1221 900];
            app.PharmPoroUIFigure.Name = 'PharmPoro';
            app.PharmPoroUIFigure.Icon = fullfile(pathToMLAPP, 'Images', 'CaT_logo.png');

            % Create UIAxes3
            app.UIAxes3 = uiaxes(app.PharmPoroUIFigure);
            title(app.UIAxes3, 'Tablet Refractive Index')
            xlabel(app.UIAxes3, 'Bin Number')
            ylabel(app.UIAxes3, 'Refractive Index')
            zlabel(app.UIAxes3, 'Z')
            app.UIAxes3.FontWeight = 'bold';
            app.UIAxes3.GridLineWidth = 1;
            app.UIAxes3.MinorGridLineWidth = 1;
            app.UIAxes3.LineWidth = 1;
            app.UIAxes3.Box = 'on';
            app.UIAxes3.XGrid = 'on';
            app.UIAxes3.YGrid = 'on';
            app.UIAxes3.Position = [28 34 580 200];

            % Create UIAxes2
            app.UIAxes2 = uiaxes(app.PharmPoroUIFigure);
            title(app.UIAxes2, 'Tablet Thickness')
            xlabel(app.UIAxes2, 'Bin Number')
            ylabel(app.UIAxes2, 'Thickness (mm)')
            zlabel(app.UIAxes2, 'Z')
            app.UIAxes2.FontWeight = 'bold';
            app.UIAxes2.LineWidth = 1;
            app.UIAxes2.Box = 'on';
            app.UIAxes2.XGrid = 'on';
            app.UIAxes2.YGrid = 'on';
            app.UIAxes2.Position = [28 245 580 200];

            % Create UIAxes1
            app.UIAxes1 = uiaxes(app.PharmPoroUIFigure);
            title(app.UIAxes1, 'Terahertz Reflections')
            xlabel(app.UIAxes1, 'Time of Flight (ps)')
            ylabel(app.UIAxes1, 'Electric Field Intensity (a.u.)')
            zlabel(app.UIAxes1, 'Z')
            app.UIAxes1.FontWeight = 'bold';
            app.UIAxes1.LineWidth = 1;
            app.UIAxes1.Box = 'on';
            app.UIAxes1.XGrid = 'on';
            app.UIAxes1.YGrid = 'on';
            app.UIAxes1.Position = [28 501 861 366];

            % Create AcquisitionSetttingsPanel
            app.AcquisitionSetttingsPanel = uipanel(app.PharmPoroUIFigure);
            app.AcquisitionSetttingsPanel.Title = 'Acquisition Setttings';
            app.AcquisitionSetttingsPanel.FontWeight = 'bold';
            app.AcquisitionSetttingsPanel.FontSize = 13;
            app.AcquisitionSetttingsPanel.Position = [913 636 298 213];

            % Create SubtractBaselineCheckBox
            app.SubtractBaselineCheckBox = uicheckbox(app.AcquisitionSetttingsPanel);
            app.SubtractBaselineCheckBox.Text = 'Subtract Baseline';
            app.SubtractBaselineCheckBox.FontWeight = 'bold';
            app.SubtractBaselineCheckBox.Position = [131 163 123 22];

            % Create BaselineLampLabel
            app.BaselineLampLabel = uilabel(app.AcquisitionSetttingsPanel);
            app.BaselineLampLabel.HorizontalAlignment = 'right';
            app.BaselineLampLabel.Position = [11 129 51 22];
            app.BaselineLampLabel.Text = 'Baseline';

            % Create BaselineLamp
            app.BaselineLamp = uilamp(app.AcquisitionSetttingsPanel);
            app.BaselineLamp.Position = [71 129 20 20];
            app.BaselineLamp.Color = [0.851 0.3294 0.102];

            % Create BaselineButton
            app.BaselineButton = uibutton(app.AcquisitionSetttingsPanel, 'push');
            app.BaselineButton.ButtonPushedFcn = createCallbackFcn(app, @BaselineButtonPushed, true);
            app.BaselineButton.FontWeight = 'bold';
            app.BaselineButton.Position = [123 126 90 27];
            app.BaselineButton.Text = 'Baseline';

            % Create RemoveButton
            app.RemoveButton = uibutton(app.AcquisitionSetttingsPanel, 'push');
            app.RemoveButton.ButtonPushedFcn = createCallbackFcn(app, @RemoveButtonPushed, true);
            app.RemoveButton.FontWeight = 'bold';
            app.RemoveButton.Position = [220 126 64 27];
            app.RemoveButton.Text = 'Remove';

            % Create IntervalsecLabel
            app.IntervalsecLabel = uilabel(app.AcquisitionSetttingsPanel);
            app.IntervalsecLabel.HorizontalAlignment = 'right';
            app.IntervalsecLabel.Position = [10 162 53 22];
            app.IntervalsecLabel.Text = 'Average ';

            % Create AverageEditField
            app.AverageEditField = uieditfield(app.AcquisitionSetttingsPanel, 'numeric');
            app.AverageEditField.Limits = [0 10000];
            app.AverageEditField.ValueDisplayFormat = '%.0f';
            app.AverageEditField.FontWeight = 'bold';
            app.AverageEditField.BackgroundColor = [0.9294 0.6941 0.1255];
            app.AverageEditField.Position = [71 162 43 22];
            app.AverageEditField.Value = 100;

            % Create ACQUIREButton
            app.ACQUIREButton = uibutton(app.AcquisitionSetttingsPanel, 'push');
            app.ACQUIREButton.ButtonPushedFcn = createCallbackFcn(app, @ACQUIREButtonPushed, true);
            app.ACQUIREButton.BackgroundColor = [1 1 1];
            app.ACQUIREButton.FontSize = 14;
            app.ACQUIREButton.FontWeight = 'bold';
            app.ACQUIREButton.FontColor = [0 0.4471 0.7412];
            app.ACQUIREButton.Position = [11 10 133 33];
            app.ACQUIREButton.Text = 'ACQUIRE';

            % Create STOPButton
            app.STOPButton = uibutton(app.AcquisitionSetttingsPanel, 'push');
            app.STOPButton.ButtonPushedFcn = createCallbackFcn(app, @STOPButtonPushed, true);
            app.STOPButton.BackgroundColor = [1 1 1];
            app.STOPButton.FontSize = 14;
            app.STOPButton.FontWeight = 'bold';
            app.STOPButton.FontColor = [0.851 0.3255 0.098];
            app.STOPButton.Position = [154 10 133 33];
            app.STOPButton.Text = 'STOP';

            % Create ResetButton
            app.ResetButton = uibutton(app.AcquisitionSetttingsPanel, 'push');
            app.ResetButton.ButtonPushedFcn = createCallbackFcn(app, @ResetButtonPushed, true);
            app.ResetButton.FontWeight = 'bold';
            app.ResetButton.Position = [220 83 64 27];
            app.ResetButton.Text = 'Reset';

            % Create SampleNameEditFieldLabel
            app.SampleNameEditFieldLabel = uilabel(app.AcquisitionSetttingsPanel);
            app.SampleNameEditFieldLabel.HorizontalAlignment = 'right';
            app.SampleNameEditFieldLabel.Position = [7 52 81 22];
            app.SampleNameEditFieldLabel.Text = 'Sample Name';

            % Create SampleNameEditField
            app.SampleNameEditField = uieditfield(app.AcquisitionSetttingsPanel, 'text');
            app.SampleNameEditField.Position = [96 52 140 22];

            % Create NumberingSwitchLabel
            app.NumberingSwitchLabel = uilabel(app.AcquisitionSetttingsPanel);
            app.NumberingSwitchLabel.HorizontalAlignment = 'center';
            app.NumberingSwitchLabel.Position = [11 85 64 22];
            app.NumberingSwitchLabel.Text = 'Numbering';

            % Create NumberingSwitch
            app.NumberingSwitch = uiswitch(app.AcquisitionSetttingsPanel, 'slider');
            app.NumberingSwitch.Items = {'On', 'Off'};
            app.NumberingSwitch.ValueChangedFcn = createCallbackFcn(app, @NumberingSwitchValueChanged, true);
            app.NumberingSwitch.Position = [118 86 45 20];
            app.NumberingSwitch.Value = 'On';

            % Create NumberingEditField
            app.NumberingEditField = uieditfield(app.AcquisitionSetttingsPanel, 'numeric');
            app.NumberingEditField.Limits = [1 Inf];
            app.NumberingEditField.ValueDisplayFormat = '%.0f';
            app.NumberingEditField.ValueChangedFcn = createCallbackFcn(app, @NumberingEditFieldValueChanged, true);
            app.NumberingEditField.FontWeight = 'bold';
            app.NumberingEditField.BackgroundColor = [0.9412 0.9412 0.9412];
            app.NumberingEditField.Position = [244 52 38 22];
            app.NumberingEditField.Value = 1;

            % Create SystemReadyLamp
            app.SystemReadyLamp = uilamp(app.PharmPoroUIFigure);
            app.SystemReadyLamp.Position = [916 860 20 20];

            % Create SystemReadyLampLabel
            app.SystemReadyLampLabel = uilabel(app.PharmPoroUIFigure);
            app.SystemReadyLampLabel.Position = [945 858 83 22];
            app.SystemReadyLampLabel.Text = 'System Ready';

            % Create UITable
            app.UITable = uitable(app.PharmPoroUIFigure);
            app.UITable.ColumnName = {'No.'; 'Name'; 'Thickness'; 'Refractive Index'; 'Peak1'; 'Peak2'; 'Peak3'};
            app.UITable.ColumnWidth = {40, 'auto', 75, 110, 75, 75, 75};
            app.UITable.RowName = {};
            app.UITable.CellEditCallback = createCallbackFcn(app, @UITableCellEdit, true);
            app.UITable.CellSelectionCallback = createCallbackFcn(app, @UITableCellSelection, true);
            app.UITable.Position = [627 60 580 330];

            % Create StatusEditField
            app.StatusEditField = uieditfield(app.PharmPoroUIFigure, 'text');
            app.StatusEditField.Editable = 'off';
            app.StatusEditField.BackgroundColor = [0.902 0.902 0.902];
            app.StatusEditField.Position = [1031 859 180 20];

            % Create PeakFindingPanel
            app.PeakFindingPanel = uipanel(app.PharmPoroUIFigure);
            app.PeakFindingPanel.Title = 'Peak Finding';
            app.PeakFindingPanel.Position = [913 442 298 185];

            % Create FINDPEAKSButton
            app.FINDPEAKSButton = uibutton(app.PeakFindingPanel, 'push');
            app.FINDPEAKSButton.ButtonPushedFcn = createCallbackFcn(app, @FINDPEAKSButtonPushed, true);
            app.FINDPEAKSButton.BackgroundColor = [1 1 1];
            app.FINDPEAKSButton.FontSize = 14;
            app.FINDPEAKSButton.FontWeight = 'bold';
            app.FINDPEAKSButton.FontColor = [0 0.4471 0.7412];
            app.FINDPEAKSButton.Position = [11 96 133 31];
            app.FINDPEAKSButton.Text = 'FIND PEAKS';

            % Create MinimumPeakDistanceEditFieldLabel
            app.MinimumPeakDistanceEditFieldLabel = uilabel(app.PeakFindingPanel);
            app.MinimumPeakDistanceEditFieldLabel.HorizontalAlignment = 'right';
            app.MinimumPeakDistanceEditFieldLabel.Position = [16 135 134 22];
            app.MinimumPeakDistanceEditFieldLabel.Text = 'Minimum Peak Distance';

            % Create MinimumPeakDistanceEditField
            app.MinimumPeakDistanceEditField = uieditfield(app.PeakFindingPanel, 'numeric');
            app.MinimumPeakDistanceEditField.Limits = [0 Inf];
            app.MinimumPeakDistanceEditField.ValueDisplayFormat = '%5.2f';
            app.MinimumPeakDistanceEditField.Position = [191 135 58 22];
            app.MinimumPeakDistanceEditField.Value = 10;

            % Create psLabel_0
            app.psLabel_0 = uilabel(app.PeakFindingPanel);
            app.psLabel_0.Position = [254 135 25 22];
            app.psLabel_0.Text = 'ps';

            % Create TabletTopEditFieldLabel
            app.TabletTopEditFieldLabel = uilabel(app.PeakFindingPanel);
            app.TabletTopEditFieldLabel.HorizontalAlignment = 'right';
            app.TabletTopEditFieldLabel.Position = [17 66 60 22];
            app.TabletTopEditFieldLabel.Text = 'Tablet Top';

            % Create TabletTopEditField
            app.TabletTopEditField = uieditfield(app.PeakFindingPanel, 'numeric');
            app.TabletTopEditField.ValueDisplayFormat = '%5.2f';
            app.TabletTopEditField.Position = [84 66 50 22];

            % Create SubstrateEditFieldLabel
            app.SubstrateEditFieldLabel = uilabel(app.PeakFindingPanel);
            app.SubstrateEditFieldLabel.HorizontalAlignment = 'right';
            app.SubstrateEditFieldLabel.Position = [19 37 56 22];
            app.SubstrateEditFieldLabel.Text = 'Substrate';

            % Create SubstrateEditField
            app.SubstrateEditField = uieditfield(app.PeakFindingPanel, 'numeric');
            app.SubstrateEditField.ValueDisplayFormat = '%5.2f';
            app.SubstrateEditField.Position = [84 37 50 22];

            % Create TabletBottomEditFieldLabel
            app.TabletBottomEditFieldLabel = uilabel(app.PeakFindingPanel);
            app.TabletBottomEditFieldLabel.HorizontalAlignment = 'right';
            app.TabletBottomEditFieldLabel.Position = [2 10 78 22];
            app.TabletBottomEditFieldLabel.Text = 'Tablet Bottom';

            % Create TabletBottomEditField
            app.TabletBottomEditField = uieditfield(app.PeakFindingPanel, 'numeric');
            app.TabletBottomEditField.ValueDisplayFormat = '%5.2f';
            app.TabletBottomEditField.Position = [84 10 50 22];

            % Create CALCULATEButton_2
            app.CALCULATEButton_2 = uibutton(app.PeakFindingPanel, 'push');
            app.CALCULATEButton_2.ButtonPushedFcn = createCallbackFcn(app, @CALCULATEButton_2Pushed, true);
            app.CALCULATEButton_2.BackgroundColor = [1 1 1];
            app.CALCULATEButton_2.FontSize = 14;
            app.CALCULATEButton_2.FontWeight = 'bold';
            app.CALCULATEButton_2.FontColor = [0.0745 0.6235 1];
            app.CALCULATEButton_2.Position = [156 96 132 31];
            app.CALCULATEButton_2.Text = 'CALCULATE';

            % Create psLabel_3
            app.psLabel_3 = uilabel(app.PeakFindingPanel);
            app.psLabel_3.Position = [137 9 25 22];
            app.psLabel_3.Text = 'ps';

            % Create psLabel_2
            app.psLabel_2 = uilabel(app.PeakFindingPanel);
            app.psLabel_2.Position = [137 36 25 22];
            app.psLabel_2.Text = 'ps';

            % Create psLabel_1
            app.psLabel_1 = uilabel(app.PeakFindingPanel);
            app.psLabel_1.Position = [137 65 25 22];
            app.psLabel_1.Text = 'ps';

            % Create mmLabel
            app.mmLabel = uilabel(app.PeakFindingPanel);
            app.mmLabel.Position = [266 64 25 22];
            app.mmLabel.Text = 'mm';

            % Create ThicknessEditFieldLabel
            app.ThicknessEditFieldLabel = uilabel(app.PeakFindingPanel);
            app.ThicknessEditFieldLabel.HorizontalAlignment = 'right';
            app.ThicknessEditFieldLabel.Position = [155 64 59 22];
            app.ThicknessEditFieldLabel.Text = 'Thickness';

            % Create ThicknessEditField
            app.ThicknessEditField = uieditfield(app.PeakFindingPanel, 'numeric');
            app.ThicknessEditField.Limits = [0 Inf];
            app.ThicknessEditField.ValueDisplayFormat = '%5.2f';
            app.ThicknessEditField.Position = [217 64 45 22];

            % Create RefractiveIndexEditFieldLabel
            app.RefractiveIndexEditFieldLabel = uilabel(app.PeakFindingPanel);
            app.RefractiveIndexEditFieldLabel.HorizontalAlignment = 'right';
            app.RefractiveIndexEditFieldLabel.Position = [156 37 92 22];
            app.RefractiveIndexEditFieldLabel.Text = 'Refractive Index';

            % Create RefractiveIndexEditField
            app.RefractiveIndexEditField = uieditfield(app.PeakFindingPanel, 'numeric');
            app.RefractiveIndexEditField.Limits = [1 Inf];
            app.RefractiveIndexEditField.ValueDisplayFormat = '%5.2f';
            app.RefractiveIndexEditField.Position = [253 37 37 22];
            app.RefractiveIndexEditField.Value = 1;

            % Create SAVEButton
            app.SAVEButton = uibutton(app.PharmPoroUIFigure, 'push');
            app.SAVEButton.ButtonPushedFcn = createCallbackFcn(app, @SAVEButtonPushed, true);
            app.SAVEButton.BackgroundColor = [1 1 1];
            app.SAVEButton.FontSize = 14;
            app.SAVEButton.FontWeight = 'bold';
            app.SAVEButton.FontColor = [0.0745 0.6235 1];
            app.SAVEButton.Position = [1108 20 90 28];
            app.SAVEButton.Text = 'SAVE';

            % Create REMOVEButton
            app.REMOVEButton = uibutton(app.PharmPoroUIFigure, 'push');
            app.REMOVEButton.ButtonPushedFcn = createCallbackFcn(app, @REMOVEButtonPushed, true);
            app.REMOVEButton.BackgroundColor = [1 1 1];
            app.REMOVEButton.FontSize = 14;
            app.REMOVEButton.FontWeight = 'bold';
            app.REMOVEButton.FontColor = [1 0.4118 0.1608];
            app.REMOVEButton.Position = [910 20 90 28];
            app.REMOVEButton.Text = 'REMOVE';

            % Create LOADButton
            app.LOADButton = uibutton(app.PharmPoroUIFigure, 'push');
            app.LOADButton.ButtonPushedFcn = createCallbackFcn(app, @LOADButtonPushed, true);
            app.LOADButton.BackgroundColor = [1 1 1];
            app.LOADButton.FontSize = 14;
            app.LOADButton.FontWeight = 'bold';
            app.LOADButton.FontColor = [0.0745 0.6235 1];
            app.LOADButton.Position = [1009 20 90 28];
            app.LOADButton.Text = 'LOAD';

            % Create ResetPlotButton
            app.ResetPlotButton = uibutton(app.PharmPoroUIFigure, 'push');
            app.ResetPlotButton.ButtonPushedFcn = createCallbackFcn(app, @ResetPlotButtonPushed, true);
            app.ResetPlotButton.BackgroundColor = [1 1 1];
            app.ResetPlotButton.FontWeight = 'bold';
            app.ResetPlotButton.FontColor = [1 0.4118 0.1608];
            app.ResetPlotButton.Position = [681 462 96 23];
            app.ResetPlotButton.Text = 'Reset Plot';

            % Create TABULATETHEMEASUREMENTButton
            app.TABULATETHEMEASUREMENTButton = uibutton(app.PharmPoroUIFigure, 'push');
            app.TABULATETHEMEASUREMENTButton.ButtonPushedFcn = createCallbackFcn(app, @TABULATETHEMEASUREMENTButtonPushed, true);
            app.TABULATETHEMEASUREMENTButton.BackgroundColor = [1 1 1];
            app.TABULATETHEMEASUREMENTButton.FontSize = 14;
            app.TABULATETHEMEASUREMENTButton.FontWeight = 'bold';
            app.TABULATETHEMEASUREMENTButton.FontColor = [0 0.4471 0.7412];
            app.TABULATETHEMEASUREMENTButton.Position = [925 402 269 30];
            app.TABULATETHEMEASUREMENTButton.Text = 'TABULATE THE MEASUREMENT';

            % Create Peak1Button
            app.Peak1Button = uibutton(app.PharmPoroUIFigure, 'push');
            app.Peak1Button.ButtonPushedFcn = createCallbackFcn(app, @Peak1ButtonPushed, true);
            app.Peak1Button.BackgroundColor = [1 1 1];
            app.Peak1Button.FontWeight = 'bold';
            app.Peak1Button.Position = [399 462 83 23];
            app.Peak1Button.Text = 'Peak 1';

            % Create Peak2Button
            app.Peak2Button = uibutton(app.PharmPoroUIFigure, 'push');
            app.Peak2Button.ButtonPushedFcn = createCallbackFcn(app, @Peak2ButtonPushed, true);
            app.Peak2Button.BackgroundColor = [1 1 1];
            app.Peak2Button.FontWeight = 'bold';
            app.Peak2Button.Position = [491 462 83 23];
            app.Peak2Button.Text = 'Peak 2';

            % Create Peak3Button
            app.Peak3Button = uibutton(app.PharmPoroUIFigure, 'push');
            app.Peak3Button.ButtonPushedFcn = createCallbackFcn(app, @Peak3ButtonPushed, true);
            app.Peak3Button.BackgroundColor = [1 1 1];
            app.Peak3Button.FontWeight = 'bold';
            app.Peak3Button.Position = [583 462 83 23];
            app.Peak3Button.Text = 'Peak 3';

            % Create ManualSelectionButton
            app.ManualSelectionButton = uibutton(app.PharmPoroUIFigure, 'state');
            app.ManualSelectionButton.ValueChangedFcn = createCallbackFcn(app, @ManualSelectionButtonValueChanged, true);
            app.ManualSelectionButton.Text = 'Manual Selection';
            app.ManualSelectionButton.BackgroundColor = [1 1 1];
            app.ManualSelectionButton.FontWeight = 'bold';
            app.ManualSelectionButton.Position = [75 462 136 23];

            % Create TimePositionEditFieldLabel
            app.TimePositionEditFieldLabel = uilabel(app.PharmPoroUIFigure);
            app.TimePositionEditFieldLabel.HorizontalAlignment = 'right';
            app.TimePositionEditFieldLabel.Position = [221 462 77 22];
            app.TimePositionEditFieldLabel.Text = 'Time Position';

            % Create TimePositionEditField
            app.TimePositionEditField = uieditfield(app.PharmPoroUIFigure, 'numeric');
            app.TimePositionEditField.ValueDisplayFormat = '%5.2f';
            app.TimePositionEditField.Position = [305 462 62 22];

            % Create PLOTButton
            app.PLOTButton = uibutton(app.PharmPoroUIFigure, 'push');
            app.PLOTButton.ButtonPushedFcn = createCallbackFcn(app, @PLOTButtonPushed, true);
            app.PLOTButton.BackgroundColor = [1 1 1];
            app.PLOTButton.FontSize = 14;
            app.PLOTButton.FontWeight = 'bold';
            app.PLOTButton.FontColor = [0 0.4471 0.7412];
            app.PLOTButton.Position = [711 20 90 28];
            app.PLOTButton.Text = 'PLOT';

            % Create HoldPlotButton
            app.HoldPlotButton = uibutton(app.PharmPoroUIFigure, 'state');
            app.HoldPlotButton.Text = 'Hold Plot';
            app.HoldPlotButton.BackgroundColor = [1 1 1];
            app.HoldPlotButton.FontWeight = 'bold';
            app.HoldPlotButton.FontColor = [0.4667 0.6745 0.1882];
            app.HoldPlotButton.Position = [787 462 96 23];

            % Create plotType
            app.plotType = uibutton(app.PharmPoroUIFigure, 'state');
            app.plotType.ValueChangedFcn = createCallbackFcn(app, @plotTypeValueChanged, true);
            app.plotType.Text = 'Scatter';
            app.plotType.BackgroundColor = [1 1 1];
            app.plotType.FontWeight = 'bold';
            app.plotType.FontColor = [0 0.4471 0.7412];
            app.plotType.Position = [70 21 136 23];

            % Create RESETButton
            app.RESETButton = uibutton(app.PharmPoroUIFigure, 'push');
            app.RESETButton.ButtonPushedFcn = createCallbackFcn(app, @RESETButtonPushed, true);
            app.RESETButton.BackgroundColor = [1 1 1];
            app.RESETButton.FontSize = 14;
            app.RESETButton.FontWeight = 'bold';
            app.RESETButton.FontColor = [1 0.4118 0.1608];
            app.RESETButton.Position = [811 20 90 28];
            app.RESETButton.Text = 'RESET';

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