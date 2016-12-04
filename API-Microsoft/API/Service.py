'''
Created on 1 Nov 2016

@author: mozat
'''
import httplib,urllib, json

class MicrosoftService(object): 
    _FACE_KEY = '00ba0d2cd01b4bf69678806d5dbf89fd'
    
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


class MSS_NLPText(MicrosoftService):
    _SERVICE_URL = 'westus.api.cognitive.microsoft.com'
    _NLPTEXT_KEY = 'e8bbd72eb5f84bb5997804a9c7256499'
    
    def __init__(self):
        super(MSS_NLPText, self).__init__(service_url = MSS_NLPText._SERVICE_URL, account_key = MSS_NLPText._NLPTEXT_KEY)
        self.headers = {'Content-Type':'application/json', 'Ocp-Apim-Subscription-Key':MSS_NLPText._NLPTEXT_KEY}
        pass
    
    def detect_keyphrase(self, input_texts):
        '''Detect key phrases.'''
        _POST_URL = '/text/analytics/v2.0/keyPhrases?%s'
        query_params = {}
        body = input_texts 
        obj = self.service_execute(_POST_URL, self.headers, query_params, body)
        return obj
    
    def detect_language(self, input_texts, num_detect_langs):
        '''Detect language.'''
        _POST_URL = "/text/analytics/v2.0/languages?%s"
        query_params = {'numberOfLanguagesToDetect': num_detect_langs}
        body = input_texts
        obj = self.service_execute(_POST_URL, self.headers, query_params, body)
        return obj
    
    def detect_sentiment(self, input_texts):
        '''Detect sentiment from 0-1, negative and positive.'''
        _POST_URL = "/text/analytics/v2.0/sentiment?%s"
        query_params = {}
        body = input_texts
        obj = self.service_execute(_POST_URL, self.headers, query_params, body)
        return obj

class MSS_Emotion(MicrosoftService):
    _SERVICE_URL = 'api.projectoxford.ai'
    _EMOTION_KEY = 'd7b65479e11a4017a7bbcdbc24732c4a'
    
    def __init__(self):
        super(MSS_Emotion, self).__init__(service_url = MSS_Emotion._SERVICE_URL, account_key = MSS_Emotion._EMOTION_KEY)
        self.headers = {'Ocp-Apim-Subscription-Key': MSS_Emotion._EMOTION_KEY} 
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

class MSS_IMGSearch(MicrosoftService):
    _SERVICE_URL = 'api.cognitive.microsoft.com'
    _IMGSEARCH_KEY = '78012ea33fda4ea29d7387ab47c7963b'
    
    def __init__(self):
        super(MSS_IMGSearch, self).__init__(service_url = MSS_IMGSearch._SERVICE_URL, account_key = MSS_IMGSearch._IMGSEARCH_KEY)
        self.headers =  {'Content-Type': 'multipart/form-data', 'Ocp-Apim-Subscription-Key': MSS_IMGSearch._IMGSEARCH_KEY,}
        pass
    
    def bing_search(self, query_params, body = "{}"):
        _POST_URL = "/bing/v5.0/images/search?%s"
        obj = self.service_execute(_POST_URL, self.headers, query_params, body)
        return obj
    
class MSS_Face(MicrosoftService):
    _SERVICE_URL = 'api.projectoxford.ai'
    _FACE_KEY = '00ba0d2cd01b4bf69678806d5dbf89fd'
    
    def __init__(self):
        super(MSS_Face, self).__init__(service_url = MSS_Face._SERVICE_URL, account_key = MSS_Face._FACE_KEY)
        self.headers =   {'Ocp-Apim-Subscription-Key': MSS_Face._FACE_KEY}
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