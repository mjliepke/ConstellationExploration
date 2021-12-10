%%% Matt Liepke, creating TLE for a constellation and then sending it to
%%% STK, propogating and determining the amount of 'connected' time from
%%% KDAB to KPLC
clear all; close all;clc;
%% Define TimeSpan
stkThreadLimit = 4; % Max number of STK instances to spool up (lots of mem)
stkStartTime = '01 Dec 2021 00:00:00.000';
stkEndTime = '03 Dec 2021 00:00:00.000';

satsPerPlane = [8 10 12 14 16 18 20 22 24 28 30];
semiMajAxis = 6378+550;
planeCount = [6 8 10 12 14 16 18 20 22 24 26 28 30];
inc = 53;
covProb = zeros(length(satsPerPlane),length(planeCount),10); %assume no greater than 10 sats connected at once

for i=1:length(satsPerPlane)
    parfor (j=1:length(planeCount),stkThreadLimit)
        try
        temp = FindCoverageOfConstellation(satsPerPlane(i), planeCount(j),...
            inc, semiMajAxis, stkStartTime, stkEndTime,...
            (i-1)*length(satsPerPlane) + j);
        temp(numel(zeros(10,1))) = 0;
        covProb(i,j,:) = temp;
        catch err
            disp(err)
            disp("Overflow of covProb - More Sats could connect that you thought")
        end
    end
end
save('covProb.m','covProb')
someSortOfCoverage = sum(covProb(:,:,2:end),3); %all but the 0 sat probabilities

surf(planeCount, satsPerPlane,someSortOfCoverage)
xlabel("Sats Per Plane")
ylabel("Plane Count")
zlabel("Satellite Coverage Percentage of Time")
title("KDAB-KPLC Coverage from Constellations from:" + stkStartTime + " to " + stkEndTime + "for i = " + string(inc) + " and a = " + string(semiMajAxis))
t = 0; % for debugging to stop so STK from closing

