function step7_generate_csv()
addpath('./step5_extract_frame');
addpath('./jsonlab');
inDir = './step5_extract_frame/frames';
dirs  = dir(inDir);
dirs = dirs(3:end);
outDir = './face_info';

for idx = 4:length(dirs)
    total_frame_seconds = get_frames(fullfile(inDir, dirs(idx).name));
    
    img_width = face_info_struct.img_width/2;
    img_heihgt = face_info_struct.img_height/2;
    total_frame = face_info_struct.total_frames;
    result = {};
    for idy = 1:total_frame
        frame_idx = sprintf('x0x30_%04d',idy);
        has_face = face_info.(frame_idx).has_face;
        if has_face==0
            expression_info = face_info.(frame_idx).expression;
            if isempty(expression_info)
                result.has_face(idy) = 0;
            else
                result.has_face(idy) = 1;
                mega_img = imread(fullfile(fullfile(inDir, dirs(idx).name), sprintf('%05d.jpg', idy)));
                [~, bin] = generate_skinmap(mega_img, '');
            end
        else
            result.has_face(idy) = 0;
        end
        
    end
end


function total_frame_seconds = get_frames_cnt(dpath)
group_info = loadjson(fullfile(fullfile(inDir, dirs(idx).name), 'group_info.json'));
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





function analysze_face(expression_info, img_width, img_height)


for idx = 1:length(expression_info)
    faces = expression_info{idx};
    face_position = faces{1};
    expression = faces{2};
end

