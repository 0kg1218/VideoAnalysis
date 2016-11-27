function main(job_file, dir)
%clear;close all;
%get file structure
addpath(fullfile(fileparts(mfilename('fullpath')), 'generate_skinmap'))
out_filename = fullfile(fileparts(mfilename('fullpath')), 'analysis_videonames/name_map.mat');
if exist(out_filename, 'file')
    structs = load(out_filename);
    name_map = structs.name_map;
else
    name_map = analysis_video_namelist(out_filename);
end

jobset = {};
jobfid = fopen(job_file);
jobcount = 1;
while ~feof(jobfid)
    tline = fgetl(jobfid);
    jobset{jobcount} = tline;
    jobcount = jobcount + 1;
end
fclose(jobfid);

if exist('output.csv', 'file')
    delete('output.csv');
end
%if exist('table1.csv', 'file')
%    delete('table1.csv', 'file');
%end
if exist('table2.csv', 'file')
    delete('table2.csv');
end
if exist('frames', 'dir')
    rmdir('frames', 's');
end

ftableid = fopen('output.csv', 'wt+');
table2id = fopen('table2.csv', 'wt+');

fprintf(ftableid, 'Room,Session,Performer,Minute_Index,Anger,Contempt,Disgust,Fear,Happiness,Neutral,Sadness,Surprise,Hand\n');
fprintf(table2id, 'Group_ID;video_idx;frame_idx;face_info;hand_info\n');

fclose(ftableid);
fclose(table2id);

%process each video
key_sets = keys(name_map);
for idx = 1:length(key_sets)
    key = key_sets{idx};
    process_video(key, name_map(key), idx, jobset, dir);
end