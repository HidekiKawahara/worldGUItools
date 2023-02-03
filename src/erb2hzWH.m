function hz = erb2hzWH(erb)
%erb = 21.4*log10(0.00437*hz+1);
%erb/21.4 = log10(0.00437*hz+1);
%10^(erb/21.4) = 0.00437*hz+1;
%10^(erb/21.4)-1 = 0.00437*hz;
hz = (10.^(erb/21.4)-1)/0.00437;
%hz = erb;
end