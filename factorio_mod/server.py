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

if os.name == 'nt':  # 'nt' is the code for Windows
    os.getenv('username')
    outputPath = os.path.join(os.path.expandvars("%userprofile%"), "AppData", "Roaming", "Factorio", "script-output")
    logFileName = 'factARy_log'
    logFileExtension = '.json'
    filepath1 = os.path.join(outputPath, logFileName + '1' + logFileExtension)
    filepath2 = os.path.join(outputPath, logFileName + '2' + logFileExtension)
else:
    # If you are not on Windows, you can manually specify the path to the json files here
    filepath1 = "OS_NOT_SUPPORTED"
    filepath2 = "OS_NOT_SUPPORTED"

# In Windows 10, the filepaths should look something like this:
# filepath1 = r'C:\Users\USERNAME\AppData\Roaming\Factorio\script-output\factARy_log1.json'
# filepath2 = r'C:\Users\USERNAME\AppData\Roaming\Factorio\script-output\factARy_log2.json'
print("Filepath for logfile 1 is: '" + filepath1 + "'")

data = {}


def read_data():
    global filepath1
    global filepath2
    
    if os.path.getmtime(filepath1) > os.path.getmtime(filepath2):
        filepath = filepath2
        print("Using filepath 2")
    else:
        filepath = filepath1
        print("Using filepath 1")
    
    file_string = open(filepath, "r")
    d = json.load(file_string)
    file_string.close()
    return d


def read_attempt_manager():
    global interval
    global lastTime
    global data
    
    if time.time() > lastTime + interval:
        lastTime = time.time()
        try:
            data = read_data()
            print("timestamp path1: " +
                  str(os.path.getmtime(filepath1)) +
                  " timestamp path2: " +
                  str(os.path.getmtime(filepath2)))
            print("tick: " + data["tick"])
            data["status"] = "ok"
            data["error"] = ""
        except ValueError:
            data["status"] = "error"
            data["error"] = "Values Invalid"
            print(f"=== Error: {data['error']}!")
            lastTime = time.time() + 0.01
            data = read_attempt_manager()
        except PermissionError:
            data["status"] = "error"
            data["error"] = "Permission Error"
            print(f"=== Error: {data['error']}!")
            lastTime = time.time() + 0.01
        except FileNotFoundError:
            data["status"] = "error"
            data["error"] = "File not found"
            print(f"=== Error: {data['error']}!")
            lastTime = time.time() + 0.01
    return data


class Root:

    @cherrypy.expose
    def index(self):
        global filepath1
        global data
        global lastTime
        data = read_attempt_manager()

        s = "<h1>FactARy Server </h1><br>"
        s += f"Client IP: {str(cherrypy.request.remote.ip)} <br>"
        s += f"Server Socket: {str(cherrypy.server.socket_host)} <br>"
        s += f"File Path: '{filepath1}' <br>"
        s += f"Last Attempt Time: '{lastTime}' <br>"
        s += f"Status: {data['status']} <br>"
        s += "<br>"

        if len(data['error']) > 0:
            s += f"Error: {data['error']} <br>"
        else:
            s += "Click <a href=\"/json\">here</a> for JSON data"
        
        s += "<br><br>"
        s += "Click <a href=\"/map\">here</a> for the world map <br>"

        return s

    @cherrypy.expose
    @cherrypy.tools.json_out()
    def json(self):
        global data
        data = read_attempt_manager()
        return data

    @cherrypy.expose
    @cherrypy.tools.json_out()
    def map(self):
        global data
        
        data = read_attempt_manager()
        return data


if __name__ == "__main__":
    
    cherrypy.config.update({
                        'server.socket_port': 8042,
                        'server.socket_host': '127.0.0.1',
                        #'server.ssl_module':  'builtin',
                        #'server.ssl_certificate': 'cert.pem',
                        #'server.ssl_certificate': 'fullchain.pem',
                        #'server.ssl_private_key': 'privkey.pem',
                        #'server.ssl_certificate_chain': 'chain.perm'
                       })
    cherrypy.quickstart(Root())
