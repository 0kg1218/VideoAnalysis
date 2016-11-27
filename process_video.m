function process_video(recorder_name, video_names, group_id, jobset, dir)
t1 = clock;
%fprintf(['processing:', recorder_name, ' videos:\n']);

cur_dir = fileparts(mfilename('fullpath'));
value = video_names;
ids = strsplit(recorder_name, '_');

room_str = ids{1};
session_str = ids{2};
performer_str = ids{3};

%data storage dirs
frameDir = 'frames';
if ~exist(frameDir, 'dir')
    mkdir(frameDir);
end
frameListFile = 'frame_list.dat';
faceFile = 'face.dat';

img_cnt = 1;
mega_cnt = 1;

imgs = {};
img_temp_cnt = 1;
img_frame_index = {};
img_video_index = {};

mega_imgs = {};
mega_frame_index = {};
mega_sec_index = {};

fid = fopen(frameListFile, 'wt+');

for idy = 1:length(value)
    filename = value{idy};
    filepath = fullfile(dir, filename);
    if exist(filepath, 'file') && ismember(filename, jobset)
    %if exist(fullfile(cur_dir, sprintf('video_sample/%s', filename)), 'file')
        fprintf('%s\n', filename);
        %filename = fullfile(cur_dir, sprintf('video_sample/%s', filename));
        filename = filepath;
        xyloObj = VideoReader(filename);
        vidWidth = xyloObj.Width;
        vidHeight = xyloObj.Height;
        frameRate = round(xyloObj.FrameRate);
        nFrames = xyloObj.NumberOfFrames;
        
        frame_start = floor(frameRate/2);
        for k = frame_start:frameRate:nFrames
            imgs{img_temp_cnt} = read(xyloObj, k);
            img_frame_index{img_cnt} = k;
            img_video_index{img_cnt} = idy;
            
            %add: 20 frames
            if mod(img_cnt,20) == 0
%                 mega_img = [imgs{img_cnt-19} imgs{img_cnt-18} imgs{img_cnt-17} imgs{img_cnt-16} imgs{img_cnt-15};
%                     imgs{img_cnt-14} imgs{img_cnt-13} imgs{img_cnt-12} imgs{img_cnt-11} imgs{img_cnt-10};
%                     imgs{img_cnt-9} imgs{img_cnt-8} imgs{img_cnt-7} imgs{img_cnt-6} imgs{img_cnt-5};
%                     imgs{img_cnt-4} imgs{img_cnt-3} imgs{img_cnt-2} imgs{img_cnt-1} imgs{img_cnt}];
                mega_img = [imgs{1} imgs{2} imgs{3} imgs{4} imgs{5};
                    imgs{6} imgs{7} imgs{8} imgs{9} imgs{10};
                    imgs{11} imgs{12} imgs{13} imgs{14} imgs{15};
                    imgs{16} imgs{17} imgs{18} imgs{19} imgs{20}];
                mega_imgs{mega_cnt} = mega_img;
                save_file_name = strcat(frameDir, '/');
                save_file_name = strcat(save_file_name, num2str(img_cnt-19), '-', num2str(img_cnt));
                save_file_name = strcat(save_file_name, '.jpg');
                
                imwrite(mega_img, save_file_name, 'jpg');
                fprintf(fid, '%s.jpg\n', [num2str(img_cnt-19),'-',num2str(img_cnt)]);
                fprintf('saving %s.jpg\n', [num2str(img_cnt-19),'-',num2str(img_cnt)]);
                mega_index{mega_cnt} = k;
                mega_sec_index{mega_cnt} = img_cnt;
                mega_cnt = mega_cnt + 1;
                
                img_temp_cnt = 0;
                imgs = {};
            end
            img_cnt = img_cnt + 1;
            img_temp_cnt = img_temp_cnt + 1;
        end  
    else
        continue;
    end
end
fclose(fid);

if img_cnt == 1
    return;
end

img_width = size(imgs{1}, 2);
img_height = size(imgs{1}, 1);
%face_detect

t2 = clock;
%etime(t2, t1)

system('python API-Microsoft/API/FaceDetect2.py');

t3 = clock;

%skin_detect
fid = fopen(faceFile);
count = 0; 
x = 0;
y = 0;
h = 0;
w = 0;

face_frames = {};

jsonFile = 'json.dat';
jsonstr = {};
jsonid = fopen(jsonFile);

line_num = str2num(fgetl(fid));
for line = 1:line_num
    count = str2num(fgetl(fid));
    face_frame = {};
    json_str = {};
    for i = 1:count
        line_str = fgetl(fid);
        a = sscanf(line_str, '%d %d %d %d %d');
        face_frame{i} = a;
        json_str{i} = fgetl(jsonid);
    end
    face_frames{line} = face_frame;
    jsonstr{line} = json_str;
end

fclose(fid);
fclose(jsonid);

ftableid = fopen('output.csv', 'at+');
table2id = fopen('table2.csv', 'at+');

