function output = generalizedTCmorphing(morphdBase,weightStr,dispOn)
% output = generalizedTCmorphing(morphdBase,weightStr,dispOn)
% generalized morphing function with temporally constant weights
%
% Argument
%   morphdBase: Structure variable with the following fields
%       morphStr : Structure variable consists of morphing objects
%           worldParameter  : WORLD vocoder analysis results *note-1
%           timeAnchor      : vector consisting of time anchring points
%           timeFreqAnchor  : martix sonsisting of time-frequency points
%   weightStr:  Structure variable with the following fields
%       tx: vector of morphing weight of time axis for each instance
%       fx: vector of morphing weight of frequency axis for each instance
%       fo: vector of morphing weight of fun. freq. for each instance
%       sl: vector of morphing weight of spectrum level for each instance
%       ap: vector of morphing weight of aperiodicity for each instance
%   dispOn: switch for debug, 1:plot graphs, 0:no plots
%
% Output
%   output: Structure variable with the following fields
%       source_parameter    : source parameters for vocoder with fields:
%           temporal_positions  : vector of frame locations
%           f0                  : fundamental frequency of each frame
%           vuv                 : 1: voiced, 0: unvoiced
%           aperiodicity        : aperiodicity matrix
%       spectrum_parameter  : spectrum prameters for vocoder
%           temporal_positions  : vector of frame locations
%           spectrogram         : smoothed power spectrum matrix
%           fs                  : sampling frequency
%       elapsedTime         : elapsed time for processing
%       * There are other fields for debug use
%
% *note-1   : use "worldHandler" tool to get worldParameter

% Copyright 2024 Hideki Kawahara
%
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
%
%    http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.

startTic = tic;
nObj = length(morphdBase.morphStr);

%Morph time axis
nTanchor = length(morphdBase.morphStr(1).timeAnchor);
segLengthMtx = zeros(nTanchor+1,nObj);
for ii = 1:nObj
    timeAnchor = morphdBase.morphStr(ii).timeAnchor;
    worldParameter = morphdBase.morphStr(ii).worldParameter;
    fs = worldParameter.samplingFrequency;
    span = worldParameter.span;
    endTime = length(span)/fs;
    lastPoint = 0;
    for jj = 1:nTanchor
        segLengthMtx(jj,ii) = timeAnchor(jj) - lastPoint;
        lastPoint = timeAnchor(jj);
    end
    segLengthMtx(nTanchor+1,ii) = endTime - lastPoint;
end
logSlopeMtx = log(segLengthMtx);
morphedLogSlope = logSlopeMtx*weightStr.tx;
morphedSlope = exp(morphedLogSlope);
morphedTanchor = cumsum(morphedSlope);
if dispOn
    figure;
    plot(cumsum(segLengthMtx),'o-');grid on;
    hold all
    plot(morphedTanchor,'ko-','LineWidth',2);
    xlabel("anchor index")
    ylabel("time (s)")
    hold off
    drawnow
end

%Morph fundamental frequency
morphedTemporalPosition = 0:0.005:morphedTanchor(end);
morphedFo = morphedTemporalPosition*0;
extendedTanchorMtx = cumsum(segLengthMtx);
morphedVUV = morphedTemporalPosition*0;
tmpAxisOnObjMtx = zeros(nObj,length(morphedTemporalPosition));
for ii = 1:nObj
    worldParameter = morphdBase.morphStr(ii).worldParameter;
    temporalPositions = worldParameter.source_parameter.temporal_positions;
    fo = worldParameter.source_parameter.f0;
    vuv = worldParameter.source_parameter.vuv;
    tmpAxisOnObj = ...
        interp1(morphedTanchor,extendedTanchorMtx(:,ii),morphedTemporalPosition,"linear","extrap");
    tmp = interp1(temporalPositions,log(fo),tmpAxisOnObj,"linear","extrap");
    tmp = exp(tmp);
    tmpVUV = interp1(temporalPositions,vuv,tmpAxisOnObj,"linear","extrap");
    tmp(isnan(tmp)) = 0;
    morphedFo = morphedFo + tmp*weightStr.fo(ii);
    morphedVUV = morphedVUV + tmpVUV*weightStr.fo(ii);
    tmpAxisOnObjMtx(ii,:) = tmpAxisOnObj;
end
morphedFo(morphedVUV<0.99) = 0;

