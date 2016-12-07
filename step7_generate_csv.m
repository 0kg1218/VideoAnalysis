function step7_generate_csv()
addpath('./step5_extract_frame');
addpath('./jsonlab');
addpath('./generate_skinmap');
inDir = './step5_extract_frame/frames';
dirs  = dir(inDir);
dirs = dirs(3:end);
outDir = './face_info';

% for idx = 1:length(dirs)
for idx = 4:4
    total_frame_seconds = get_frames_cnt(fullfile(inDir, dirs(idx).name));
    face_info = get_face_info(fullfile(inDir, dirs(idx).name));
    face_result = get_face_result(face_info, total_frame_seconds);
    save(fullfile(outDir, sprintf('%05d.mat', idx)), 'face_result');
    writejson('', face_result, fullfile(outDir, sprintf('%05d.json', idx)));
    write_csv_file(fullfile(outDir, sprintf('%05d.csv', idx)), face_result);
end


function total_frame_seconds = get_frames_cnt(dpath)
group_info = loadjson(fullfile(dpath, 'group_info.json'));
video_num = group_info.video_num;
total_frame_seconds = 0;
for idx = 1:video_num
    video_name = sprintf('video_%02d', idx);
    frame_idx = group_info.(video_name).frame_idx;
    total_frame_seconds = total_frame_seconds+(frame_idx(2)-frame_idx(1))/12+1;
end

function face_info = get_face_info(dpath)
face_info_struct = loadjson(fullfile(dpath, 'face_info.json'));
face_info = face_info_struct.face_info;
face_info.img_width = face_info_struct.img_width/2;
face_info.img_height = face_info_struct.img_height/2;
face_info.total_mega_imgs = face_info_struct.total_frames;
face_info.room = face_info_struct.room;
face_info.session = face_info_struct.session;
face_info.performer = face_info_struct.performer;
face_info.img_path = dpath;


function face_result = get_face_result(face_info, total_frame_seconds)
face_result = {};
face_result.face = zeros(total_frame_seconds, 1);
face_result.face_position = zeros(total_frame_seconds, 4);
face_result.expression = cell(total_frame_seconds, 1);
face_result.expression_details = cell(total_frame_seconds, 1);
face_result.hand = zeros(total_frame_seconds, 1);
face_result.hand_area = zeros(total_frame_seconds, 2);
face_result.frame_index = zeros(total_frame_seconds, 3); %mega_img_idx, y_index, x_index
face_result.total_frames = total_frame_seconds;

for mega_img_idx = 1:face_info.total_mega_imgs
    frame_idx = sprintf('x0x30_%04d',mega_img_idx);
    mega_face_info = face_info.(frame_idx);
    mega_face_img = imread(fullfile(face_info.img_path, sprintf('%05d.jpg', mega_img_idx)));
    if mega_face_info.has_face == 0 || isempty(mega_face_info.expression)
        face_result = update_no_face(face_result, mega_img_idx, total_frame_seconds);
    else
        face_result = update_with_face(face_result, mega_img_idx, mega_face_img, mega_face_info, face_info.img_width, face_info.img_height, total_frame_seconds);
    end
end


function face_result = update_no_face(face_result, mega_img_idx, total_frame_seconds)
batch_size = 20;
img_per_row = 5;
expression_keys = {'happiness', 'sadness', 'surprise', 'anger', 'fear', 'contempt', 'disgust', 'neutral'};
expression_probs = {-1, -1, -1, -1, -1, -1, -1, -1};
for idx = mega_img_idx*batch_size+1:(mega_img_idx+1)*batch_size
    if idx>total_frame_seconds
        break
    else
        face_result.face(idx) = 0;
        face_result.face_position(idx,:) = -1;
        face_result.expression{idx} = 'no_detection';
        face_result.expression_details{idx} = containers.Map(expression_keys, expression_probs);
        face_result.hand(idx) = -1;
        face_result.hand_area(idx) = [-1 -1];
        frame_in_mega = idx-mega_img_idx*batch_size;
        face_result.frame_index(idx) = [mega_img_idx floor(frame_in_mega/img_per_row) mod(frame_in_mega, img_per_row)];
    end
end


