clear; close all; 

optotuneRingingTime = 8; % in ms. To crop top portion of each frame.

baseDir = 'P:\';
mouse = 38;
sessions = [1:28,901,5554,55559998,9999];

targetBD = 'D:\TPM\JK\h5\';
targetDir = sprintf('%s%03d\\',targetBD,mouse);

% for si = 1 : length(sessions)
%     if sessions(si) < 1000
%         sbxList = ls(sprintf('%s%03d\\%03d_%03d_0*.sbx',baseDir,mouse,mouse,sessions(si)));
%     else
%         sbxList = ls(sprintf('%s%03d\\%03d_%d_*.sbx',baseDir,mouse,mouse,sessions(si)));
%     end
%     for sbxi = 1 : size(sbxList,1)
%         tempFn = strsplit(sbxList(sbxi,:),'.');
%         sbxFn = tempFn{1}; % removing '.sbx'
%         fn = sprintf('%s%03d\\%s',baseDir,mouse,sbxFn);
%         if floor(sessions(si)/1000) == 5 % spontaneous
%             laserOnFrames = laser_on_frames(fn);
%             jksbxsplittrial_4h5c(fn,laserOnFrames)
%         elseif floor(sessions(si)/1000) == 9 % piezo & passive pole (x1x)
%             tempTrial = strsplit(sbxFn,'_');
%             trialNum = num2str(tempTrial{end});
%             flag = 1 - str2double(trialNum(2)); % 1 if piezo, 0 if passive pole
%             if flag % only piezo deflection, not passive pole presentation.
%                 laserOnFrames = laser_on_frames(fn);
%                 jksbxsplittrial_4h5c(fn,laserOnFrames, 'piezo')
%             end
%         elseif sessions(si) < 1000
%             jksbxsplittrial_4h5c(fn) % run this again, making .trial files
%         else
%             error('Wrong session #')
%         end
%         
%         if isfile([fn,'.trials'])
%             convertToH5_JK(fn,targetDir,optotuneRingingTime)
%         end
%     end
% end
% 


%% Check results
%% (1) Test file size. Planes 1-4 from a session should have the same file size, and planes 5-8 should do too.
%% Sometimes the file sizes are different, meaning there was an error


errorSessions = [];
for si = 1 : length(sessions)
% for si = 1
    session = sessions(si);
    if session < 1000
        sbxList = ls(sprintf('%s%03d\\%03d_%03d_0*.sbx',baseDir,mouse,mouse,session));
        if mouse == 27 % mouse JK027 has only lower planes
            planes = 5:8;
        else
            planes = 1:8;
        end
    else
        sbxList = ls(sprintf('%s%03d\\%03d_%d_*.sbx',baseDir,mouse,mouse,session));
        if mod(session,2)
            planes = 1:4;
        else
            planes = 5:8;
        end
    end
    
    for sbxi = 1 : size(sbxList,1)
        tempFn = strsplit(sbxList(sbxi,:),'.');
        sbxFn = tempFn{1}; % removing '.sbx'
        temp = strsplit(sbxFn,'_');
        experiment = temp{end};
        if ~(str2double(experiment(2)) > 0 && session > 9000) % removing passive pole presentation
            % first, check if there are all files matched to each plane
            for pi = 1 : length(planes)
                if ~isfile(sprintf('%splane_%d\\%s_plane_%d.h5',targetDir,planes(pi),sbxFn,planes(pi)))
                    errorSessions = [errorSessions;session];
                    break % break pi loop
                end
            end
            if ismember(session, errorSessions)
                break
            end
            % then, check if these files have the same file size
            % after dividing into imaging volumes
            if ismember(1,planes) % upper volume, if exists
                fileSizes = zeros(4,1);
                for pi = 1 : 4
                    temp = dir(sprintf('%splane_%d\\%s_plane_%d.h5',targetDir,pi,sbxFn,pi));
                    fileSizes(pi) = temp.bytes;
                end
                if any(diff(fileSizes))
                    errorSessions = [errorSessions;session];
                    break
                end
            end
            if ismember(5,planes) % lower volume, if exists
                fileSizes = zeros(4,1);
                for pi = 5 : 8
                    temp = dir(sprintf('%splane_%d\\%s_plane_%d.h5',targetDir,pi,sbxFn,pi));
                    fileSizes(pi-4) = temp.bytes;
                end
                if any(diff(fileSizes))
                    errorSessions = [errorSessions;session];
                    break
                end
            end
        end
    end
end
errorSessions



%% (2) Check random files and random frames from each sbx file


numCheckFrames = 100;
errorSessions = [];
for si = 1 : length(sessions)
    session = sessions(si);
    if session < 1000
        sbxList = ls(sprintf('%s%03d\\%03d_%03d_0*.sbx',baseDir,mouse,mouse,session));
        if mouse == 27 % mouse JK027 has only lower planes
            planes = 5:8;
            ftuIndices = 5:8; % ftu: frame_to_use
        else
            planes = 1:8;
            ftuIndices = 1:8; % ftu: frame_to_use
        end
    else
        sbxList = ls(sprintf('%s%03d\\%03d_%d_*.sbx',baseDir,mouse,mouse,session));
        if mod(session,2)
            planes = 1:4;
            ftuIndices = 1:4; % ftu: frame_to_use
        else
            planes = 5:8;
            ftuIndices = 1:4; % ftu: frame_to_use
        end
    end
    
    for sbxi = 1 : size(sbxList,1)
        tempFn = strsplit(sbxList(sbxi,:),'.');
        sbxFn = tempFn{1}; % removing '.sbx'
        refFn = sprintf('%s%03d\\%s',baseDir,mouse,sbxFn);
        temp = strsplit(sbxFn,'_');
        experiment = temp{end};
        if ~(str2double(experiment(2)) > 0 && session > 9000) % removing passive pole presentation
            % first, check if there are all files matched to each plane
            
            trials = load([refFn,'.trials'],'-mat');
            loadedInfo = load([refFn,'.mat'],'info');

            for ftui = 1 : length(ftuIndices)
                plane = planes(ftui);
                h5Fn = sprintf('%splane_%d\\%s_plane_%d.h5',targetDir, plane, sbxFn, plane);
                numFrames = length(trials.frame_to_use{ftuIndices(ftui)});
                testFrames = randperm(numFrames,numCheckFrames);
                yStart = round(optotuneRingingTime/ (1000/loadedInfo.info.resfreq) *(2-loadedInfo.info.scanmode));
                xStart = 100;
                xDeadband = 10;

                % Load frames from sbx file (reference images)
                refImRaw = squeeze(jksbxreadframes_4h5c(refFn,trials.frame_to_use{ftuIndices(ftui)}(testFrames),1));
                refIm = refImRaw(yStart:end,xStart:end-xDeadband,:);

                % Load frames from h5 file (check images)
                checkIm = zeros(size(refIm), 'like', refIm);
                for fi = 1 : numCheckFrames
                    checkIm(:,:,fi) = h5read(h5Fn, '/data', [1 1 testFrames(fi)], [size(refIm,1), size(refIm,2), 1]);
                end

                % Compare reference images and check images
                imDiff = refIm - checkIm;
                if any(imDiff(:))
                    errorSessions = [errorSessions; session];
                    break
                end
            end
        end
    end
end
errorSessions