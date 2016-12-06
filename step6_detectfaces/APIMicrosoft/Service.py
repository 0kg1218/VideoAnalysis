'''
Created on 1 Nov 2016

@author: mozat
'''
import httplib,urllib, json

class MicrosoftService(object):    
    def __init__(self, service_url, account_key):
        self._service_url = service_url
        self._account_key = account_key
    def service_execute(self, post_url, headers, query_params, body):
        obj = ''
        params = urllib.urlencode(query_params)
        try:
            conn = httplib.HTTPSConnection(self._service_url)
            conn.request('POST', post_url % params, body, headers)
            response = conn.getresponse()
            obj = response.read()
            conn.close()
        except Exception as e:
            print e
        return obj

class MSSEmotion(MicrosoftService):
    _SERVICE_URL = 'api.projectoxford.ai'

    def __init__(self, EMOTION_KEY = 'd7b65479e11a4017a7bbcdbc24732c4a'):
        super(MSSEmotion, self).__init__(service_url = MSSEmotion._SERVICE_URL, account_key = EMOTION_KEY)
        self.EMOTION_KEY = EMOTION_KEY
        self.headers = {'Ocp-Apim-Subscription-Key': self.EMOTION_KEY} 
        pass
    
    def detect_emotion_url(self, url):
        _POST_URL = "/emotion/v1.0/recognize?%s"
        query_params = {}
        body = json.dumps({'URl': url})
        self.headers['Content-Type'] = 'application/json'
        obj = self.service_execute(_POST_URL, self.headers, query_params, body)
        return obj
    
    def detect_emotion_img(self, img_file):
        _POST_URL = "/emotion/v1.0/recognize?%s"
        query_params = {}
        f = open(img_file, "rb")
        body = f.read()
        f.close()
        self.headers['Content-Type'] = 'application/octet-stream'
        obj = self.service_execute(_POST_URL, self.headers, query_params, body)
        return obj
    
class MSSFace(MicrosoftService):
    _SERVICE_URL = 'api.projectoxford.ai'
    
    def __init__(self, FACE_KEY = '00ba0d2cd01b4bf69678806d5dbf89fd'):
        super(MSSFace, self).__init__(service_url = MSSFace._SERVICE_URL, account_key = FACE_KEY)
        self.FACE_KEY = FACE_KEY
        self.headers =   {'Ocp-Apim-Subscription-Key': self.FACE_KEY}
        pass
    
    def detect_face_url(self, url):
        _POST_URL = "/face/v1.0/detect?%s"
        query_params = {'returnFaceId': True, 'returnFaceLandmarks':True, 'returnFaceAttributes':  'age,gender,headPose,smile,facialHair,glasses'}
        body = json.dumps({'URl': url})
        self.headers['Content-Type'] = 'application/json'
        obj = self.service_execute(_POST_URL, self.headers, query_params, body)
        return obj
    
    def detect_face_img(self, img_file):
        _POST_URL = "/face/v1.0/detect?%s"
        query_params = {'returnFaceId': True, 'returnFaceLandmarks':True, 'returnFaceAttributes':  'age,gender,headPose,smile,facialHair,glasses'}
        f = open(img_file, "rb")
        body = f.read()
        f.close()
        self.headers['Content-Type'] = 'application/octet-stream'
        obj = self.service_execute(_POST_URL, self.headers, query_params, body)
        return obj
        pass