%Display morphed fundamental frequency
if dispOn
    figure;
    semilogy(morphedTemporalPosition,morphedFo,"k","LineWidth",2);grid on;
    hold on
    for ii = 1:nObj
        worldParameter = morphdBase.morphStr(ii).worldParameter;
        temporalPositions = worldParameter.source_parameter.temporal_positions;
        fo = worldParameter.source_parameter.f0;
        semilogy(temporalPositions,fo);
        drawnow;
    end
    hold off
end

%morph frequency axis
spGram = worldParameter(1).spectrum_parameter.spectrogram;
[nFbin, ~] = size(spGram);
freqAxisOnMorph = (0:nFbin-1)'/nFbin*fs/2;
freqAxisOnMorph(1)=freqAxisOnMorph(2)/2;
logFx = log(freqAxisOnMorph);
timeFreqAnchor = morphdBase.morphStr(1).timeFreqAnchor;
maxNfreqAnchor = length(timeFreqAnchor(:,1));
freqMapStr = struct;
endLogFqPoint = log(fs/2);
segLengthMtx = zeros(maxNfreqAnchor+1,1);
weightedLogSlope = zeros(maxNfreqAnchor+1,nTanchor);
nFreqVector = zeros(nTanchor,1);
for ii = 1:nObj
    timeFreqAnchor = morphdBase.morphStr(ii).timeFreqAnchor;
    segLengthMtx = segLengthMtx*0;
    weightedLogSlope = weightedLogSlope*0;
    nFreqVector = nFreqVector*0;
    for jj = 1:nTanchor
        nFreq = nnz(timeFreqAnchor(:,jj));
        nFreqVector(jj) = nFreq;
        if nFreq == 0
            segLengthMtx(1) = endLogFqPoint;
        else
            lastPoint = 0;
            for kk = 1:nFreq
                segLengthMtx(kk) = log(timeFreqAnchor(kk,jj)) - lastPoint;
                lastPoint = log(timeFreqAnchor(kk,jj));
            end
            segLengthMtx(nFreq+1) = endLogFqPoint - lastPoint;
        end
        logSlopeMtx = segLengthMtx(1:nFreq+1);
        weightedLogSlope(1:nFreq+1,jj) = logSlopeMtx*weightStr.fx(ii);
    end
    freqMapStr.mapStr(ii).weightedLogSlope = weightedLogSlope;
    freqMapStr.mapStr(ii).nFreqVector = nFreqVector;
end
morphedLogSlope = zeros(maxNfreqAnchor+1,1);
morphedTLogFanchor = timeFreqAnchor*0;
freqAxisOnObj = zeros(nFbin,nTanchor);
for ii = 1:nObj
    freqMapStr.mapStr(ii).freqAxisOnObj =  freqAxisOnObj;
end
for jj = 1:nTanchor
    nFreq = nFreqVector(jj);
    if nFreq == 0
        morphedTLogFanchor(1,jj) = log(fs/2);
    else
        morphedLogSlope = morphedLogSlope*0;
        for ii = 1:nObj
            morphedLogSlope(1:nFreq+1) = morphedLogSlope(1:nFreq+1) ...
                +freqMapStr.mapStr(ii).weightedLogSlope(1:nFreq+1,jj);
        end
        morphedLogFanchor = cumsum(morphedLogSlope);
        morphedLogFanchor(nFreq+1) = log(fs/2);
        morphedTLogFanchor(1:nFreq+1,jj) = morphedLogFanchor(1:nFreq+1);
    end
    for ii = 1:nObj
        nFreq = nFreqVector(jj);
        if nFreq == 0
            freqMapStr.mapStr(ii).freqAxisOnObj(:,jj) = freqAxisOnMorph;
        else
            logFreqAnchor = log(morphdBase.morphStr(ii).timeFreqAnchor(1:nFreq,jj));
            tmp = interp1([0;morphedTLogFanchor(1:nFreq+1,jj)],[0;logFreqAnchor;endLogFqPoint], ...
                logFx,"linear","extrap");
            freqMapStr.mapStr(ii).freqAxisOnObj(:,jj) = exp(tmp);
        end
    end
end
morphedTFanchor = exp(morphedTLogFanchor);

%Check TF anchor morping
if dispOn
    figure;
    colorList = {"ro","go","bo","mo"};
    for ii = 1:nObj
        semilogy(morphdBase.morphStr(ii).timeAnchor,morphdBase.morphStr(ii).timeFreqAnchor, ...
            colorList{ii},"LineWidth",1.5);
        grid on
        hold on
    end
    hold on;
    semilogy(morphedTanchor(1:nTanchor),morphedTFanchor,'ko',"linewidth",3);
