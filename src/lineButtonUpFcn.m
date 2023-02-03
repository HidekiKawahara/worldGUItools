function lineButtonUpFcn(src, ~)
%get(src)
set(src, 'WindowButtonUpFcn', '', 'WindowButtonMotionFcn', '');
lineHandle = get(src, 'UserData');
lineHandle.LineWidth = 0.5;
lineStatus = get(lineHandle,'UserData');
lineStatus.replayHandle.Enable = 'off';
end