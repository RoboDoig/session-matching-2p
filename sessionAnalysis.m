clear all; close all; clc;

%% params
plane = 1;
baseDir = 'E:\027\';
suite2pDir = 'E:\027_Training\027\';

%% get converted sessions
sessionNames = {dir([suite2pDir, '\plane_' num2str(plane), '\*.h5']).name};
for s = 1:length(sessionNames)
   sessionNames{s} = sessionNames{s}(1:11); 
end
nSessions = length(sessionNames);

%% get frame planes for each session
frameFiles = {dir([baseDir, '*.trials']).name};
sessionVars = {};
framePlanes = cell(1,nSessions);
sessionTrialInfo = cell(1,nSessions);
nFrames = nan(1,nSessions);
for i = 1:length(sessionNames)
   sessionVars{i} = frameFiles{find(cellfun(@(s) ~isempty(strfind(s, sessionNames{i})), frameFiles) == 1)};
   sessionTrialInfo{i} = importdata(fullfile(baseDir, sessionVars{i}));
   framePlanes{i} = sessionTrialInfo{i}.frame_to_use{plane};
   nFrames(i) = length(framePlanes{i});
end
sessionMarker = cumsum(nFrames);

%% load combined fluorescence (plane n)
fall = load(fullfile(suite2pDir, ['plane_' num2str(plane) '\suite2p\plane0\Fall.mat']));
goodCellIdx = find(fall.iscell(:, 1) == 1);
fs = fall.ops.fs;
F = fall.F(goodCellIdx, :);
Fneu = fall.Fneu(goodCellIdx, :);
spks = fall.spks(goodCellIdx, :)./fs;
baseLine = nan(size(F, 1), size(F, 2));
dff = nan(size(F, 1), size(F, 2));

%% condition fluorescence
sM = [1, sessionMarker];
for i = 1:size(F, 1)
   thisF = F(i, :);
   for s = 2:length(sM)
      thisFSession = thisF(sM(s-1):sM(s));
      baseLine(i, sM(s-1):sM(s)) = mean(thisFSession(thisFSession<(prctile(thisFSession, 20))));
   end
   
   dff(i,:) = (thisF - baseLine(i,:)) ./ baseLine(i,:);
end

% test figure
plot(F(1,:), 'k'); hold on;
plot(baseLine(1,:), 'r', 'LineWidth', 1.5);
for i = 1:length(sessionMarker)
   plot([sessionMarker(i), sessionMarker(i)],[0, 10000], 'b--', 'LineWidth', 2) 
end

%% convert trial markers
allStartFrames = [];
allStopFrames = [];

for s = 1:length(sessionTrialInfo)
   trialInfo = sessionTrialInfo{s};
   globalFrames = trialInfo.frame_to_use{plane};
   
   if (plane < 5)
       trialsToUse = trialInfo.layer_trials{1};
   else
       trialsToUse = trialInfo.layer_trials{2};
   end
   
   startFrames = [];
   stopFrames = [];
   for t = 1:length(trialsToUse)
       if trialsToUse(t) < trialInfo.trials(end).trialnum
           trialFrames = trialInfo.trials([trialInfo.trials.trialnum] == trialsToUse(t)).frames;
           startFrame = find(globalFrames>=trialFrames(1), 1); % first frame that occurs after trial start
           stopFrame = find(globalFrames>=trialFrames(2), 1); % first frame that occurs after trial stop

           if (~isempty(startFrame) && ~isempty(stopFrame))
               startFrames(t) = startFrame;
               stopFrames(t) = stopFrame;
           end
       end
   end
   
   offset = [0 sessionMarker(1:end-1)];
   allStartFrames = [allStartFrames startFrames + (offset(s))];
   allStopFrames = [allStopFrames stopFrames + (offset(s))];
end

% check
figure;
plot(dff(1,:), 'k'); hold on;
for t = 1:length(allStartFrames)
   plot([allStartFrames(t) allStopFrames(t)], [0 1], 'b--') 
end
