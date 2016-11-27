function name_map = analysis_video_namelist(out_filename)
if nargin<1
    out_filename = 'name_map.mat';
end
dpath = mfilename('fullpath');
inFile = fullfile(fileparts(dpath),'../doc/playback-all.csv');
name_map = analysis_video(inFile);
save(out_filename, 'name_map');

%added
out_filename2 = 'name_map.csv';
fid = fopen(out_filename2, 'wt+');

keyset = keys(name_map);
fprintf(fid,'Group_ID,Room,Session,Performer,Video_Name,Video_Index\n');
for index = 1:length(keyset)
    key = keyset{index};
    value = name_map(key); 
    %fprintf(fid, '%s, {', key);
    for index2 = 1:length(value)
        ids = split(key, '_');
        fprintf(fid, '%d,%s,%s,%s,%s,%d\n', index, ids(1), ids(2), ids(3), value{index2}, index2);
    end
end

fclose(fid);
  

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
