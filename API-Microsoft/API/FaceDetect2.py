import os, json, cStringIO, urllib, time
from Service import MSS_Emotion

if __name__ == '__main__':
    service = MSS_Emotion()
    
    base_dir = os.path.dirname(os.path.abspath(__file__))
    base_dir = os.path.join(base_dir, '../..')
    filename = os.path.join(base_dir, 'face.dat')
    framename = os.path.join(base_dir, 'frame.jpg')

    fp = open(filename, 'w')

    print 'detecting: '
    img_file = framename

    t1 = -1
    tname = 'time.dat'
    if os.path.exists(tname):
        tfp = open(tname, 'r')
        t1 = float(tfp.readline())
        tfp.close()
    if t1 > 0: 
        t2 = time.time()
        print 'time:', (t2 - t1)
        if (t2 - t1 < 3):
            time.sleep(3 + t1 - t2)
    tfp = open(tname, 'w')
    tfp.write(str(time.time()))
    tfp.close()
    obj = service.detect_emotion_img(img_file)
    

    result = json.loads(obj)
    fp.write(str(len(result)))
    fp.write('\n')
    if type(result) != list:
        fp.close()
        pass
    for face in result:
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
        fp.write(str(face))
        fp.write('\n')
    fp.close()
