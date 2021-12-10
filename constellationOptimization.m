%%% Matt Liepke, optimizing a given constellation to maximize coverage
%%% percentage

clear all; close all;clc;
%% Define TimeSpan
stkThreadLimit = 4; % Max number of STK instances to spool up (lots of mem)
stkStartTime = '01 Dec 2021 00:00:00.000';
stkEndTime = '03 Dec 2021 00:00:00.000';

satsPerPlane = 12;
semiMajAxis = 6900;
planeCount = 10;
inc = 53;


bounds = [];
initial = [0 0 ]
lb = [-1 -1 ];   % Lower bounds
ub =  [1 1 1 1 1];
fun = @(input) optimizationFunction(input,  satsPerPlane, planeCount, inc, semiMajAxis, stkStartTime, stkEndTime );

options = optimoptions('fmincon', 'UseParallel', true) % can't specify
%limit of threads

bestFourierCoeffs = fmincon(fun, initial, [],[],[],[],lb, ub, [], options);

disp(bestFourierCoeffs);
save('bestFourierCoeffs.mat');