function dt = ConvertToDatetime(stkStr)
%CONVERTTODATETIME returns datetime object representing the stkStr's date.
%To convert stk's odd formatting
%   Detailed explanation goes here
 dt = datetime(stkStr,'InputFormat','dd MMM yyyy HH:mm:ss.SSS');
end

