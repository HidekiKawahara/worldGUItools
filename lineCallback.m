function lineCallback(src, ~)
lineStatus = get(src,'UserData');
currentAxisToolBar = lineStatus.axisToolbar;
onCount = 0;
for ii = 1:length(currentAxisToolBar.Children)-1
    onCount = onCount + currentAxisToolBar.Children(ii).Value;
end
if onCount == 0
    src.LineWidth = 3;
    axisHandle = src.Parent;
    tmp = axisHandle.Parent;
    switch tmp.Type
        case 'figure'
            figureHandle = tmp;
        otherwise
            tmp1 = tmp.Parent;
            figureHandle = tmp1.Parent;
    end
    set(figureHandle, 'WindowButtonUpFcn', @lineButtonUpFcn, ...
        'WindowButtonMotionFcn', @lineMotionFunction);
    set(figureHandle, 'UserData', src);
    lineStatus.InitialYData = src.YData;
    lineStatus.lastPoint = axisHandle.CurrentPoint;
    figureHandle.Tag = 'modified';
    set(src,'UserData', lineStatus);
end
end