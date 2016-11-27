'''
Created on 31 Oct 2016

@author: mozat
'''
import json, os
from Service import MSS_Emotion

if __name__ == '__main__':
    service = MSS_Emotion()
    
    print '----start testing emotion from url'
    url = 'https://d.ibtimes.co.uk/en/full/1356835/number-2-u-s-president-barack-obama-second-most-admired-person-planet.jpg?w=400'
    data = service.detect_emotion_url(url)
    json_data = json.loads(data)
    print json_data
    print '----finish testing emotion from url'

    print '----start testing emotion from local img'
    base_dir = os.path.dirname(os.path.abspath(__file__))
    img_path = os.path.join(base_dir, 'photos/face.jpg')
    data = service.detect_emotion_img(img_path)
    json_data = json.loads(data)
    print json_data
    print '----finish testing emotion from local img'
