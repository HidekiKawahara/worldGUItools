function output = wordTV2WmorphingEngineRev(worldPRef, worldPTgt, anchStr, mRate, vtl_ratio, displayOn)
strtTic = tic;
if isstruct(mRate)
    mStr = mRate;
else
    mStr.tx = mRate;
    mStr.fx = mRate;
    mStr.fo = mRate;
    mStr.sl = mRate;
    mStr.ap = mRate;
end
%%
tFrameRef = worldPRef.source_parameter.temporal_positions;
tFrameTgt = worldPTgt.source_parameter.temporal_positions;
tAnchRef = [0 anchStr.timeAnchorReference' tFrameRef(end)];
tAnchTgt = [0 anchStr.timeAnchorTarget' tFrameTgt(end)];
ftAnchorRef = anchStr.timeFreqAnchorReference;
ftAnchorTgt = anchStr.timeFreqAnchorTarget;
%
tAnchMrph = [0 cumsum(real(exp((1-mStr.tx)*log(diff(tAnchRef))+mStr.tx*log(diff(tAnchTgt)))))];
deltaT = tFrameRef(2)-tFrameRef(1);
tFrameMorph = 0:deltaT:tAnchMrph(end);
tFrameMorphOnRef = interp1(tAnchMrph,tAnchRef,tFrameMorph,"linear","extrap");
tFrameMorphOnTgt = interp1(tAnchMrph,tAnchTgt,tFrameMorph,"linear","extrap");

if displayOn
figure;
plot(tFrameMorph,tFrameMorphOnRef);grid on
hold all
plot(tFrameMorph,tFrameMorphOnTgt);
end
% fo
f0Ref = worldPRef.f0_original;
f0Tgt = worldPTgt.f0_original;
f0RefOnMrh = interp1(tFrameRef,f0Ref,tFrameMorphOnRef,"linear","extrap");
f0TgtOnMrh = interp1(tFrameTgt,f0Tgt,tFrameMorphOnTgt,"linear","extrap");
f0_original = exp((1-mStr.fo)*log(f0RefOnMrh) + mStr.fo*log(f0TgtOnMrh));
% vuv
vuvRef = worldPRef.source_parameter.vuv;
vuvTgt = worldPTgt.source_parameter.vuv;
vuvRefOnMrh = interp1(tFrameRef,vuvRef,tFrameMorphOnRef,"linear","extrap");
vuvTgtOnMrh = interp1(tFrameTgt,vuvTgt,tFrameMorphOnTgt,"linear","extrap");
vuv = (1-mStr.fo)*vuvRefOnMrh + mStr.fo*vuvTgtOnMrh;
vuv = double(vuv > 0.3);
vuv = vuv*0 + 1; % all voiced
%
if displayOn
figure;
plot(tFrameRef,f0Ref);grid on
hold all
plot(tFrameTgt,f0Tgt);grid on
plot(tFrameMorph,f0RefOnMrh,"LineWidth",3)
plot(tFrameMorph,f0TgtOnMrh,"LineWidth",3)
plot(tFrameMorph,f0_original,"k","LineWidth",3)
end
% spectrum
fs = worldPRef.spectrum_parameter.fs;
spectrogramRef = real(10*log10(worldPRef.spectrum_parameter.spectrogram));
spectrogramTgt = real(10*log10(worldPTgt.spectrum_parameter.spectrogram));
fxRef = (0:size(spectrogramRef,1)-1)'/size(spectrogramRef,1)*fs/2;
fxTgT = (0:size(spectrogramRef,1)-1)'/size(spectrogramRef,1)*fs/2;
fxMorphR = fxRef/((1-mStr.fx) + mStr.fx*vtl_ratio);
fxMorphT = fxTgT/((1-mStr.fx) + mStr.fx/vtl_ratio);
%
nAnch = size(ftAnchorRef,2);
fxMorphMapRef = zeros(size(spectrogramRef,1),nAnch+2);
fxMorphMapRef(:,1) = fxMorphR;
fxMorphMapRef(:,end) = fxMorphR;
fxMorphMapTgt = zeros(size(spectrogramRef,1),nAnch+2);
fxMorphMapTgt(:,1) = fxMorphT;
fxMorphMapTgt(:,end) = fxMorphT;
for ii = 1:nAnch
    nfC = sum(ftAnchorRef(:,ii)>0);
    if nfC > 0
        tmpLogFanchRef = log([1 ftAnchorRef(1:nfC, ii)' fs/2]);
        tmpLogFanchTgt = log([1 ftAnchorTgt(1:nfC, ii)' fs/2/vtl_ratio]);
        fAncMrph = exp(cumsum([log(1) real(exp((1-mStr.fx)*log(diff(tmpLogFanchRef)) ...
            +mStr.fx*log(diff(tmpLogFanchTgt))))]));
        %fxLinOnMrph = (0:size(spectrogramRef,1)-1)'/size(spectrogramRef,1)*fAncMrph(end);
        fxMrphOnTgt = interp1(exp(tmpLogFanchTgt),fAncMrph,fxRef, ...
            "linear","extrap");
        fxMrphOnRef = interp1(exp(tmpLogFanchRef),fAncMrph,fxRef, ...
            "linear","extrap");
        %[~, tRefIdx] = min(abs(anchStr.timeAnchorReference(ii)-tFrameRef));
        fxMorphMapRef(:,ii+1) = fxMrphOnRef;
        %[~, tTgtIdx] = min(abs(anchStr.timeAnchorTarget(ii)-tFrameTgt));
        fxMorphMapTgt(:,ii+1) = fxMrphOnTgt;
    else
        fxMorphMapRef(:,ii+1) = fxMorphR;
        fxMorphMapTgt(:,ii+1) = fxMorphT;
    end
end
%
nFrameMorph = length(tFrameMorph);
%specgramMorph = zeros(length(fxRef), nFrameMorph);
%apMroph = zeros(length(fxRef), nFrameMorph);
prevInd = 1;
segHead = zeros(nAnch,1);
segHead(1) = 1;
for ii = 1:nFrameMorph
    if tFrameMorph(ii) > tAnchMrph(prevInd)
        prevInd = prevInd + 1;
        segHead(prevInd) = ii;
    end
end
%
idxOnMorph = floor(tAnchMrph/deltaT)+1;
%idxOnRef = floor(tAnchRef/deltaT)+1;
%idxOnTgt = floor(tAnchTgt/deltaT)+1;
%
fxMorphMapRefIntrp = zeros(length(fxRef), nFrameMorph);
fxMorphMapTgtIntrp = zeros(length(fxRef), nFrameMorph);
fxMorphMapMixIntrp = zeros(length(fxRef), nFrameMorph);
spectrogramRefOnTFMrh = zeros(length(fxRef), nFrameMorph);
spectrogramTgtOnTFMrh = zeros(length(fxRef), nFrameMorph);
spectrogramTgt(end,:) = spectrogramTgt(end-1,:);
spectrogramRef(end,:) = spectrogramRef(end-1,:);
spectrogramRefOnMrh = interp1(tFrameRef',spectrogramRef',tFrameMorphOnRef',"linear","extrap")';
spectrogramTgtOnMrh = interp1(tFrameTgt',spectrogramTgt',tFrameMorphOnTgt',"linear","extrap")';
spectrogramMixOnTFMrh = spectrogramTgtOnTFMrh * 0;
aperiodicityRef = real(log(worldPRef.source_parameter.aperiodicity));
aperiodicityTgt = real(log(worldPTgt.source_parameter.aperiodicity));
aperiodicityRefOnMrh = interp1(tFrameRef',aperiodicityRef',tFrameMorphOnRef',"linear","extrap")';
aperiodicityTgtOnMrh = interp1(tFrameTgt',aperiodicityTgt',tFrameMorphOnTgt',"linear","extrap")';
aperiodicityRefOnTFMrh = zeros(length(fxRef), nFrameMorph);
aperiodicityTgtOnTFMrh = zeros(length(fxRef), nFrameMorph);
aperiodicityMixOnTFMrh = spectrogramTgtOnTFMrh * 0;
for ii = 1:nAnch+1
    strtP = idxOnMorph(ii);
    if ii == nAnch
        endP = nFrameMorph;
    else
        endP = idxOnMorph(ii+1);
    end
    for jj = strtP:endP
        fractionV = (tFrameMorph(jj) - tFrameMorph(strtP)) ...
            /(tFrameMorph(endP)-tFrameMorph(strtP));
        fxMorphMapRefIntrp(:, jj) = (1-fractionV) * fxMorphMapRef(:,ii) ...
            + fractionV * fxMorphMapRef(:,ii+1);
        fxMorphMapTgtIntrp(:, jj) = (1-fractionV) * fxMorphMapTgt(:,ii) ...
            + fractionV * fxMorphMapTgt(:,ii+1);
        fxMorphMapMixIntrp(:, jj) = (1-mStr.fx) * fxMorphMapRefIntrp(:, jj) ...
            + mStr.fx * fxMorphMapTgtIntrp(:, jj);
        spectrogramRefOnTFMrh(:, jj) = interp1(fxMorphMapRefIntrp(:, jj), spectrogramRefOnMrh(:, jj), fxRef, "linear","extrap");
        spectrogramTgtOnTFMrh(:, jj) = interp1(fxMorphMapTgtIntrp(:, jj), spectrogramTgtOnMrh(:, jj), fxRef, "linear","extrap");
        spectrogramMixOnTFMrh(:, jj) = (1-mStr.sl) * spectrogramRefOnTFMrh(:, jj) ...
            + mStr.sl * spectrogramTgtOnTFMrh(:, jj);
        aperiodicityRefOnTFMrh(:, jj) = interp1(fxMorphMapRefIntrp(:, jj), aperiodicityRefOnMrh(:, jj), fxRef, "linear","extrap");
        aperiodicityTgtOnTFMrh(:, jj) = interp1(fxMorphMapTgtIntrp(:, jj), aperiodicityTgtOnMrh(:, jj), fxRef, "linear","extrap");
        aperiodicityMixOnTFMrh(:, jj) = (1-mStr.ap) * aperiodicityRefOnTFMrh(:, jj) ...
            + mStr.ap * aperiodicityTgtOnTFMrh(:, jj);
    end
end
%%
spectrogram = 10.0 .^ (spectrogramMixOnTFMrh/10);
%% aperiodicity
aperiodicity = exp(aperiodicityMixOnTFMrh);
%% modify aperiodicity
originalAperiodicity = aperiodicity;
f0_original(f0_original <= 0) = min(f0_original(f0_original > 30));
f0_original(isnan(f0_original)) = min(f0_original(f0_original > 30));
averageFo = mean(f0_original);
fxTmp = fxRef(fxRef<3*averageFo);
apShaper = ones(length(fxTmp),1);
apShaper(1:length(fxTmp)) = 0.5*cos((fxTmp-averageFo)/averageFo/2*pi)+0.5;
apShaper(fxTmp<=averageFo) = 1;
apShaper = 10 .^ (-60*apShaper/10);
for ii = 1:size(aperiodicity,2)
    aperiodicity(1:length(fxTmp),ii) = aperiodicity(1:length(fxTmp),ii) .* apShaper;
end
%%
output.samplingFrequency = worldPRef.samplingFrequency;
output.f0_original = f0_original;
output.source_parameter.temporal_positions = tFrameMorph;
output.source_parameter.f0 = f0_original .* vuv;
output.spectrum_parameter.temporal_positions = tFrameMorph;
output.spectrum_parameter.fs = worldPRef.samplingFrequency;
output.source_parameter.vuv = vuv;
output.spectrum_parameter.spectrogram = spectrogram;
output.source_parameter.aperiodicity = aperiodicity;
output.morphingRateStructure = mStr;
%%
output.elapsedTime = toc(strtTic);
end