function step5_genearte_frame()
%we had better not to use this code, as it is very low effiency
%get all the files
in_filename = './filtered_videonames_with_session/group_map.mat';
load(in_filename);
%write log
global logfile;
logfile = './frames/runlog.txt';
flog = fopen(logfile, 'wt');
fclose(flog);
global errfile;
errfile = './frames/err.txt';
ferr = fopen(errfile, 'wt');
fclose(ferr);
%group_id
group_ids = group_map.keys();
for idx = 1:length(group_ids)
    group_id = group_ids{idx};
     process_videos_group(group_map(group_id), group_id);
end


function process_videos_group(video_info, group_id)
if exist('./frames/finished_group.mat', 'file')
    load('./frames/finished_group.mat');
else
    finished_group = containers.Map();
end
if isKey(finished_group, sprintf('%05d', group_id))
    return;
end
video_names = video_info{1};
out_dir = sprintf('./frames/%05d', group_id);
if ~exist(out_dir,'dir')
    mkdir(out_dir);
end
frame_idx_cell = video_info{3};
[video_num, total_frames] = read_videos_by_frame(video_names, frame_idx_cell', out_dir);
save(fullfile(out_dir, 'video_process_info.mat'), 'frame_idx_cell', 'total_frames');
finished_group(sprintf('%05d', group_id)) = 1;
save('./frames/finished_group.mat', 'finished_group');
global logfile;
flog = fopen(logfile, 'at');
fprintf(flog,'group id: %d: %d videso processed with %d frames\n', group_id, video_num, total_frames);
fclose(flog);

function [processed_num, total_frame] = read_videos_by_frame(video_names, frame_idx_cell, out_dir)
video_base_dir = 'F:/live broadcast/videos';
batch_size = 20;
videos_per_row = 5;
processed_num = 0;
video_info = read_video_info(read_video(fullfile(video_base_dir, video_names{1})));
imgs = zeros(video_info.img_height*batch_size/videos_per_row, video_info.img_width*videos_per_row, 3, 'uint8');
start_idx = 0;
write_img_idx = 1;
total_frame = 0;
for idx = 1:length(video_names)
    video_name = fullfile(video_base_dir, video_names{idx});
    frame_idx = frame_idx_cell{idx};
    xyloObj = read_video(video_name);
    for idy = 1:length(frame_idx)        
        img = read_frame(xyloObj, frame_idx(idy));
        total_frame = total_frame + 1;
        col_start = floor(start_idx/videos_per_row);
        row_start = mod(start_idx, videos_per_row);
        imgs(col_start*video_info.img_height+1:(col_start+1)*video_info.img_height, row_start*video_info.img_width+1:(row_start+1)*video_info.img_width, :) = img;
        start_idx = start_idx + 1;
        if mod(start_idx,batch_size) == 0 && start_idx~=0
            filename = fullfile(out_dir, sprintf('%05d.jpg', write_img_idx));
            imwrite(imgs, filename);
            imgs(:) = 0;
            start_idx = 0;
            write_img_idx = write_img_idx + 1;
        end
    end
    processed_num = processed_num + 1;
end

if start_idx~=0
    filename = fullfile(out_dir, sprintf('%05d.jpg', write_img_idx));
    imwrite(imgs, filename);
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

function img = read_frame(xyloObj, frame_idx)
bias = [0, -1, -2, 1, 2];
for idx = 1:length(bias)
    try
        img = read(xyloObj, frame_idx+bias(idx));
        break;
    catch
        img = -1;
    end
end
if img == -1
    global errfile;
    img = read(xyloObj, 1);
    ferr = fopen(errfile, 'at');
    fprintf(ferr, 'video, %d, %s\n', frame_idx, xyloObj.Name);
    fclose(ferr);
end