hand_count = 0;
emotion_count = {0,0,0,0,0,0,0,0};

for k = 1:length(mega_imgs)  
    mega_img = mega_imgs{k};
    faces = face_frames{k};
    json = jsonstr{k};
    fprintf(strcat('testing video: ', filename, ', second: ', num2str(mega_sec_index{k}-19), '-', num2str(mega_sec_index{k}), '\n'));
    if length(faces) == 0 
        if mod(k,3) == 0
            fprintf(ftableid, '%s,%s,%s,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d\n', room_str, session_str, performer_str, floor(k/3), emotion_count{1}, emotion_count{2}, emotion_count{3}, emotion_count{4}, emotion_count{5}, emotion_count{6}, emotion_count{7}, emotion_count{8}, hand_count);
            hand_count = 0;
            emotion_count = {0,0,0,0,0,0,0,0};
        end
        continue
    end
    [out bin] = generate_skinmap(mega_img, '');
    
    for l = 1:length(faces)
        face = faces{l}; 
        json_str = json{l};
        
        x_index = fix((face(1)-1)/img_width);
        y_index = fix((face(2)-1)/img_height);

        if (face(1)+face(3)-1) > img_width * (x_index + 1) && img_width * (x_index + 1) - face(1) + 1 < fix(img_width/2)
            x_index = x_index + 1;
        end
        
        if (face(2)+face(4)-1) > img_height * (y_index + 1) && img_height * (y_index + 1) - face(2) + 1 < fix(img_height/2)
            y_index = y_index + 1;
        end
        
        img_x = x_index*img_width+1;
        img_y = y_index*img_height+1;
        
        result = detect_hand(bin, face, img_x, img_y, img_width, img_height);%detect_hand
        if result(1) == 1           
            hand_count = hand_count + 1;
        end
        
        last_img_index = mega_sec_index{k};
        img_index = last_img_index - (19 - (y_index * 5 + x_index));
        video_idx = img_video_index{img_index};
        frame_idx = img_frame_index{img_index};
        
        emotion_index = face(5) + 1;
        emotion_count{emotion_index} = emotion_count{emotion_index} + 1;
        
        hand_info = sprintf('{''had_hand'':%d,"skin_number_around_face":%d,"skin_number_inside_face":%d,"face_bounding_box":{"x":%d,"y":%d,"w":%d,"h":%d}}',result(1),result(6),result(7),result(2),result(3),result(4),result(5));
        fprintf(table2id, '%d;%d;%d;%s;%s\n', group_id, video_idx, frame_idx, json_str, hand_info);
    end

    if mod(k,3) == 0
        fprintf(ftableid, '%s,%s,%s,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d\n', room_str, session_str, performer_str, floor(k/3), emotion_count{1}, emotion_count{2}, emotion_count{3}, emotion_count{4}, emotion_count{5}, emotion_count{6}, emotion_count{7}, emotion_count{8}, hand_count);
        hand_count = 0;
        emotion_count = {0,0,0,0,0,0,0,0};
    end
end

fclose(ftableid);
fclose(table2id);
rmdir(frameDir, 's');

t4 = clock;
fprintf(['total_time:', num2str(etime(t4,t1)), ',loading&reading:', num2str(etime(t2,t1)), ',face_detect:', num2str(etime(t3,t2)), ',skin_detect:', num2str(etime(t4,t3)), '\n']);

function result = detect_hand(bin, face, img_x, img_y, img_w, img_h)
    result = [0,-1,-1,-1,-1, 0];
    face_x1 = face(1);
    face_x2 = face(1) + face(3) - 1;
    face_y1 = face(2);
    face_y2 = face(2) + face(4) - 1;
    x_margin = fix(face(3)/2);
    y_margin = fix(face(4)/4);
    x_min = max([face_x1 - x_margin, img_x]);
    x_max = min([face_x2 + x_margin, img_x + img_w-1]);
    %y_min = max([face_y1 - y_margin, img_y]);
    %y_max = min([face_y2 - y_margin, img_y + img_h-1]);
    y_min = max([face_y1 - y_margin, img_y]);
    y_max = min([face_y2 + y_margin, img_y + img_h-1]);
    count = 0;
    face_count = 0;
    for i = x_min:x_max
        for j = y_min:y_max
            if (i < face_x1 || i > face_x2)
                if  bin(j, i) == 1
                    count = count + 1;   
                end
            end
            if (i >= face_x1 && i <= face_x2 && j >= face_y1 && j <= face_y2)
                if bin(j, i) == 1
                    face_count = face_count + 1;
                end
            end
        end
    end
    if count > 1000
        %result = [1,x_min,y_min, x_max-x_min+1, y_max-y_min+1, count, face_count];
        result = [1,face(1),face(2),face(3),face(4),count,face_count];
        return;
    end
    result = [0,face(1),face(2),face(3),face(4),count,face_count];
    %result = [0,x_min,y_min,x_max-x_min+1,y_max-y_min+1, count, face_count];
    