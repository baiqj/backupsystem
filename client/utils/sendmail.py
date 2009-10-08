# -*- coding: utf-8 -*-
#!/usr/bin/python
import os.path
import sys
from smtplib import SMTP
from email.mime.text import MIMEText
import time

Email_settings = {
    'user' : 'auto',
    'passwd':'Abc09*-',
    'server': 'www.lemote.com',
    'from': 'auto@lemote.com',
    'to': '',
    'text': '',
    'subject': '',
}

def send_mail(config):
    
    msg = MIMEText(config['text'], _charset = 'UTF-8')
    
    msg['From'] = config['from']
    msg['To'] = ', '.join (config['to'])
    msg['Subject'] = config['subject']
    msg['Date'] = time.ctime()
    
    s = SMTP (config['server'])
    s.login (config['user'], config['passwd'])
    s.sendmail (config['from'], config['to'], msg.as_string ())
    s.quit ()

if __name__ == "__main__":
    if len(sys.argv) < 4:
        print 'Usage: python %s <subject> <text file path> receiver1 receiver2 ...' % os.path.basename(sys.argv[0])
    else:
        config = Email_settings
        
        config['subject'] = sys.argv[1]
        config['text'] = open(os.path.abspath(sys.argv[2]), 'r').read()
        receivers = []
        for i in xrange(3, len(sys.argv)):
            receivers.append(sys.argv[i])
        config['to'] = receivers

        send_mail (config)
