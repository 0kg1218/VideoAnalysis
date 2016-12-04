%read video and generate frame
function step3_filter_videos_with_session()


%get all the files
in_filename1 = './analysis_videonames/name_map.mat';
in_filename2 = './filtered_videonames/group_map.mat';
out_filename1 = './filtered_videonames_with_session/group_map.mat';
out_filename2 = './filtered_videonames_with_session/group_map.csv';
out_filename3 = './filtered_videonames_with_session/big_videos.txt';
load(in_filename1);
load(in_filename2);

video_to_session_map = containers.Map('KeyType', 'char', 'ValueType', 'char');
keys = name_map.keys();
for idx = 1:length(keys)
    key = keys{idx};
    values = name_map(key);
    for idy = 1:length(values)
        value = values{idy};
        video_to_session_map(value) = key;
    end
end

fcsv = fopen(out_filename2, 'wt');
fprintf(fcsv,'Group_ID,Video_Index,Room,Session,Performer,Video_Name, Frame_Num\n');
fclose(fcsv);

fbig = fopen(out_filename3, 'wt');
fprintf(fbig,'video_names\n');
fclose(fbig);

group_map_copy = group_map;
group_map = containers.Map('KeyType', 'int32', 'ValueType', 'any');
group_keys = group_map_copy.keys();
new_group_idx = 1;
for idx = 1:length(group_keys)
    group_key = group_keys{idx};
    values = group_map_copy(group_key);
    video_names = values{1};video_length = values{2};
    for idy = 1:length(video_names)
        value = video_names{idy};
        session = video_to_session_map(value);
        %Room,Session,Performer
        ids = strsplit(session, '_');
        frame_idx_cell = process_video_frame_index(values);
        group_map(new_group_idx) = [{video_names}, {video_length}, {frame_idx_cell'}, ids(1), ids(2), ids(3)];
        big_video_idx = predict_large_video(cell2mat(video_length));
        for idz = 1:length(big_video_idx)
            fbig = fopen(out_filename3, 'at');
            fprintf(fbig,'%s\n', video_names{big_video_idx(idz)});
            fclose(fbig);
        end
        for idz = 1:length(video_names)
            video_name = video_names{idz};
            frame_number = video_length{idz};
            fcsv = fopen(out_filename2, 'at');
            fprintf(fcsv, '%d,%d,%s,%s,%s,%s,%d\n', new_group_idx, idz, ids{1}, ids{2}, ids{3}, video_name, frame_number);
            fclose(fcsv);
        end
        
        new_group_idx = new_group_idx+1;
        break;
    end
end
save(out_filename1, 'group_map');


function big_video = predict_large_video(video_length)
big_video_length = 200000;
big_video = find(video_length>big_video_length);

function frame_idx_cell = process_video_frame_index(video_info)
frame_rate = 12;
video_frames = cell2mat(video_info{2});
cum_frame_num = cumsum(video_frames);
cum_frame_num = [0 cum_frame_num];
cum_frame_num(end) = floor(cum_frame_num(end)/frame_rate)*frame_rate;%elliminate those less than 1 seconds
seg_idx = floor((cum_frame_num-frame_rate/2)/frame_rate)+1;
seg_frame_idx = frame_rate/2:frame_rate:floor(sum(video_frames)/frame_rate)*frame_rate;
frame_idx_cell = cell(length(seg_idx)-1,1);
for idx = 2:length(seg_idx)
    frame_idx = seg_frame_idx(seg_idx(idx-1)+1:seg_idx(idx));
    frame_idx = frame_idx - cum_frame_num(idx-1);
    frame_idx_cell{idx-1} = frame_idx;
end