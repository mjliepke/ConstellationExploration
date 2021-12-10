function chainLinkDates = RunSTKCoverageCampusConnection(TLE_file, stkStartTime, stkEndTime)
%MAKESTKCOVERAGESCENARIO determines connected time between KDAB and KPLC
%using the satellites in TLE_file from the stkStartTime to stkEndTime. Only
%used 1-bounce (no sat -> sat communication)
%
% Returns list of [datetime, datetime] representing connected times


%% Define Stuff so you don't need to scroll down
station1Name = "KDAB";
station2Name = "KPRC";
tle_filepath = TLE_file;

%% Startup STK object and Set Scenario
try % stk doesn't like connecting sometimes so you gotta try it a couple times
    try
        stk = actxserver('STK12.application');
    catch err
        stk = actxserver('STK11.application');
    end
catch
    disp("STK Failed to Connect... Trying Again")
    pause(3); %wait for other (potential) apps to give us CPU time
    try
        stk = actxserver('STK12.application');
    catch err
        stk = actxserver('STK11.application');
    end
end

root = stk.Personality2;

scenario = root.Children.New('eScenario','AE_313H_STK3_Project');
scenario.SetTimePeriod(stkStartTime,stkEndTime);
scenario.StartTime = stkStartTime;
scenario.StopTime = stkEndTime;
root.ExecuteCommand('Animate * Reset');

%% Define TLEs and make all of them a constellation
satellites = importTLEToSTK(root,tle_filepath);

constellation = root.CurrentScenario.Children.New('eConstellation','MyConstellation');
for satellite = satellites
    try
        constellation.Objects.AddObject(satellite);
    catch
        fprintf("Satellite was not able to be added to the constellation")
    end
end

%% Ground Stations (KDAB and KPRC)
KDAB = scenario.Children.New('eFacility',station1Name);
KDAB.Position.AssignGeodetic(29.1802,-81.0598,0);
KDAB.UseTerrain = true;

KPRC = scenario.Children.New('eFacility',station2Name);
KPRC.Position.AssignGeodetic(34.6501,-112.4283,0);
KPRC.UseTerrain = true;

%% Create Chain Coverage and Compute
chain = root.CurrentScenario.Children.New('eChain', 'CampusConnection');

% Add chain from KDAB - constellation - KPRC (order matters)
chain.objects.AddObject(KDAB);
chain.Objects.AddObject(constellation);
chain.objects.AddObject(KPRC);

% Configure chain parameters
chain.AutoRecompute = true;
chain.EnableLightTimeDelay = true;
chain.TimeConvergence = 0.001;
chain.DataSaveMode = 'eSaveAccesses';

% Compute the chain and print
chain.ComputeAccess();

chainLinkDates = getChainAccess(chain);

%% Clean up server instances
release(chain);
release(constellation);
release(KDAB);
release(KPRC);
for sat = satellites
    release(sat);
end
release(scenario)
release(root)
release(stk)
t = 0; % debug line to pause so STK doesn't shutdown

