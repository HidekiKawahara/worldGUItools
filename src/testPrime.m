%% test prime
tic
upperLimit = 10^5;
n = upperLimit;
buff = ones(n,1);
buff(1) = 0;
testLim = ceil(sqrt(n));
for ii = 2:testLim
    if buff(ii) == 1
        buff(ii * (2:n/ii)) = 0;
    end
end
idx = 1:n;
xPrimes = idx(buff==1);
toc
sum(abs(xPrimes - primes(10^5)))
%%
ntest = 100;
eTime = zeros(ntest,1);
for ii = 1:ntest
    stmp = sum(1:rand(1,1)*1000000);
    stTic = tic;
    stmp = primes(10^5);
    eTime(ii) = toc(stTic);
end
figure;
bar(sort(eTime));grid on
ylabel("elapsed time (s)")