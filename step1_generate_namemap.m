%generate name_map
%name_map.mat
clear;close all;clc;
addpath('./analysis_videonames');
out_filename = './analysis_videonames/name_map.mat';
analysis_video_namelist(out_filename);