value = video_names;
ids = strsplit(recorder_name, '_');

room_str = ids{1};
session_str = ids{2};
performer_str = ids{3};

%data storage
frameFile = 'frame.jpg';
faceFile = 'face.dat';

img_cnt = 1;
mega_cnt = 1;

imgs = cell(20);
img_temp_cnt = 1;

img_frame_index = {};
img_video_index = {};

mega_sec_index = {};

ftableid = fopen('output.csv', 'at+');
table2id = fopen('table2.csv', 'at+');

hand_count = 0;
emotion_count = {0,0,0,0,0,0,0,0};

k = 0;
for idy = 1:length(value)
    filename = value{idy};
    filepath = fullfile(dir, filename);
    if exist(filepath, 'file') && ismember(filename, jobset)
        fprintf('%s\n', filename);
        xyloObj = VideoReader(filepath);
        img_width = xyloObj.Width;
        img_height = xyloObj.Height;
        frameRate = round(xyloObj.FrameRate);
        %nFrames = xyloObj.NumberOfFrames;
        
        frame_start = floor(frameRate/2);
        while hasFrame(xyloObj)
        %for k = frame_start:frameRate:nFrames
            %imgs{img_temp_cnt} = read(xyloObj, k);
            k = k + 1;
            fr = readFrame(xyloObj);
            if k < frame_start || mod(k - frame_start, frameRate) ~= 0
                continue;
            end
            imgs{img_temp_cnt} = fr;
            img_frame_index{img_cnt} = k;
            img_video_index{img_cnt} = idy;
            
            %add: 20 frames
            if mod(img_cnt,20) == 0
                mega_img = [imgs{1} imgs{2} imgs{3} imgs{4} imgs{5};
                    imgs{6} imgs{7} imgs{8} imgs{9} imgs{10};
                    imgs{11} imgs{12} imgs{13} imgs{14} imgs{15};
                    imgs{16} imgs{17} imgs{18} imgs{19} imgs{20}];
                
                imwrite(mega_img, frameFile, 'jpg');
                fprintf('saving %s.jpg\n', [num2str(img_cnt-19),'-',num2str(img_cnt)]);
            
                mega_sec_index{mega_cnt} = img_cnt;
                
                img_temp_cnt = 0;
                imgs = {};
                
                system('python API-Microsoft/API/FaceDetect2.py');
                
                fid = fopen(faceFile);
                
                count = str2double(fgetl(fid));
                faces = cell(count);
                json = cell(count);
                for i = 1:count
                    line_str = fgetl(fid);
                    a = sscanf(line_str, '%d %d %d %d %d');
                    faces{i} = a;
                    json{i} = fgetl(fid);
                end
                
                fclose(fid);
                
                fprintf(strcat('testing video: ', filename, ', second: ', num2str(img_cnt-19), '-', num2str(img_cnt), '\n'));
                
                if ~isempty(faces)
                    [~, bin] = generate_skinmap(mega_img, '');
                end
                
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
                    
                    last_img_index = mega_sec_index{mega_cnt};
                    img_index = last_img_index - (19 - (y_index * 5 + x_index));
                    video_idx = img_video_index{img_index};
                    frame_idx = img_frame_index{img_index};
                    
                    emotion_index = face(5) + 1;
                    emotion_count{emotion_index} = emotion_count{emotion_index} + 1;
                    
                    hand_info = sprintf('{''had_hand'':%d,"skin_number_around_face":%d,"skin_number_inside_face":%d,"face_bounding_box":{"x":%d,"y":%d,"w":%d,"h":%d}}',result(1),result(6),result(7),result(2),result(3),result(4),result(5));
                    fprintf(table2id, '%d;%d;%d;%s;%s\n', group_id, video_idx, frame_idx, json_str, hand_info);
                end
                
                if mod(mega_cnt,3) == 0
                    fprintf(ftableid, '%s,%s,%s,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d\n', room_str, session_str, performer_str, floor(mega_cnt/3), emotion_count{1}, emotion_count{2}, emotion_count{3}, emotion_count{4}, emotion_count{5}, emotion_count{6}, emotion_count{7}, emotion_count{8}, hand_count);
                    hand_count = 0;
                    emotion_count = {0,0,0,0,0,0,0,0};
                end
                mega_cnt = mega_cnt + 1;
            end
            img_cnt = img_cnt + 1;
            img_temp_cnt = img_temp_cnt + 1;
        end
    else
        continue;
    end
end
fclose(ftableid);
fclose(table2id);

if img_cnt == 1
    return;
end

t2 = clock;
fprintf(['total_time:', num2str(etime(t2,t1)), '\n']);

function result = detect_hand(bin, face, img_x, img_y, img_w, img_h)
face_x1 = face(1);
face_x2 = face(1) + face(3) - 1;
face_y1 = face(2);
face_y2 = face(2) + face(4) - 1;
x_margin = fix(face(3)/2);
y_margin = fix(face(4)/4);
x_min = max([face_x1 - x_margin, img_x]);
x_max = min([face_x2 + x_margin, img_x + img_w-1]);
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
    result = [1,face(1),face(2),face(3),face(4),count,face_count];
    return;
end
result = [0,face(1),face(2),face(3),face(4),count,face_count];