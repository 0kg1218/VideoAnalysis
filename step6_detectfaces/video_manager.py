import os, glob
from face_analyzer import face_analyzer
from video_logger import video_logger
import time
import multiprocessing
from config import BASE_DIR, EMOTION_ACCOUNT, ACCOUNT_INFO, ACCOUNT_INFO_FILE, join_path, load_json, write_json


class video_analyzer(multiprocessing.Process):
    enable_cached = False
    frame_path = join_path(BASE_DIR, 'step5_extract_frame/frames')
    def __init__(self, account_id, group_idx):
        self.video_analyzer = face_analyzer()
        self.video_logger = video_logger().get_log()
        self.account_id = account_id
        self.group_idx = group_idx
        super(video_analyzer, self).__init__()

    def run(self):
        process_semaphore.acquire()
        group_idx = self.group_idx
        if not os.path.exists(join_path(self.frame_path, '%05d/face_info.json'%group_idx)) or not self.enable_cached:
            files = glob.glob(join_path(self.frame_path, '%05d/*.jpg'%group_idx))
            json_info = load_json(join_path(self.frame_path, '%05d/group_info.json'%group_idx))
            files = [join_path(self.frame_path, '%05d/%05d.jpg'%(group_idx, idy+1)) for idy in range(0, len(files))]
            self.analyze_face(group_idx, json_info, files)
        process_semaphore.release()

    def analyze_face(self, group_idx, json_info, files):
        self.video_logger.info('start procesing group %d'%group_idx)
        video_num = json_info['video_num']
        for idx in range(video_num):
            json_info.pop('video_%02d'%(idx+1))
        json_info['face_info'] = {}
        json_info['total_frames'] = len(files) 
        start_time = time.time()
        api_call_time = 0
        for frame_idx, filename in enumerate(files):
            json_info['face_info']['%05d'%(frame_idx+1)] = {}
            face_detected = self.video_analyzer.detect_face(filename)
            if face_detected:
                try:
                    expression_info = self.video_analyzer.detect_emotion(filename, EMOTION_KEY = self.account_id)
                    api_call_time = api_call_time + 1
                    time.sleep(3)
                except Exception:
                    expression_info = 'error_detection'
                json_info['face_info']['%05d'%(frame_idx+1)]['has_face'] = 1
                json_info['face_info']['%05d'%(frame_idx+1)]['expression'] = expression_info
            else:
                json_info['face_info']['%05d'%(frame_idx+1)]['has_face'] = 0 #
            if (frame_idx)%20+1 == 20:
                self.video_logger.info('group %d with % frame spends %03f'%(group_idx, frame_idx+1, time.time()-start_time))
        write_json(json_info, join_path(self.frame_path, '%05d/face_info.json'%group_idx))      
        self.video_logger.info('finish procesing group %d'%group_idx)
        
        account_info_sempahore.acquire()
        ACCOUNT_INFO[self.account_id] += api_call_time
        write_json(ACCOUNT_INFO, ACCOUNT_INFO_FILE)
        account_info_sempahore.release()

if __name__ == '__main__':
    account_num = len(EMOTION_ACCOUNT)
    process_semaphore = multiprocessing.Semaphore(account_num)
    account_info_sempahore = multiprocessing.Semaphore(1)
    workers = []
    for process_idx in range(1, 5):
        p = video_analyzer(account_id = EMOTION_ACCOUNT[process_idx%account_num], group_idx = process_idx)
        workers.append(p)
        p.start()
    for p in workers:
        p.join()
    print "all frames tested"
