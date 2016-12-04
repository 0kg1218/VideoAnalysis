'''
Created on 4 Dec 2016

@author: mozat
'''


import os
import cv2
import glob
import json
from video_extraction import video_extracter
import numpy as np
import math

base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
frame_rate = 12
batch_size = 20
video_per_row = 5
BIG_VIDEO_THRESHOLD = 200000
VIDEO_BASE_DIR = '/media/mozat/Seagate Backup Plus Drive/live broadcast/videos'
BIG_VIDEO_BASE_DIR = '/media/mozat/Seagate Backup Plus Drive/live broadcast/videos/big_videos'
video_processer = video_extracter()

def get_json():
    json_path = os.path.join(base_dir, 'json_files')
    json_files = glob.glob(os.path.join(json_path, '*.json'))
    json_nums = len(json_files)
    json_files = [os.path.join(json_path, '%05d.json'%(idx+1)) for idx in range(json_nums)]
    return json_files

def parse_json(json_file):
    fp = open(json_file)
    video_info = json.load(fp)
    fp.close()
    return video_info

def get_frame_info(video_info):
    if video_info['frame_num']> BIG_VIDEO_THRESHOLD:
        video_processer.video_init(os.path.join(BIG_VIDEO_BASE_DIR, video_info['video_name']))
    else:
        video_processer.video_init(os.path.join(VIDEO_BASE_DIR, video_info['video_name']))
    width, height = video_processer.video_get_info()
    video_processer.video_close()
    return (width, height)

def process_group(json_file):
    videos_info = parse_json(json_file)
    video_num = videos_info['video_num']
    group_id = videos_info['group_id']
    if not os.path.exists('./frames/%05d'%group_id):
        os.mkdir('./frames/%05d'%group_id)
    video_processer.video_log.info('start group: %05d with %d video(s)'%(group_id, video_num))
    
    img_width, img_height = get_frame_info(videos_info['video_01'])
    videos_info['img_width'] = img_width
    videos_info['img_height'] = img_height
    new_img = np.zeros((img_height*batch_size/video_per_row, img_width*video_per_row, 3), np.uint8)
    idx_in_new_img = 0
    img_write_idx = 1
    
    for v_idx in range(video_num):
        new_key = 'video_%02d'%(v_idx+1)
        video_info = videos_info[new_key]
        video_name = video_info['video_name']
        frame_num  = video_info['frame_num']
        start_idx, finish_idx = video_info['frame_idx']
        video_processer.video_log.info('start video: %s'%(video_name))
        if frame_num > BIG_VIDEO_THRESHOLD:
            video_processer.video_init(os.path.join(BIG_VIDEO_BASE_DIR, video_name))
        else:
            video_processer.video_init(os.path.join(VIDEO_BASE_DIR, video_name))
        for idx in range(start_idx, finish_idx+1, frame_rate):
            frame = video_processer.video_read_by_frame(idx-1)
            col_idx = idx_in_new_img%video_per_row
            row_idx = math.floor(idx_in_new_img/video_per_row)
            new_img[img_height*row_idx:img_height*(row_idx+1), img_width*col_idx:img_width*(col_idx+1), :] = frame
            idx_in_new_img = idx_in_new_img + 1
            if idx_in_new_img == 20:
                idx_in_new_img = 0
                filename = os.path.join('./frames/%05d/%05d.jpg'%(group_id, img_write_idx))
                video_processer.video_log.info('start video: %s, frame_idx: %d'%(video_name, img_write_idx))
                cv2.imwrite(filename, new_img)
                new_img[:] = 0
                img_write_idx = img_write_idx + 1
        video_processer.video_log.info('finish video: %s with frame_idx: %d'%(video_name, img_write_idx))
        video_processer.video_close()
    
    if idx_in_new_img!=0:
        filename = os.path.join('./frames/%05d/%05d.jpg'%(group_id, img_write_idx))
        video_processer.video_log.info('finish remain frame_idx: %d'%(img_write_idx))
        cv2.imwrite(filename, new_img)
    fp = open('./frames/%05d/group_info.json'%(group_id), 'wt')
    fp.write(json.dumps(videos_info))
    fp.close()
            

if __name__ == '__main__':
    json_files = get_json()
    for json_file in json_files:
        process_group(json_file)
    
    
    

