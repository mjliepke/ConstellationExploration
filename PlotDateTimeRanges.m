function  [probability longestWait] = PlotDateTimeRanges(datetimeArray, startDate, endDate, printMetrics)
%PLOTDATETIMERANGES Plots range of datetime array of [start, end]
%overlapping to represent coverage.  Also prints some metrics if desired
%   ASSUMES that all values in datetimeArray fall between startDate and
%   endDate
% Returns probability of [0,1,2...] satellites having coverage
histRes = seconds(10);

histogram_bins = startDate:histRes:endDate;
histogram_values = zeros(size(histogram_bins));

for i=1:size(datetimeArray,1)
[~, startIndex] = min(abs(histogram_bins-datetimeArray(i,1)));
[~, endIndex] = min(abs(histogram_bins-datetimeArray(i,2)));
 
histogram_values(startIndex:endIndex) = histogram_values(startIndex:endIndex) + 1;
end

hold on
hist = histogram(histogram_values, 'Normalization','probability');
xlabel('Satellite Chains Active');
ylabel('%% Time');
xticks(unique(round(get(gca,'xTick'))));
title('Histogram of Chains Active');

%% Plot stuff
if(printMetrics)
figure
bar(histogram_bins,histogram_values);
ylabel('Satellite Chains Active');
xlabel('Time');
title('Coverage Timeline');

end
%% Generate Features for GA
probability = hist.Values;

zeroPos = histogram_values == 0;
[~, zeroMaxLength] = max(diff(zeroPos));
longestWait = zeroMaxLength*histRes;
