function mimimize = optimizationFunction(input, satsperPlane, planeCount, inc, semiMajAxis, stkStartTime, stkEndTime )
%OPTIMIZATIONFUNCTION runs campus connection and returns a function to
%mimimzize
%   Detailed explanation goes here
try
    ourindex = randi(9999);
    temp = FindCoverageOfConstellationWithPhase(input, satsperPlane, planeCount,...
        inc, semiMajAxis, stkStartTime, stkEndTime,...
        ourindex);
    temp(numel(zeros(10,1))) = 0;
    covProb = temp;
catch err
    disp(err)
    disp("Overflow of covProb - More Sats could connect that you thought")
end

someSortOfCoverage = sum(covProb(2:end)); %all but the 0 sat probabilities
mimimize =  1 - someSortOfCoverage;

end

