function output = twoWayMultiAttributeMorphing(mObjectEntity1, mObjectEntity2, morphRate)
% output = twoWayMultiAttributeMorphing(mObjectEntity1, mObjectEntity2, morphRate)
% Two way multi attribute morphing function
%
% Arguments
%    mObjectEntity1 : morphing object identifier (structure or string)
%    mObjectEntity2 : morphing object identifier (structure or string)
%    morphRate      : morphing rate definition (scalar or structure)
% note:
%    morphing object structure consists of following fields
%       worldParameter  : structure consisting of WORLD parameter
%       timeAnchor      : vector defining time anchor position
%       timeFreqAnchor  : matrix defining time-frequency position
%    morphing object identifier string is the fullpath to the .mat file
%    consisting of a morphing object
%    When morphRate is a structure, it consists of following fields
%       tx  : time axis morphing rate
%       fx  : frequency axis morphing rate
%       fo  : fundamental frequency morphing rate
%       sl  : spectrum level morphing rate
%       ap  : aperiodicity morphing rate
%    morphing rate defines contributions of two entities.
%    morphing rate 0 uses parameters in mObjectEntity1 only
%    morphing rate 1 uses parameters in mObjectEntity2 only
%
% Output
%    output  : structure consitsing of following fields
%       elapsedTime   : elapsed time
%       morphOutStr   : morphed WORLD parameter
%       xSynth        : vector consisting of the morphed sound
%       samplingFrequency  : in Hz

%-- Check first and second input arguments
if isstruct(mObjectEntity1)
    mObject1 = mObjectEntity1;
elseif isstring(mObjectEntity1)
    try
    mObject1 = load(mObjectEntity1);
    if ~isstruct(mObject1)
        disp("Input file should consist of morphing object structure.")
        help("twoWayMultiAttributeMorphing");
        output = [];
        return;
    end
    catch
        disp("file " + mObjectEntity1 + " does not exist")
        help("twoWayMultiAttributeMorphing");
        output = [];
        return;
    end
else
    help("twoWayMultiAttributeMorphing");
    output = [];
    return;
end
if isstruct(mObjectEntity2)
    mObject2 = mObjectEntity2;
elseif isstring(mObjectEntity2)
    try
    mObject2 = load(mObjectEntity2);
    if ~isstruct(mObject2)
        disp("Input file should consist of morphing object structure.")
        help("twoWayMultiAttributeMorphing");
        output = [];
        return;
    end
    catch
        disp("file " + mObjectEntity2 + " does not exist")
        help("twoWayMultiAttributeMorphing");
        output = [];
        return;
    end
else
    help("twoWayMultiAttributeMorphing");
    output = [];
    return;
end
%-- Initialize parameters
startTic = tic;
displayOn = 0;
vtl_ratio = 1;
worldPRef = mObject1.worldParameter;
worldPTgt = mObject2.worldParameter;

anchStr = struct;
anchStr.timeAnchorReference = mObject1.timeAnchor;
anchStr.timeAnchorTarget = mObject2.timeAnchor;
anchStr.timeFreqAnchorReference = mObject1.timeFreqAnchor;
anchStr.timeFreqAnchorTarget = mObject2.timeFreqAnchor;
%-- Check morphing object compatibility

%-- Morphing parameters and synthesize morphed sound
morphOutStr = ...
    wordTV2WmorphingEngineRev(worldPRef, worldPTgt, anchStr, morphRate, vtl_ratio, displayOn);
xSynth = Synthesis(morphOutStr.source_parameter, morphOutStr.spectrum_parameter);

%-- Copy to output structure
output.elapsedTime = toc(startTic);
output.morphOutStr = morphOutStr;
output.xSynth = xSynth;
output.samplingFrequency = worldPRef.samplingFrequency;