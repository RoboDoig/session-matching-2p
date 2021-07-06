%%
%% Manual info correction
%%
fn = '054_9998_205';
load([fn, '.mat'], 'info')
%%
tempMessages = cell(11,1);
tempMessages(2:end) = info.messages(1:10);
tempMessages{1} = '96';
info.messages = tempMessages;
%%
save([fn,'.mat'], 'info')
