mice = [52,53,54,56];
targetDir = 'D:\TPM\JK\h5\';
sessions = {[9998,9999],[9998,9999],[9998,9999],[9998,9999]};
planes = 1:8;

for mi = 1 : length(mice)
    mouse = mice(mi);
    for pi = 1 : length(planes)
        plane = planes(pi);
        cd(sprintf('%s%03d\\plane_%d',targetDir, mouse, plane))
        for si = 1 : length(sessions{mi})
            session = sessions{mi}(si);
            fnList = dir(['*_', num2str(session), '_*.h5']);
            for fi = 1 : length(fnList)
                if fnList(fi).bytes < 1e+9
                    delete(fnList(fi).name)
                end
            end
        end
    end
end