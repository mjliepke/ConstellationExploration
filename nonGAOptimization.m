%%% Matt Liepke, creating TLE for a constellation and then sending it to
%%% STK, propogating and determining the amount of 'connected' time from
%%% KDAB to KPLC
clear all; close all;clc;
%% Define TimeSpan
stkThreadLimit = 8; % Max number of STK instances to spool up (lots of mem)
stkStartTime = '01 Dec 2021 00:00:00.000';
stkEndTime = '04 Dec 2021 00:00:00.000';

satsPerPlane = 12;
semiMajAxis = 6900;
planeCount = 10;
inc = 53;

B1 = linspace(0, 2*360/satsPerPlane, 15);
B2 = linspace(0, 2*360/satsPerPlane, 15);

covProb = zeros(length(B1),length(B2),10); %assume no greater than 10 sats connected at once


for i=1:length(B1)
    parfor (j=1:length(B2),stkThreadLimit)
        try
        temp = FindCoverageOfConstellationWithPhase([B1(i), B2(j)], satsPerPlane, ...
            planeCount, inc, semiMajAxis, stkStartTime, stkEndTime, ...
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

surf(B1, B2,someSortOfCoverage)
xlabel("B1")
ylabel("B2")
zlabel("Satellite Coverage Percentage of Time")
title("KDAB-KPLC Coverage from Constellations from:" + stkStartTime + " to " + stkEndTime + "for i = " + string(inc) + " and a = " + string(semiMajAxis))
t = 0; % for debugging to stop so STK from closing

