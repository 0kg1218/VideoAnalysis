'''
Created on 4 Dec 2016

@author: mozat
'''

import cv2
import logging
import time

def singleton(cls):
    instances = {}
    def getinstance():
        if cls not in instances:
            instances[cls] = cls
        return instances[cls]
    return getinstance


class video_logger(object):
    _instance = None
    def __init__(self, filename = 'video_analysis.log'):
        self.logger_name = self.__class__.__name__
        self.logger = logging.getLogger(self.logger_name)
        self.logger.setLevel(logging.DEBUG)
        self.logger.propagate = False
        self.fh = logging.FileHandler(filename)
        self.fh.setLevel(logging.DEBUG)
        fmt = "%(asctime)-15s %(levelname)s %(filename)s %(message)s"
        datafmt = "%a %d %b %Y %H:%M:%S"
        formmater = logging.Formatter(fmt, datafmt)
        self.fh.setFormatter(formmater)
        self.logger.addHandler(self.fh)
    
    def get_log(self):
        return self.logger

class video_extracter(object):
    _instance = None
    def __init__(self):
        video_log = video_logger()
        self.video_log = video_log.get_log()
        super(video_extracter, self).__init__()
        
    def video_init(self, video_name):
        self.video_name = video_name
        self.capture = cv2.VideoCapture(video_name)
        if not self.capture.isOpened():
            self.video_log.error('error in %s'%(video_name))
            exit()
        self.frame_width = self.capture.get(3)
        self.frame_height = self.capture.get(4)
    
    def video_get_info(self):
        return (int(self.frame_width), int(self.frame_height))
    
    def video_read_by_frame(self, frame_idx):
        biases = [0, -1, -2, -3. -4, 1 , 2, 3, 4]
        for bias in biases:
            self.capture.set(1, frame_idx-bias)
            ret, frame = self.capture.read()
            if ret:
                return frame
            else:
                time.sleep(0.05)
        self.video_log.error('error in %s at frame %d'%(self.video_name, frame_idx))
        self.capture.set(1, 0)
        ret, frame = self.capture.read()
        return frame
    def video_close(self):
        self.capture.release()