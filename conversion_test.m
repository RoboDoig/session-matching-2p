% compare random pairs of images from .sbx and .h5 
% to confirm correct conversion
testi = 19;

session = sessions(testi);
imagingi = 0; % 0 or 1. most of the cases, it's 0.
if session < 1000
    fnSbx = sprintf('%s%03d\\%03d_%03d_%03d',baseDir,mouse,mouse,session,imagingi);
else
    fnSbx = sprintf('%s%03d\\%03d_%d_%03d',baseDir,mouse,mouse,session,imagingi);
end

load([fnSbx,'.trials'],'-mat');

%%
planei = 3;
framei = 1053;

if session < 1000
    fnH5 = sprintf('%s%03d\\plane_%d\\%03d_%03d_%03d_plane_%d.h5',targetBD,mouse,planei,mouse,session,imagingi,planei);
else
    fnH5 = sprintf('%s%03d\\plane_%d\\%03d_%d_%03d_plane_%d.h5',targetBD,mouse,planei,mouse,session,imagingi,planei);
end
dataH5 = h5read(fnH5,'/data');

imH5 = dataH5(:,:,framei);
szy = size(imH5,1);

sbxi = frame_to_use{planei}(framei);

imSbx = sbxread(fnSbx, sbxi, 1);
imSbx = squeeze(imSbx(1,end-szy+1:end,100:end-10,1));

compare(imSbx,imH5)
