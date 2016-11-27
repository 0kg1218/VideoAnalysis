'''
Created on 1 Nov 2016

@author: mozat
'''

from Service import MSS_NLPText

if __name__ == '__main__':
    service = MSS_NLPText()
    input_texts = '{"documents":[{"id":"1","text":"hello world"},{"id":"2","text":"hello foo world"},{"id":"three","text":"hello my world"},]}'
    obj = service.detect_keyphrase(input_texts)
    print obj
    obj = service.detect_language(input_texts, 1)
    print obj
    obj = service.detect_sentiment(input_texts)
    print obj
    pass