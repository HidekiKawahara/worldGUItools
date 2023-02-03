function hz = kHz2hzWH(kHz)
%erb = 21.4*log10(0.00437*hz+1);
%erb/21.4 = log10(0.00437*hz+1);
%10^(erb/21.4) = 0.00437*hz+1;
%10^(erb/21.4)-1 = 0.00437*hz;
hz = kHz*1000;
%hz = erb;
end