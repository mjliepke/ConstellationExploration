function coverageProbability = FindCoverageOfConstellationWithPhase(fourierAnomolyCoeffs, satPerPlane, planeCount, inc, a, startTime, endTime, analysisNumber)
tempTLEFile = "analysis" + string(analysisNumber) + ".txt";

try
    CreateConstellationWithPhaseTLE(satPerPlane ,planeCount, fourierAnomolyCoeffs, a, inc, tempTLEFile);
catch err
    disp("ERROR Creating TLE file")
    disp(err)
end

try
    chainDates = RunSTKCoverageCampusConnection(tempTLEFile, startTime, endTime);
    [coverageProbability ~] = PlotDateTimeRanges(chainDates, ConvertToDatetime(startTime), ConvertToDatetime(endTime), false);
catch err
    disp("ERROR finding coverage for TLE of " + tempTLEFile);
    disp(err)
    disp(err.stack)
    coverageProbability = [-1,-1];
end
end

