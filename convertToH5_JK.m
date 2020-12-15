function [] = convertToH5_JK(sessionName,targetDir,optotuneRingingTime,varargin)
% from 'convertToH5', add 'targetDir' to save the image in a different disk
% drive 2020/11/29 JK
% loadBuffer as an option to limit the memory handled each time 2020/12/10 JK
% Allocate upper and lower volume separately for spontaneous and piezo
% sessions 2020/12/10 JK

    if ~strcmp(targetDir(end), '\')
        targetDir = [targetDir,'\'];
    end
    
    if nargin > 3
        loadBuffer = varargin{1};
    else
        loadBuffer = [];
    end
    
    % session name definition
    sessionID = strsplit(sessionName, '\');
    sessionID = sessionID{end};
    sessionInfo = strsplit(sessionID,'_');
    sessionNum = str2double(sessionInfo{2}); % in case of spontaneous and piezo, there are only 4 planes. Need to identify if it was upper or lower volume (by the evenness of the session #)
    
    % for a given session load the trials
    trials = load([sessionName '.trials'],'-mat'); % sometimes importdata just doesn't work
    load([sessionName, '.mat'], 'info')
    
    % vars
    nPlanes = length(trials.frame_to_use);
    yStart = round(optotuneRingingTime/ (1000/info.resfreq) *(2-info.scanmode));
    xStart = 100;
    xDeadband = 10;

    framePlanes = trials.frame_to_use; % 2020/12/02 JK

    % extract frames for each plane and save
    for i = 1:nPlanes
        if sessionNum > 1000 % spontaneous or piezo, where only upper or lower volume was imaged
           if mod(sessionNum,2) % odd, upper volume
               planeNum = i;
           else % even, lower volume
               planeNum = i+4;
           end
        else
            planeNum = i;
        end
       planeDir = fullfile(targetDir, ['plane_' num2str(planeNum)]);
       mkdir(planeDir);
       planeFile = fullfile(planeDir, [sessionID, '_plane_', num2str(planeNum), '.h5']);
       nFrames = length(framePlanes{i});
       frameCounter = 1;
       
       testFrame = squeeze(jksbxreadframes_4h5c(sessionName, 1, 1));
       testFrame = testFrame(yStart:end, xStart : end-xDeadband, :);

       if ~isfile(planeFile)
           h5create(planeFile, '/data', [size(testFrame, 1), size(testFrame, 2) nFrames], 'DataType', 'uint16', 'ChunkSize',[size(testFrame,1) size(testFrame,2) 1]) % chunking would be better with each separate image frame
           % load
           if ~isempty(loadBuffer) % in case where load buffer is specified
               while frameCounter < nFrames
                   readWindow = frameCounter:(frameCounter+loadBuffer-1);
                   if (readWindow(end) > nFrames)
                      readWindow = frameCounter:nFrames; 
                   end

                   q = squeeze(jksbxreadframes_4h5c(sessionName, framePlanes{i}(readWindow), 1));
                   q = q(yStart:end, xStart : end-xDeadband, :);

                   % save

                   h5write(planeFile,'/data',q,[1, 1, frameCounter],[size(q, 1), size(q, 2), length(readWindow)]);
                   frameCounter = frameCounter + loadBuffer;
               end
           else
               wholeData = squeeze(jksbxreadframes_4h5c(sessionName, framePlanes{i}, 1));
               wholeData = wholeData(yStart:end, xStart:end-xDeadband,:);
               h5write(planeFile,'/data',wholeData)
           end
       end
    end
end

