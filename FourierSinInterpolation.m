function y = FourierSinInterpolation(coeffArray, Length, x)
%FOURIERSININTERPOLATION Returns point given coeffArray and length of the
%period
%   Detailed explanation goes here
y = zeros(size(x));
for i  = 1 : length(coeffArray)
    y = y + coeffArray(i).*sin(2.*pi.*i.*x./Length);
end
end

