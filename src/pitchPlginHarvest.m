function output = pitchPlginHarvest(x, fs, options)
%Plugin_Role fundamental_frequency
%Plugin_Name Harvest
output = Harvest(x, fs, options);
[~, nTime] = size(output.f0_candidates);
output.candidatePositions = (0:nTime-1)'/1000;
output.foExtractor = "Harvest";
end