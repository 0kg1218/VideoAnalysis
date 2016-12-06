'''
Created on 5 Dec 2016

@author: mozat
'''
import dlib
import cv2
import numpy as np

class dlib_detector(object):
    def __init__(self):
        self.detector = dlib.get_frontal_face_detector()
        super(dlib_detector, self).__init__()
    
    
    def generate_img(self, img):
        img = cv2.resize(img, (0,0), fx=0.5, fy=0.5)
        rows, cols = img.shape[0], img.shape[1]
        img1 = img[0:rows/4, 0:cols/5, :]#1
        img2 = img[0:rows/4, (cols*3/5):(cols*4/5),:]#5
        img3 = img[(rows/4):(rows*2/4), (cols*2/5):(cols*3/5),:]#9
        img4 = img[(rows*2/4):(rows*3/4), (cols*1/5):(cols*2/5),:]#13
        img5 = img[(rows*3/4):(rows*4/4), (cols*0/5):(cols*1/5),:]#17
        img6 = img[(rows*3/4):(rows*4/4), (cols*4/5):(cols*5/5),:]#20
        img = np.concatenate((np.concatenate((img1, img2, img3), axis = 1), np.concatenate((img4, img5, img6), axis = 1)), axis = 0)
        return img
        
    
    def detect_img(self, img):
        self.img = img
        self.img = self.generate_img(img)
        dets, scores, idx = self.detector.run(self.img, 1, -0.3)
#         self.scores = scores
#         dets = self.detector(self.img, 1)
        self.dets = dets
        return dets
    
    def detect_img_file(self, img_file):
        img = cv2.imread(img_file)
        self.img = self.generate_img(img)
        dets, scores, idx = self.detector.run(self.img, 1, -0.3)
#         self.scores = scores
#         dets = self.detector(self.img, 1)
        self.dets = dets
        return dets
    
    def draw_detection(self):
        win = dlib.image_window()
        win.clear_overlay()
        win.set_image(self.img)
        win.add_overlay(self.dets)
        dlib.hit_enter_to_continue()
        
if __name__ == '__main__':
    img_name = './photos/face.jpg'
    detector = dlib_detector()
    detector.detect(cv2.imread(img_name))
    detector.draw_detection()
    