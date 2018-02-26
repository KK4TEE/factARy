#!/usr/bin/python3
################################################################################
# Python 3
# Author: KK4TEE
# Licence: MIT
# Summary: Read data from Factorio and host via http
# Note:    Yes, I know this is a crude script. Proof of concept only. No warranty whatsoever. 
################################################################################

import cherrypy
import json
import os
import time

lastTime = 0
interval = 0.033
## CHANGE THE BELOW PATHS TO POINT TO YOUR FACTORIO DIRECTORY ##
filepath1 = r'C:\Users\USERNAME\AppData\Roaming\Factorio\script-output\factARy_log1.json'
filepath2 = r'C:\Users\USERNAME\AppData\Roaming\Factorio\script-output\factARy_log2.json'
data = {}

def readData():
    global filepath1
    global filepath2
    
    if (os.path.getmtime(filepath1) > os.path.getmtime(filepath2)):
        filepath = filepath2
        print("Using filepath 2")
    else:
        filepath = filepath1
        print("Using filepath 1")
    
    filestring = open(filepath, "r")
    d = json.load(filestring)
    filestring.close()
    return d


def ReadAttemptManager():
    global interval
    global lastTime
    global data
    
    if time.time() > lastTime + interval:
        lastTime = time.time()
        try:
            data = readData()
            print("timestamp path1: " +
                  str(os.path.getmtime(filepath1)) +
                  " timestamp path2: " +
                  str(os.path.getmtime(filepath2)))
            print("tick: " + data["tick"])
        except ValueError:
            print("=== Error: Values Invalid!")
            lastTime = time.time() + 0.01
            data = ReadAttemptManager()
        except PermissionError:
            print("=== Error: Permission Error!")
            lastTime = time.time() + 0.01
        except FileNotFoundError:
            print("=== Error: File not found!")
            lastTime = time.time() + 0.01
    return data

################################################################################

class Root:

    @cherrypy.expose
    def index(self):
        s = "<h1>FactARy Server </h1><br>"
        s += "Client IP: "
        s += str(cherrypy.request.remote.ip)
        s += "<br>Server Socket: "
        s += str(cherrypy.server.socket_host)
        return s

    @cherrypy.expose
    @cherrypy.tools.json_out()
    def json(self):
        global data
        data = ReadAttemptManager()
        return data

################################################################################

if __name__ == "__main__":
    
    cherrypy.config.update({
                        'server.socket_port': 8042,
                        'server.socket_host': '0.0.0.0',
                        #'server.ssl_module':  'builtin',
                        #'server.ssl_certificate': 'cert.pem',
                        #'server.ssl_certificate': 'fullchain.pem',
                        #'server.ssl_private_key': 'privkey.pem',
                        #'server.ssl_certificate_chain': 'chain.perm'
                       })
    cherrypy.quickstart(Root())
