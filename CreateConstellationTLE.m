function CreateConstellationTLE(satPerPlane,planeCount, a, i, fileToSave)
%CREATECONSTELLATIONTLE creates a file w/ TLE elements corresponding to
%constellation inclination, elements per plane, and plane count.  Will
%assume that everything is evenly spaced  and that the first plane has a
%RAAN of 0deg.  Will randomly name each constellation and will leave
%the first line that of the ISS (with a bad checksum so be prepared)

RAAN_array = linspace(0,360-(360/planeCount),planeCount);
mean_anomoly_array = linspace(0,360-(360/satPerPlane),satPerPlane);

w = 0;
epoch = "08264.51782528";
e = 0;
TLE_string_array = string;
tempLines = string;
satNumber = 0;

for raan = RAAN_array
    for anomoly = mean_anomoly_array
        
        temp = GetTLEEntryString(a,e,anomoly, w, i, raan, "sat" + string(satNumber));
        for line = temp
           TLE_string_array(end+1) = line ;
        end
        satNumber = satNumber + 1;
    end
end

TLE_string_array = TLE_string_array(2:end); % remove first 'blank' line
%% File IO
if exist(fileToSave, 'file')==2
  delete(fileToSave');
end

fid = fopen(fileToSave,'wt');
fprintf(fid,'%s\n',TLE_string_array);

 fclose(fid);
 
    function entryLines = GetTLEEntryString(a, e, M, w, i, Omega, name)
        % epoch should take the form: 08264.51782528
        % format: [a, ecc, M, w , Incl, Omega , satnum];
        % ISS (ZARYA)
        %1 25544U 98067A   2102.51782528 -.00000000  00000-0 -11606-4 0  2927
        %2 25544  51.6416 247.4627 0006703 130.5360 325.0288 15.72125391563537
        
        T = (pi*3986^(1/2)*(a^3)^(1/2))/19930;
        n = 86400/T; % rev/day per format

        A1 = pad(name,24);
        A2 = "1 25544U 98067A   02102.51782528 -.00000000  00000-0 -11606-4 0  2927";
        
        iStr = pad(num2str(i,'%07.4f'),8,'left');
        raanStr = pad(num2str(Omega,'%07.4f'),8,'left');
        eccStr = num2str(e*10^7,'%07.0f');
        argPStr = pad(num2str(w,'%07.4f'),8,'left');
        meanAStr = pad(num2str(M,'%07.4f'),8,'left');
        meanMStr = pad(num2str(n,'%010.8f'),11,'left');
        epochRStr = '0001';
        
        A3 = convertStringsToChars(sprintf('2 12345 %s %s %s %s %s %s %s',iStr,raanStr,eccStr,argPStr,meanAStr,meanMStr, epochRStr));
        A3 = A3 + string(chksum(A3));
        
        entryLines = A1;
        entryLines(end+1) = A2;
        entryLines(end+1) = A3;
    end

    function chksum = chksum(str)
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
    chksum  = mod(c,10);
    end

end

