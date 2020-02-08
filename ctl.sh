#!/bin/bash
#
. envvars.appd.sh

APPD_LOGS_DIR="/logs"
mkdir -p $APPD_LOGS_DIR

_AppDynamicsStartMachineAgent() {
  . envvars.controller1.sh
  pkill -f ".*machineagent.jar"
  HTTP_LISTENER_OPTS=" -Dmetric.http.listener=true -Dmetric.http.listener.port=8081 "
  mkdir -p $MAC_AGENT_DIR
  unzip $APPD_MACHINE_AGENT_ZIP_FILE -d $MAC_AGENT_DIR
  nohup ./$MAC_AGENT_DIR/bin/machine-agent $HTTP_LISTENER_OPTS > $APPD_LOGS_DIR/macagent.log 2>&1 &
}

MAC_AGENT_DIR="/macagent"

_AppDynamicsStartMachineAgent




sleep 3600
