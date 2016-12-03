%read video and generate frame
function step3_filter_videos_with_session()


%get all the files
in_filename1 = './analysis_videonames/name_map.mat';
in_filename2 = './filtered_videonames/group_map.mat';
out_filename1 = './filtered_videonames_with_session/group_map.mat';
out_filename2 = './filtered_videonames_with_session/group_map.csv';
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

group_map_copy = group_map;
group_map = containers.Map('KeyType', 'int32', 'ValueType', 'any');
group_keys = group_map_copy.keys();
start_idx = 1;
for idx = 1:length(group_keys)
    group_key = group_keys{idx};
    values = group_map_copy(group_key);
    video_names = values{1};video_length = values{2};
    for idy = 1:length(video_names)
        value = video_names{idy};
        session = video_to_session_map(value);
        %Room,Session,Performer
        ids = strsplit(session, '_');
        group_map(start_idx) = [video_names, video_length, ids(1), ids(2), ids(3)];
        
        for idz = 1:length(video_names)
            video_name = video_names{idz};
			frame_number = video_length{idz};
            fcsv = fopen(out_filename2, 'at');
            fprintf(fcsv, '%d,%d,%s,%s,%s,%s,%d\n', start_idx, idx, ids{1}, ids{2}, ids{3}, video_name, frame_number);
            fclose(fcsv);
        end
        
        start_idx = start_idx+1;
        break;
    end
end
save(out_filename1, 'group_map');