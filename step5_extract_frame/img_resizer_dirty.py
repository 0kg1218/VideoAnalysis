'''
Created on 6 Dec 2016

@author: mozat
'''
import glob, cv2, os

import multiprocessing
import logging
import json
import numpy as np
import math
from video_extraction import video_extracter

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
frame_rate = 12
batch_size = 20
video_per_row = 5
BIG_VIDEO_THRESHOLD = 200000
VIDEO_BASE_DIR = '/media/mozat/Seagate Backup Plus Drive/live broadcast/videos'
BIG_VIDEO_BASE_DIR = '/media/mozat/Seagate Backup Plus Drive/live broadcast/videos/big_videos'
video_processer = video_extracter()

def join_path(*dirs):
    dir_path = dirs[0]
    for idx in range(1, len(dirs)):
        dir_path = os.path.join(dir_path, dirs[idx])
    return dir_path

def load_json(filename):
    with open(filename) as fb:
        json_info = json.loads(fb.read())
    return json_info

def write_json(json_info, filename):
    with open(filename, 'wt') as fb:
        fb.write(json.dumps(json_info))
        
def get_json():
    json_path = os.path.join(BASE_DIR, 'json_files')
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

def process_group(json_file, target_img_index):
    videos_info = parse_json(json_file)
    video_num = videos_info['video_num']
    group_id = videos_info['group_id']
    if not os.path.exists('./frames/%05d'%group_id):
        os.mkdir('./frames/%05d'%group_id)
    
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
            if img_write_idx<target_img_index:
                idx_in_new_img = idx_in_new_img + 1
                if idx_in_new_img == 20:
                    idx_in_new_img = 0
                    img_write_idx = img_write_idx + 1
            else:
                frame = video_processer.video_read_by_frame(idx-1)
                col_idx = idx_in_new_img%video_per_row
                row_idx = math.floor(idx_in_new_img/video_per_row)
                new_img[img_height*row_idx:img_height*(row_idx+1), img_width*col_idx:img_width*(col_idx+1), :] = frame
                idx_in_new_img = idx_in_new_img + 1
                if idx_in_new_img == 20:
                    idx_in_new_img = 0
                    filename = os.path.join(BASE_DIR, 'step5_extract_frame/frames/%05d/%05d.jpg'%(group_id, img_write_idx))
                    video_processer.video_log.info('start video: %s, frame_idx: %d'%(video_name, img_write_idx))
                    out_img = cv2.resize(new_img, (0,0), fx = 0.5, fy = 0.5)
                    cv2.imwrite(filename, out_img)
                    new_img[:] = 0
                    img_write_idx = img_write_idx + 1
                    video_processer.video_close()
                    return
    
    if idx_in_new_img!=0:
        filename = os.path.join(BASE_DIR, 'step5_extract_frame/frames/%05d/%05d.jpg'%(group_id, img_write_idx))
        out_img = cv2.resize(new_img, (0,0), fx = 0.5, fy = 0.5)
        cv2.imwrite(filename, out_img)
        return

def worker(dpath):
    Log.info('%s: %s'%(multiprocessing.current_process().name, os.path.basename(dpath)))
    json_info = load_json(join_path(dpath, 'group_info.json'))
    
    if os.path.exists(join_path(dpath, 'face_info.json')):
        os.remove(join_path(dpath, 'face_info.json'))
    
    img_names = glob.glob(join_path(dpath, '*.jpg'))
    resized_num = 0
    for img_name in img_names:
        if img_name.find('tmp')!=-1:
            os.remove(img_name)
            Log.info('copy file in %s'%img_name)
            continue
        img = cv2.imread(img_name)
        try:
            height, width = img.shape[0], img.shape[1]
        except:
            json_file_idx = int(os.path.basename(dpath))-1
            target_frame_idx = int(os.path.basename(img_name)[0:5])
            run_write_frame(json_file_idx, target_frame_idx)
            Log.info('error in %s'%img_name)
            Log.info('reread in %d, %d'%(json_file_idx+1, target_frame_idx))
            continue
        if height == 4*json_info['img_height'] and width == 5*json_info['img_width']:
            img = cv2.resize(img, (0, 0), fx = 0.5, fy = 0.5)
            cv2.imwrite(img_name,img)
            resized_num = resized_num + 1
    Log.info('%s, %s, resized %d'%(multiprocessing.current_process().name, os.path.basename(dpath) , resized_num))


def run_resizer():
    group_idx = range(1154, 2101)
    groups = [join_path(BASE_DIR, 'step5_extract_frame/frames', '%05d'%idx) for idx in group_idx]
    pool = multiprocessing.Pool(processes=8)
    for group in groups:
        pool.apply_async(worker, (group, ))
    pool.close()
    pool.join()
    Log.info('resize done here')

def run_write_frame(json_file_idx, target_frame_idx):        
    json_files = get_json()
    process_group(json_files[json_file_idx], target_frame_idx)
if __name__ == '__main__':
    fmt = "%(asctime)-15s %(levelname)s %(message)s"
    datafmt = "%a %d %b %Y %H:%M:%S"
    logging.basicConfig(filename='img_resizer.log', level=logging.INFO, \
                        format="%(asctime)-15s %(levelname)s %(message)s",\
                        datefmt = datafmt)
    Log = logging.getLogger('myLogger')
    Log.setLevel(logging.DEBUG)
    run_resizer()
    pass
    
