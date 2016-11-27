'''
Created on 1 Nov 2016

@author: mozat
'''
import os, json, cStringIO, urllib, time
from Service import MSS_Emotion
#from PIL import Image, ImageDraw

if __name__ == '__main__':
    service = MSS_Emotion()
    
    base_dir = os.path.dirname(os.path.abspath(__file__))
    base_dir = os.path.join(base_dir, '../..')
    filename = os.path.join(base_dir, 'face.dat')
    jsonfile = os.path.join(base_dir, 'json.dat')
    filelistname = os.path.join(base_dir, 'frame_list.dat')
    frame_dir = os.path.join(base_dir, 'frames')

    file_list = []
    fl = open(filelistname, 'r')
    while 1:
        line = fl.readline()
        if not line:
            break
        line = line[:-1]
        file_list.append(line)
    fl.close()

    fp = open(filename, 'w')
    fp.write(str(len(file_list)))
    fp.write('\n')

    jsonfp = open(jsonfile, 'w')
    #jsonfp.write(str(len(file_list)))
    #jsonfp.write('\n')

    for file in file_list:
        print 'detecting: ' + file
        img_file = os.path.join(frame_dir, file)
        obj = service.detect_emotion_img(img_file)
        result = json.loads(obj)
        #fp.write(file)
        #fp.write(' ')
        fp.write(str(len(result)))
        fp.write('\n')
        if type(result) != list:
            #print result
            time.sleep(3)
            continue
        #print result
        for face in result:
            #fp.write(' ')
            fp.write(str(face['faceRectangle']['left']))
            fp.write(' ')
            fp.write(str(face['faceRectangle']['top']))
            fp.write(' ')
            fp.write(str(face['faceRectangle']['width']))
            fp.write(' ')
            fp.write(str(face['faceRectangle']['height']))
            flist = list()
            flist.append(float(face['scores']['anger']))
            flist.append(float(face['scores']['contempt']))
            flist.append(float(face['scores']['disgust']))
            flist.append(float(face['scores']['fear']))
            flist.append(float(face['scores']['happiness']))
            flist.append(float(face['scores']['neutral']))
            flist.append(float(face['scores']['sadness']))
            flist.append(float(face['scores']['surprise']))
            maxv = max(flist)
            maxi = flist.index(maxv)
            fp.write(' ')
            fp.write(str(maxi))
            fp.write('\n')
            jsonfp.write(str(face))
            jsonfp.write('\n')
        time.sleep(3)
    fp.close()
    jsonfp.close()