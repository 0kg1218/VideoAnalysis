%read video and generate frame
function step4_genearte_frame()

%get all the files
in_filename = './filtered_videonames_with_session/group_map.mat';
load(in_filename);
keyset = keys(name_map);

%write headers of output group
newfile = './frames/new_map.csv';
if ~exist('./frames/new_map.mat', 'file')
    fcsv = fopen(newfile, 'wt');
    fprintf(fcsv,'Group_ID,Video_Index,Room,Session,Performer,Video_Name\n');
    fclose(fcsv);
    processed_group = containers.Map('KeyType', 'int', 'ValueType', 'any');
else
    load('./frames/new_map.mat');
end

%write log
logfile = './frames/runlog.txt';
flog = fopen(logfile, 'wt');
fclose(flog);

%get group files
for index1 = group_index:length(keyset)
    if processed_group.has_key(sprintf('%05d', group_index))
        continue;
    end
    key = keyset{index1};%get filename
    video_names = name_map(key);
    ids = strsplit(key, '_');
    tic;
    [has_valid_video, saved_video_names] = process_group(video_names, group_index);
    use_time = toc;
    if has_valid_video ==1
        fcsv = fopen(newfile, 'at');
        for idx = 1:length(saved_video_names)
            video_name = saved_video_names{idx};
            fprintf(fcsv, '%d,%d,%s,%s,%s,%s\n', group_index, idx, ids{1}, ids{2}, ids{3}, video_name);
        end
        fclose(fcsv);
        processed_group(sprintf('%05d', group_index)) = 1;
        save('./frames/new_map.mat', 'processed_group');
        flog = fopen(logfile, 'at');
        fprintf(flog, 'group %05d, use time %04f seconds\n', group_index, use_time);
        fclose(flog);
        group_index = group_index + 1;
    end
end


function [has_valid_video, saved_video_names] = process_group(video_names, group_id)
% inDir = '/media/mozat/Seagate Backup Plus Drive/live broadcast/videos';
inDir = 'F:/live broadcast/videos';
offset = 0;
has_valid_video = 0;
saved_video_names = {};
saved_video_idx = 1;
for v = 1:length(video_names)
    video_name = fullfile(inDir, video_names{v});
    xyloObj = read_video(video_name);
    if xyloObj~=0
        has_valid_video = 1;
        video_info = read_video_info(xyloObj);
        if video_info.nFrames<(video_info.frameRate*5)
            continue
        end
        [select_idx, offset, imgdata] = read_frames(xyloObj, video_info, offset);
        if ~exist(fullfile('./frames', sprintf('%05d', group_id)), 'dir')
            mkdir(fullfile('./frames', sprintf('%05d', group_id)));
        end
        mat_name = fullfile('./frames', sprintf('%05d/%02d.mat', group_id, saved_video_idx));
        save(mat_name,'select_idx', 'imgdata');
        saved_video_names{saved_video_idx} = video_names{v};
        saved_video_idx = saved_video_idx + 1;
    else
        fp = fopen('./frames/error.txt', 'at');
        fprintf(fp, 'error video: %s\n', video_name);
        fclose(fp);
    end
end

function xyloObj = read_video(video_name)
try
    xyloObj = VideoReader(video_name);
catch
    xyloObj = 0;
end

function video_info = read_video_info(xyloObj)
video_info = {};
video_info.img_width = xyloObj.Width;
video_info.img_height = xyloObj.Height;
video_info.frameRate = round(xyloObj.FrameRate);
video_info.select_idx = round(video_info.frameRate/2);
video_info.nFrames = xyloObj.NumberOfFrame;

function [select_idx, new_offset, imgdata] = read_frames(xyloObj, video_info, offset)
select_idx = zeros(floor(video_info.nFrames/video_info.frameRate)+1,1);
idx = 1;
for k = 1:video_info.nFrames
    if mod(k+offset-video_info.select_idx, video_info.frameRate) == 0
        select_idx(idx) = k; %keep the index in this video
        idx = idx + 1;
    end
end
select_idx = select_idx(1:idx-1);
if(select_idx(end)==video_info.nFrames)%we do a approximiation which does not affect much
    select_idx(end) = select_idx(end)-1;
end
new_offset = video_info.nFrames+offset;
imgdata = cell(length(select_idx), 1);
for k = 1:length(select_idx)
    img = read(xyloObj, select_idx(k));
    imgdata{k} = img;
end