function face_result = update_with_face(face_result, mega_img_idx, mega_face_img, mega_face_info, img_width, img_height, total_frame_seconds)
batch_size = 20;
img_per_row = 5;
%initialization
expression_keys = {'happiness', 'sadness', 'surprise', 'anger', 'fear', 'contempt', 'disgust', 'neutral'};
expression_probs = {-1, -1, -1, -1, -1, -1, -1, -1};
for idx = (mega_img_idx-1)*batch_size+1:mega_img_idx*batch_size
    if idx>total_frame_seconds
        break
    else
        face_result.face(idx) = 0;
        face_result.face_position(idx,:) = -1;
        face_result.expression{idx} = 'no face';
        face_result.expression_details{idx} = containers.Map(expression_keys, expression_probs);
        face_result.hand(idx) = -1;
        face_result.hand_area(idx, :) = [-1 -1];
        frame_in_mega = idx-(mega_img_idx-1)*batch_size;
        face_result.frame_index(idx,:) = [mega_img_idx floor(frame_in_mega/img_per_row) mod(frame_in_mega, img_per_row)];
    end
end
%update for face info
expression_info = mega_face_info.expression;
[~, skin_map] = generate_skinmap(mega_face_img);
for idx = 1:length(expression_info)
    face_info_instance = expression_info{idx};
    face_position = [face_info_instance{1}.top face_info_instance{1}.left face_info_instance{1}.height face_info_instance{1}.width];
    expression = face_info_instance{2};
    expression_detail = face_info_instance{3};
    [y_index, x_index] = detect_face_idx(face_position, img_width, img_height);
    update_face_idx = (mega_img_idx-1)*batch_size + (y_index-1) * img_per_row + x_index;
    [nonface_skin_count, total_skin_count] = detect_hand(skin_map, face_position, [(y_index-1)*img_height+1, (x_index-1)*img_width+1 , y_index*img_height, x_index*img_width]);
    
    face_result.face(update_face_idx) = 1;
    face_result.face_position(update_face_idx,:) = face_position;
    face_result.expression{idx} = expression;
    for idy = 1:length(expression_keys)
        face_result.expression_details{idx}(expression_keys{idy}) = expression_detail.(expression_keys{idy});
    end
    if(nonface_skin_count>250)
        face_result.hand(update_face_idx) = 1;
    else
        face_result.hand(update_face_idx) = 0;
    end
    face_result.hand_area(update_face_idx,:) = [nonface_skin_count total_skin_count];
end


function [nonface_skin_count, total_skin_count] = detect_hand(skin_map, face_position, img_roi)
face_x1 = face_position(2);
face_x2 = face_position(4)+face_position(2)-1;
face_y1 = face_position(1);
face_y2 = face_position(1)+face_position(3)-1;
x_margin = fix(face_position(4)/2);
y_margin = fix(face_position(3)/2);
x_min = max(face_x1-x_margin, img_roi(2));
x_max = min(face_x2+x_margin, img_roi(4));
y_min = max(face_y1-y_margin, img_roi(1));
y_max = min(face_y2+y_margin, img_roi(3));
new_mat = [skin_map(y_min:y_max, x_min:face_x1) skin_map(y_min:y_max, face_x2:x_max)];
nonface_skin_count = length(find(new_mat==1));
total_skin_count = length(find(skin_map(y_min:y_max, x_min:x_max)==1));


function [y_index, x_index] = detect_face_idx(face_position, img_width, img_height)
y_index = ceil(face_position(1)/img_height);
x_index = ceil(face_position(2)/img_width);
%across the current index and 
if (face_position(2)+face_position(4)) > img_width * x_index && (face_position(2)+face_position(4)-img_width * x_index) > 1.2*(img_width * x_index-face_position(2))
    x_index = x_index + 1;
end

if (face_position(1)+face_position(3)) > img_height * y_index && (face_position(1)+face_position(3)-img_height * y_index) > 1.2*(img_height * y_index-face_position(1))
    y_index = y_index + 1;
end

function write_csv_file(filename, face_result)
fp = fopen(filename, 'wt');
fprintf(fp, 'room, session, performer, time_index, has_face, expression, has_hand\n');
for idx = 1:face_result.total_frames
    fprintf(fp, '%s, %s, %s, %d, %s, %d\n', face_result.room, ...
                                            face_result.session, ...
                                            face_result.performer, ...
                                            face_result.has_face(idx), ...
                                            face_result.expression{idx}, ...
                                            face_result.has_hand(idx));
    
end
fclose(fp);