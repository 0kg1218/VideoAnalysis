%read video and generate frame
function step2_filter_videos(group_index, batch_index)

if nargin<1
    group_index = 1;
    batch_index = 1000000;
end

%get all the files
in_filename = './analysis_videonames/name_map.mat';
load(in_filename);
keyset = keys(name_map);

%output group
group_map = containers.Map('KeyType', 'int32', 'ValueType', 'any');
groupfile = './filtered_videonames/group_map.csv';
group_mat = './filtered_videonames/group_map.mat';
logfile = './filtered_videonames/log.txt';

fcsv = fopen(groupfile, 'wt');
fprintf(fcsv,'Group_ID,Video_Index,Room,Session,Performer,Video_Name, Frame_Num\n');
fclose(fcsv);
flog = fopen(logfile, 'wt');
fclose(flog);

%get group files
for index1 = group_index:min(length(keyset),batch_index)
    key = keyset{index1};%get filename
    video_names = name_map(key);
    ids = strsplit(key, '_');
    tic;
    [has_valid_video, saved_video_names, saved_video_frames] = filter_group(video_names);
    use_time = toc;
    if has_valid_video ==1
        fcsv = fopen(groupfile, 'at');
        for idx = 1:length(saved_video_names)
            video_name = saved_video_names{idx};
			frame_number = saved_video_frames{idx};
            fprintf(fcsv, '%d,%d,%s,%s,%s,%s,%d\n', group_index, idx, ids{1}, ids{2}, ids{3}, video_name, frame_number);
        end
        fclose(fcsv);
        group_map(group_index) = {saved_video_names, saved_video_frames};
        save(group_mat, 'group_map');
        flog = fopen(logfile, 'at');
        fprintf(flog, 'group %05d, %d videos, %d frames, use time %04f seconds\n', group_index, length(saved_video_names), sum(cell2mat(saved_video_frames)), use_time);
        fclose(flog);
        group_index = group_index + 1;
    end
end


function [has_valid_video, saved_video_names, saved_video_frames] = filter_group(video_names)
% inDir = '/media/mozat/Seagate Backup Plus Drive/live broadcast/videos';
inDir = 'F:/live broadcast/videos';
minimal_length = 10;
has_valid_video = 0;
saved_video_names = {};
saved_video_frames = {};
saved_video_idx = 1;
for v = 1:length(video_names)
    video_name = fullfile(inDir, video_names{v});
    xyloObj = read_video(video_name);
    if xyloObj~=0
        has_valid_video = 1;
        video_info = read_video_info(xyloObj);
        if video_info.nFrames<(video_info.frameRate*minimal_length)
            continue
        end
        saved_video_names{saved_video_idx} = video_names{v};
		saved_video_frames{saved_video_idx} = video_info.nFrames;
        saved_video_idx = saved_video_idx + 1;
    else
        errfile = './filtered_videonames/err.txt';
        ferrlog = fopen(errfile, 'at');
        fprintf(ferrlog, 'error video: %s\n', video_names{v});
        fclose(ferrlog);
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
