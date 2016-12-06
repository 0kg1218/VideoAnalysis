'''
Created on 6 Dec 2016

@author: mozat
'''
import os, json

def load_account_info(account_file):
    ACCOUNT_INFO = {}
    try:
        ACCOUNT_INFO = load_json(account_file)
        for account in EMOTION_ACCOUNT:
            if account not in ACCOUNT_INFO:
                ACCOUNT_INFO[account] = 0
    except Exception:
        for account in EMOTION_ACCOUNT:
            ACCOUNT_INFO[account] = 0
    return ACCOUNT_INFO

def join_path(*dirs):
    dir_path = dirs[0]
    for idx in range(1, len(dirs)):
        dir_path = os.path.join(dir_path, dirs[idx])
    return dir_path

def load_json(filename):
    with open(filename) as fb:
        json_info = json.loads(fb.read())
    return json_info
def write_json(json_info, filename):
    with open(filename, 'wt') as fb:
        fb.write(json.dumps(json_info))

EMOTION_ACCOUNT = [
                'fc282e16ff744a50bd11d8fc70f03915',#zhangli's account, consider to buy
                'd7b65479e11a4017a7bbcdbc24732c4a',#gx's account
                '00e840bda4de4f35a551b89bbec71683', #wkg's account
                ]
ACCOUNT_INFO_FILE = 'account.info.json'
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ACCOUNT_INFO = load_account_info(ACCOUNT_INFO_FILE)


