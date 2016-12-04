'''
Created on 1 Nov 2016

@author: mozat
'''
from Service import MSS_IMGSearch
import json


if __name__ == '__main__':
    service = MSS_IMGSearch()
    query_params = {
        'q': 'person',
        'count': '10',
        'offset': '0',
        'mkt': 'en-us',
        'safeSearch': 'Moderate',
    }
    obj = service.bing_search(query_params)
    searchedIms = json.loads(obj)
    searchedIms = searchedIms['value']
    print searchedIms[0]['contentUrl']