end

%Morph spectrogram
alignedLogSgram = struct;
nFrameMorph = length(morphedTemporalPosition);
morphedSgram = zeros(nFbin,nFrameMorph);
tmpSgramBase = zeros(nFbin,nFrameMorph);
morphedSgramWoFmod = zeros(nFbin,nFrameMorph);
morphedAp = zeros(nFbin,nFrameMorph);
for ii = 1:nObj
    %logAp = log(clip(morphdBase.morphStr(ii).worldParameter.source_parameter.aperiodicity,0.00001,1));
    logAp = log(max(0.00001,min(1,morphdBase.morphStr(ii).worldParameter.source_parameter.aperiodicity)));
    logSgram = log(morphdBase.morphStr(ii).worldParameter.spectrum_parameter.spectrogram);
    temporalPositions = morphdBase.morphStr(ii).worldParameter.spectrum_parameter.temporal_positions;
    alignedLogSgram(ii).sgram = interp1(temporalPositions,logSgram', ...
        tmpAxisOnObjMtx(ii,:),"linear","extrap")';
    alignedLogSgram(ii).ap = interp1(temporalPositions,logAp', ...
        tmpAxisOnObjMtx(ii,:),"linear","extrap")';
    lastTime = 0;
    currentFrame = 1;
    lastFreqAxOnObj = freqAxisOnMorph;
    tmpSgram = tmpSgramBase;
    tmpAp = tmpSgramBase;
    for jj = 1:nTanchor+1
        segLength = morphedTanchor(jj)-lastTime;
        if jj <= nTanchor
            nextFreqAxOnObj = freqMapStr.mapStr(ii).freqAxisOnObj(:,jj);
        else
            nextFreqAxOnObj = freqAxisOnMorph;
        end
        while currentFrame <= nFrameMorph ...
                && morphedTemporalPosition(currentFrame) < morphedTanchor(jj)
            currentTime = morphedTemporalPosition(currentFrame);
            lambda = (currentTime - lastTime)/segLength;
            currentFreqAxOnObj = ...
                (1-lambda)*lastFreqAxOnObj + lambda*nextFreqAxOnObj;
            tmpSgram(:,currentFrame) = ...
                interp1(freqAxisOnMorph,alignedLogSgram(ii).sgram(:,currentFrame), ...
                currentFreqAxOnObj,"linear","extrap");
            tmpAp(:,currentFrame) = ...
                interp1(freqAxisOnMorph,alignedLogSgram(ii).ap(:,currentFrame), ...
                currentFreqAxOnObj,"linear","extrap");
            currentFrame = currentFrame + 1;
        end
        lastFreqAxOnObj = nextFreqAxOnObj;
        if jj <= nTanchor
            lastTime = morphedTanchor(jj);
        end
    end
    morphedSgram = morphedSgram + tmpSgram*weightStr.sl(ii);
    morphedAp = morphedAp + tmpAp*weightStr.ap(ii);
    morphedSgramWoFmod = morphedSgramWoFmod ...
        +alignedLogSgram(ii).sgram*weightStr.sl(ii);
end
morphedSgram = exp(morphedSgram);
morphedSgramWoFmod = exp(morphedSgramWoFmod);
morphedAp = exp(morphedAp);
if dispOn
    figure;
    imagesc([0 morphedTemporalPosition(end)],[0 fs/2],10*log10(morphedSgram));
    axis('xy')
end
output.morphedSgram = morphedSgram;
output.morphedAp = morphedAp;
output.morphedSgramWoFmod = morphedSgramWoFmod;
output.morphedTemporalPosition = morphedTemporalPosition;
output.morphedFo = morphedFo;
morphedVUV(morphedVUV<0.995) = 0;
morphedVUV(morphedVUV>0) = 1;
output.morphedVUV = morphedVUV;
output.freqMapStr = freqMapStr;
%---------
source_parameter = struct;
spectrum_parameter = struct;
source_parameter.temporal_positions = morphedTemporalPosition;
source_parameter.f0 = morphedFo;
source_parameter.vuv = morphedVUV;
source_parameter.aperiodicity = morphedAp;
spectrum_parameter.temporal_positions = morphedTemporalPosition;
spectrum_parameter.spectrogram = morphedSgram;
spectrum_parameter.fs = fs;
output.source_parameter = source_parameter;
output.spectrum_parameter = spectrum_parameter;
output.elapsedTime = toc(startTic);
end
