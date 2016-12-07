function step7_generate_csv()
addpath('./step5_extract_frame');
addpath('./jsonlab');
inDir = './step5_extract_frame/frames';
dirs  = dir(inDir);
dirs = dirs(3:end);
outDir = './face_info';

for idx = 4:length(dirs)
    total_frame_seconds = get_frames_cnt(fullfile(inDir, dirs(idx).name));
    face_info = get_face_info(fullfile(inDir, dirs(idx).name));
    face_result = get_face_result(face_info, total_frame_seconds);
    save(fullfile(outDir, sprintf('%05d.mat', idx)), 'face_result');
    write_csv_file(fullfile(outDir, sprintf('%05d.csv', idx)), face_result);
end


function total_frame_seconds = get_frames_cnt(dpath)
group_info = loadjson(fullfile(dpath, 'group_info.json'));
video_num = group_info.video_num;
total_frame_seconds = 0;
for idx = 1:video_num
    video_name = sprintf('video_%02d', idx);
    frame_idx = group_info.(video_name).frame_idx;
    total_frame_seconds = total_frame+(frame_idx(2)-frame_idx(1))/12+1;
end

function face_info = get_face_info(dpath)
face_info_struct = loadjson(fullfile(dpath, 'face_info.json'));
face_info = face_info_struct.face_info;
face_info.img_width = face_info_struct.img_width/2;
face_info.img_heihgt = face_info_struct.img_height/2;
face_info.total_mega_imgs = face_info_struct.total_frames;


function face_result = get_face_result(face_info, total_frame_seconds)
face_result = {};
face_result.face = zeros(total_frame_seconds, 1);
face_result.face_position = zeros(total_frame_seconds, 4);
face_result.expression = cell(total_frame_seconds, 1);
face_result.expression_details = cell(total_frame_seconds, 1);
face_result.hand = zeros(total_frame_seconds, 1);
face_result.hand_area = zeros(total_frame_seconds, 1);
face_result.frame_index = zeros(total_frame_seconds, 3); %mega_img_idx, y_index, x_index
face_result.total_frames = total_frame_seconds;

for mega_img_idx = 1:face_info.total_mega_imgs
    frame_idx = sprintf('x0x30_%04d',mega_img_idx);
    mega_face_info = face_info.(frame_idx);
    if mega_face_info.has_face == 0 || isempty(mega_face_info.expression)
        face_result = update_no_face(face_result, mega_img_idx, total_frame_seconds);
    else
        face_result = update_with_face(face_result, mega_img_idx, total_frame_seconds, mega_face_info);
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
        face_result.hand_area(idx) = -1;
        frame_in_mega = idx-mega_img_idx*batch_size;
        face_result.frame_index(idx) = [mega_img_idx floor(frame_in_mega/img_per_row) mod(frame_in_mega, img_per_row)];
    end
end


function face_result = update_with_face(face_result, mega_img_idx, total_frame_seconds, mega_face_info)
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
        face_result.hand_area(idx) = -1;
        frame_in_mega = idx-mega_img_idx*batch_size;
        face_result.frame_index(idx) = [mega_img_idx floor(frame_in_mega/img_per_row) mod(frame_in_mega, img_per_row)];
    end
end


function detect_hand()
disp(1);

function detect_face_idx()
idx = 1;



