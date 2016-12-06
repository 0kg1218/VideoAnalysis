'''
Created on 5 Dec 2016

@author: mozat
'''

from dlib_detector import dlib_detector
from Service import MSSEmotion
import json

class face_analyzer(object):
    def __init__(self):
        self.face_detector = dlib_detector()
        super(face_analyzer, self).__init__()
    
    def detect_face(self, img_path):
        dets = self.face_detector.detect_img_file(img_path)
        if dets:
            return dets
        else:
            return []
        
    def detect_emotion(self,img_path, EMOTION_KEY = 'd7b65479e11a4017a7bbcdbc24732c4a'):
        self.emotion_detector = MSSEmotion(EMOTION_KEY) 
        data = self.emotion_detector.detect_emotion_img(img_path)
        json_data = json.loads(data)
        result = []
        for face in json_data:
            try:
                tmplist = sorted(face['scores'].items(), key = lambda x: x[1], reverse = True)
                result.append((face['faceRectangle'], tmplist[0][0], face['scores']))
            except:
                #{u'error': {u'message': u'Rate limit is exceeded. Try again later.', u'code': u'RateLimitExceeded'}}
                print 'error in emotion detection', face['scores']
        return result
    

    