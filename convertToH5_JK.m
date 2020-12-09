function [] = convertToH5_JK(sessionName,targetDir,optotuneRingingTime,loadBuffer)
% from 'convertToH5', add 'targetDir' to save the image in a different disk
% drive
% 2020/11/29 JK

    if ~strcmp(targetDir(end), '\')
        targetDir = [targetDir,'\'];
    end
    
    % session name definition
    sessionID = strsplit(sessionName, '\');
    sessionID = sessionID{end};

    % for a given session load the trials
    trials = importdata([sessionName '.trials']);
    load([sessionName, '.mat'], 'info')
    
    % vars
    nPlanes = length(trials.frame_to_use);
    yStart = round(optotuneRingingTime/ (1000/info.resfreq) *(2-info.scanmode));
    xStart = 100;
    xDeadband = 10;

    framePlanes = trials.frame_to_use; % 2020/12/02 JK

    % extract frames for each plane and save
    for i = 1:nPlanes
       planeDir = fullfile(targetDir, ['plane_' num2str(i)]);
       mkdir(planeDir);
       planeFile = fullfile(planeDir, [sessionID, '_plane_', num2str(i), '.h5']);
       nFrames = length(framePlanes{i});
       frameCounter = 1;
       
       testFrame = squeeze(jksbxreadframes_4h5c(sessionName, 1, 1));
       testFrame = testFrame(yStart:end, xStart : end-xDeadband, :);

       if ~isfile(planeFile)
           % load
           h5create(planeFile, '/data', [size(testFrame, 1), size(testFrame, 2) nFrames], 'DataType', 'uint16', 'ChunkSize',[size(testFrame,1) size(testFrame,2) loadBuffer])
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
       end
    end
end

