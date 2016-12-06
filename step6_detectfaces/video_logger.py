'''
Created on 5 Dec 2016

@author: mozat
'''
import logging
class video_logger(object):
    _instance = None
    def __init__(self, filename = 'frame_analysis.log'):
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