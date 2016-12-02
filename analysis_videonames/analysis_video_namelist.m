function analysis_video_namelist(out_filename)
if nargin<1
    fprintf('usage: analysis_video_namelist(out_filename;\n')
    if ~strcmp(out_filename(end-3:end),'.mat')
        fprintf('out_filename must end with .mat\n');
    end
    return;
end
dpath = mfilename('fullpath');
inFile = fullfile(fileparts(dpath),'../doc/playback-all.csv');
%structure for name_map
%key: Room_Stream_Performer
%value: a list of video_names
name_map = analysis_video(inFile);
save(out_filename, 'name_map');

%added
% out_csvfile = [out_filename(1:end-4), '.csv'];
% fid = fopen(out_csvfile, 'wt+');
% keyset = keys(name_map);
% fprintf(fid,'Group_ID,Video_Index,Room,Session,Performer,Video_Name\n');
% for index = 1:length(keyset)
%     key = keyset{index};
%     value = name_map(key);
%     for index2 = 1:length(value)
%         ids = strsplit(key, '_');
%         fprintf(fid, '%d,%d,%s,%s,%s,%s\n', index, index2, ids{1}, ids{2}, ids{3}, value{index2});
%     end
% end
% fclose(fid);


function name_map = analysis_video(inFile)
M = csvimport(inFile,'columns', [1, 2, 3, 4], 'noHeader', true, 'outputAsChar', true);
M = M(2:end, :);
%http://qiubailive.ks3-cn-beijing.ksyun.com/record/live/61285850754847401/hls/61285850754847401-53568543410625422r1470845405.m3u8

name_map = containers.Map('KeyType', 'char', 'ValueType', 'any');
for i = 1:size(M, 1)
    Room = M{i, 1};
    Stream = M{i, 2};
    Performer = M{i, 3};
    name_str = sprintf('%s_%s_%s', Room, Stream, Performer);
    Link = M{i, 4};
    Link = strsplit(Link, '/');
    Link = Link{end};
    Link = sprintf('%s.mp4', Link);
    if isKey(name_map,name_str)
        value = name_map(name_str);
        value{end+1} = Link;
        name_map(name_str) = value;
    else
        value = cell(0);
        value{end+1} = Link;
        name_map(name_str) = value;
    end
end
