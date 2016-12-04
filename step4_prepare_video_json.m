function step4_prepare_video_json()
in_filename = './filtered_videonames_with_session/group_map.mat';
load(in_filename);

addpath(genpath('./jsonlab'));
keys = group_map.keys();
for idx = 1:length(keys)
    key = keys{idx};
    values = group_map(key);
    out_filename = sprintf('./json_files/%05d.json', key);
    video_names = values{1};
    frames_num = values{2};
    frame_index = values{3};
    room = values{4};
    session = values{5};
    performer = values{6};
    jsonstruct = {};
    jsonstruct.video_num = length(values{1});
    for idy = 1:length(frames_num)
        name = sprintf('video_%02d', idy);
        jsonstruct.(name).video_name = video_names{idy};
        jsonstruct.(name).frame_num = frames_num{idy};
        frame_idx = frame_index{idy};
        jsonstruct.(name).frame_idx = [frame_idx(1)  frame_idx(end)];
    end
    jsonstruct.room = room;
    jsonstruct.session = session;
    jsonstruct.performer = performer;
    savejson('', jsonstruct, out_filename);
end