%% FUNCTIONS

    function displayChainAccess(chain)
        % Credit to AGI https://help.agi.com/stkdevkit/11.4.0/Content/stkObjects/ObjModMatlabCodeSamples.htm#61
        % Considered Start and Stop time
        disp(['Chain considered start time: ' chain.Vgt.Events.Item('ConsideredStartTime').FindOccurrence.Epoch]);
        disp(['Chain considered stop time: ', chain.Vgt.Events.Item('ConsideredStopTime').FindOccurrence.Epoch]);
        
        objectParticipationIntervals = chain.Vgt.EventIntervalCollections.Item('StrandAccessIntervals');
        intervalListResult = objectParticipationIntervals.FindIntervalCollection();
        
        for i = 0:intervalListResult.IntervalCollections.Count -1
            
            if intervalListResult.IsValid
                
                disp(['Link Name: ' objectParticipationIntervals.Labels(i+1)]);
                disp('--------------');
                for j = 0:intervalListResult.IntervalCollections.Item(i).Count - 1
                    
                    startTime = intervalListResult.IntervalCollections.Item(i).Item(j).Start;
                    stopTime = intervalListResult.IntervalCollections.Item(i).Item(j).Stop;
                    disp(['Start: ' startTime ' Stop: ' stopTime]);
                end
            end
        end
        
    end

    function coverageList = getChainAccess(chain)
        % Credit to AGI https://help.agi.com/stkdevkit/11.4.0/Content/stkObjects/ObjModMatlabCodeSamples.htm#61
        % Considered Start and Stop time
        % coverageList is a 2-d list of [datetime, datetime]s
        % representing [start time, endtime]
        %disp(['Chain considered start time: ' chain.Vgt.Events.Item('ConsideredStartTime').FindOccurrence.Epoch]);
        %disp(['Chain considered stop time: ', chain.Vgt.Events.Item('ConsideredStopTime').FindOccurrence.Epoch]);
        
        objectParticipationIntervals = chain.Vgt.EventIntervalCollections.Item('StrandAccessIntervals');
        intervalListResult = objectParticipationIntervals.FindIntervalCollection();
        
        linkIndex = 1; % 1 indexing bc matlab bad :(
        for i = 0:intervalListResult.IntervalCollections.Count -1
            
            if intervalListResult.IsValid
                linkName = objectParticipationIntervals.Labels(i+1); % if we want to return

                for j = 0:intervalListResult.IntervalCollections.Item(i).Count - 1 %% Try to parfor this dude
                    
                    startTime = ConvertToDatetime(intervalListResult.IntervalCollections.Item(i).Item(j).Start);
                    stopTime = ConvertToDatetime(intervalListResult.IntervalCollections.Item(i).Item(j).Stop);
                    
                    coverageList(linkIndex,:) = [startTime stopTime];
                    linkIndex = linkIndex + 1;
                end
            end
        end
        
    end

    function satobjs = importTLEToSTK(root, tle_filepath)
        % Get the TLEs imported into STK in a super inefficient way
        [tles satNames] = readtle(tle_filepath);
        for i=1:size(tles,1)
            tle = tles(i,:);
            try
                % IAgStkObjectRoot root: STK Object Model Root
                tle_sat = root.CurrentScenario.Children.New('eSatellite', string(satNames(i)));
                % IAgSatellite satellite: Satellite object
                keplerian = tle_sat.Propagator.InitialState.Representation.ConvertTo('eOrbitStateClassical'); % Use the Classical Element interface
                keplerian.LocationType = 'eLocationMeanAnomaly'; % Makes sure True Anomaly is being used
                
                % Assign the perigee and apogee altitude values:
                keplerian.SizeShape.SemimajorAxis = tle(1); %stk wants in km
                keplerian.SizeShape.Eccentricity = tle(2);
                
                % Assign the other desired orbital parameters:
                keplerian.Orientation.Inclination = tle(5);         % deg
                keplerian.Orientation.ArgOfPerigee = tle(4);        % deg
                keplerian.Orientation.AscNode.Value = tle(6);       % deg
                keplerian.Location.Value = tle(3);                 % deg
                
                % Apply the changes made to the satellite's state and propagate:
                tle_sat.Propagator.InitialState.Representation.Assign(keplerian);
                tle_sat.Propagator.Propagate;
                satobjs(i) = tle_sat;
            catch
                fprintf("PROBLEM LOADING %s INTO STK, IGNORING THIS TLE\n",string(satNames(i)));
            end
        end
    end

    function [orbitalElements, orbitalNames ]= readtle(file, catalog, printStuff)
        % READTLE Read satellite ephemeris data from a NORAD two-line element (TLE) file.
        %
        % INPUTS:
        %   file    - Path to any standard two-line element file.
        %   catalog - Optional array of NORAD catalog numbers for the satellites of
        %             interest. The default action is to display data from every
        %             satellite in the file.
        %
        % Brett Pantalone
        % North Carolina State University
        % Department of Electrical and Computer Engineering
        % Optical Sensing Laboratory
        % mailto:bapantal@ncsu.edu
        % http://research.ece.ncsu.edu/osl/
        %
        % Modified by Matt Liepke to print stuff if I want and return an array.
        % Preallocation could speed this up a lot...
        % format: [a, ecc, M, w , Incl, Omega , satnum];
        
        %orbitalElements = zeros(n_sats,6)% could pre-allocate but I am in time crunch (yes irony)
        
        orbitalElements = [];
        orbitalNames = strings;
        if nargin < 2
            catalog = [];
            printStuff = 0;
        end
        fd = fopen(file,'r');
        if fd < 0, fd = fopen([file '.tle'],'r'); end
        assert(fd > 0,['Can''t open file ' file ' for reading.'])
        n = 0;
        A0 = fgetl(fd);
        A1 = fgetl(fd);
        A2 = fgetl(fd);
        while ischar(A2)
            n = n + 1;
            satnum = str2num(A1(3:7));
            if isempty(catalog) || ismember(satnum, catalog)
                
                % assert(chksum(A1), 'Checksum failure on line 1');
                assert(chksum(A2), 'Checksum failure on line 2');
                
                Incl = str2num(A2(9:16));
                Omega = str2num(A2(18:25));
                ecc = str2num(['.' A2(27:33)]);
                w = str2num(A2(35:42));
                M = str2num(A2(44:51));
                n = str2num(A2(53:63));
                T = 86400/n;
                a = ((T/(2*pi))^2*3.986E5)^(1/3);
                b = a*sqrt(1-ecc^2);
                
                if printStuff
                    fprintf('%s\n', repmat('-',1,50));
                    fprintf('Satellite: %s\n', A0)
                    fprintf('Catalog Number: %d\n', satnum)
                    fprintf('Epoch time: %s\n', A1(19:32)) % YYDDD.DDDDDDDD
                    fprintf('Inclination: %f deg\n', Incl)
                    fprintf('RA of ascending node: %f deg\n', Omega)
                    fprintf('Eccentricity: %f\n', ecc)
                    fprintf('Arg of perigee: %f deg\n', w)
                    fprintf('Mean anomaly: %f deg\n', M)
                    fprintf('Mean motion: %f rev/day\n', n)
                    fprintf('Period of rev: %.0f s/rev\n', T)
                    fprintf('Semi-major axis: %.0f meters\n', a)
                    fprintf('Semi-minor axis: %.0f meters\n', b)
                end
                
            end
            A0 = fgetl(fd);
            A1 = fgetl(fd);
            A2 = fgetl(fd);
            orbitalElements(end+1,:) = [a, ecc, M, w , Incl, Omega , satnum];
            orbitalNames(end+1) = erase(string(A0),[" ","(",")"]);
        end
        fclose(fd);
        orbitalNames = orbitalNames(2:end);
    end

    function result = chksum(str)
        % Checksum (Modulo 10)
        % Letters, blanks, periods, plus signs = 0; minus signs = 1
        result = false; c = 0;
        
        for k = 1:68
            if str(k) > '0' && str(k) <= '9'
                c = c + str(k) - 48;
            elseif str(k) == '-'
                c = c + 1;
            end
        end
        if mod(c,10) == str(69) - 48
            result = true;
        end
        
    end

end