'''
Created on 31 Oct 2016

@author: mozat
'''
import json, os
from Service import MSSEmotion

if __name__ == '__main__':
    EMOTION_KEY = '6d219e9aaf50437d91b8529a71583652'
    service = MSSEmotion(EMOTION_KEY = EMOTION_KEY)
    
    print '----start testing emotion from url'
    url = 'https://d.ibtimes.co.uk/en/full/1356835/number-2-u-s-president-barack-obama-second-most-admired-person-planet.jpg?w=400'
    data = service.detect_emotion_url(url)
    json_data = json.loads(data)
    print json_data
    print '----finish testing emotion from url'

#    print '----start testing emotion from local img'
#    base_dir = os.path.dirname(os.path.abspath(__file__))
#    img_path = os.path.join(base_dir, '1.jpg')
#    data = service.detect_emotion_img(img_path)
#    json_data = json.loads(data)
#    print json_data
#    result = []
#    for face in json_data:
#        tmplist = sorted(face['scores'].items(), key = lambda x: x[1], reverse = True)
#        result.append((face['faceRectangle'], tmplist[0][0], face['scores']))
#    print len(result), result
#    print '----finish testing emotion from local img'
