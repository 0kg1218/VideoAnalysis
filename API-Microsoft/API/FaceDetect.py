'''
Created on 1 Nov 2016

@author: mozat
'''
import os, json, cStringIO, urllib
from Service import MSS_Face
from PIL import Image, ImageDraw


def draw_faces(img_name, local_flag, microsoft_json, outname = 'result.jpg'):
    if not local_flag:
        image = cStringIO.StringIO(urllib.urlopen(img_name).read())
    else:
        image = img_name
    im = Image.open(image)
    draw = ImageDraw.Draw(im)
    faces = microsoft_json[0]['faceRectangle']
    draw.rectangle([(faces['left'], faces['top']), (faces['left'] + faces['width'], faces['top'] + faces['height'])], \
                   fill=None, outline='red')
    
    landmarks = microsoft_json[0]['faceLandmarks']
    for mark_name, pts in landmarks.iteritems():
        draw.rectangle([(pts['x']-2,pts['y']-2),(pts['x']+2,pts['y']+2)], fill='green', outline='green')
    del draw
    im.save(outname)

def parse_miscoft_json(microsoft_json):
    print "we process the top 1 faces", microsoft_json[0]['faceId']
    print "gender:", microsoft_json[0]['faceAttributes']['gender']
    print "age:", microsoft_json[0]['faceAttributes']['age']
    print "facialHair:", microsoft_json[0]['faceAttributes']['facialHair']
    print "headPose:", microsoft_json[0]['faceAttributes']['headPose']
    print "smile:", microsoft_json[0]['faceAttributes']['smile']
    print "glasses:", microsoft_json[0]['faceAttributes']['glasses']


if __name__ == '__main__':
    service = MSS_Face()
    print '--start testing face detection from url'
    img_url = 'https://www.conservativereview.com/sss/media/images/conservative-review/article-images/2016/august/obama-bad-face.jpg'
    obj = service.detect_face_url(img_url)
    result = json.loads(obj)
    parse_miscoft_json(result)
    draw_faces(img_url, local_flag = 0, microsoft_json = result, outname = 'result1.jpg')
    print '--finish testing face from url'
    
    base_dir =os.path.dirname(os.path.abspath(__file__))
    print base_dir
    img_file = os.path.join(base_dir, 'photos/face.jpg')
    obj = service.detect_face_img(img_file)
    result = json.loads(obj)
    parse_miscoft_json(result)
    draw_faces(img_file, local_flag = 1, microsoft_json = result, outname = 'result2.jpg')
    pass