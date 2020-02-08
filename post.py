# AppDynamics example HTTP POST of metric to Machine Agent HTTP listener
# Maintainer: David Ryder
#
# Reference: https://docs.appdynamics.com/display/PRO45/Standalone+Machine+Agent+HTTP+Listener
#
import os
import sys
import requests
import json
import time
from random import randint


def createMetricData():
    metricData =  [
                    { "metricName": "Custom Metrics|APP_X|M3",
                      "aggregatorType": "OBSERVATION",
                      "value": randint(1,10) },
                    { "metricName": "Custom Metrics|APP_X|M4",
                      "aggregatorType": "OBSERVATION",
                      "value": randint(1,10) },
                   ]
    return metricData

try:
    machineAgent = {
        "host": os.environ["APPD_MAC_AGENT_HOST"],
        "port": os.environ["APPD_MAC_AGENT_PORT"],
        "path": os.environ["APPD_MAC_AGENT_PATH"],
        "headers": { "Content-Type": "application/json" }
    }
except Exception as e:
    print( "Environment variable ({}) not set ".format(e))
    exit()

postCount  = int( sys.argv[1] ) if len(sys.argv) > 1 else 5
postInterval = float( sys.argv[2] ) if len(sys.argv) > 2 else 15
s = requests.session()

for i in range(0,postCount):
    data = createMetricData()
    print( "Posting: {}".format(data))
    r = requests.post("http://{}:{}{}".format(machineAgent["host"],
                                              machineAgent["port"],
                                              machineAgent["path"]),
                        data=json.dumps( data ), headers=machineAgent["headers"])
    print( r )
    time.sleep( postInterval )
