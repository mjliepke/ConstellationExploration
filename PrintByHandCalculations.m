function [satsRecommended] = PrintByHandCalculations(altitude, inclination, satellitesInView, fudgeFactor)
%PRINTBYHANDCALCULATIONS Prints details concerning IAA for a constellation
%at altitude and inclination via Henderson, Troy's notes in SI /w km
%   Assumes Satellite footprint is IAA
%   Assumes constant radius earth
%   goal satellite coverage per point of satellitesInView
%   Bumps up required satellites by fudgeFactor (as coverages overlap)
%   Doesn't work too well if heavily elliptical

r_earth = 6378; %km
r_sat = r_earth + altitude; % radius of satellite semimaj axis
IAA = .5 * (1-r_earth/(r_earth + altitude)); % in %% earth surface area

fprintf("\nWith a semi-major axis of:\t\t\t%f km\nIAA is determined to be:\t\t\t%f %% Surface Area\n",...
    round(r_sat),IAA);

satsRequiredPerfectCoverage = satellitesInView/IAA;
satsRequired = satsRequiredPerfectCoverage*(1+fudgeFactor);

fprintf("Required sats for ideal coverage:\t%.0f\nRequired sats with fudgeFactor:\t\t%.0f\n",...
    satsRequiredPerfectCoverage, satsRequired);

end

