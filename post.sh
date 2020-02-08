#!/bin/bash
#
# AppDynamics example HTTP POST of metric to Machine Agent HTTP listener
# Maintainer: David Ryder
#
# Reference: https://docs.appdynamics.com/display/PRO45/Standalone+Machine+Agent+HTTP+Listener
#
POST_COUNT=${1:-"5"}
POST_INTERVAL=${2:-"15"}
VERBOSE=""
#VERBOSE="-v"

_AppD_PostSingleMetric() {
  metricName=$1
  aggregatorType=$2
  metricValue1=$(( ( RANDOM % 10 )  + 1 ))
  metricValue2=$(( ( RANDOM % 10 )  + 1 ))
  METRIC_DATA="[                                            \
                  {\"metricName\":\"${metricName}|M1\",     \
                  \"aggregatorType\":\"${aggregatorType}\", \
                  \"value\":\"${metricValue1}\"},               \
                  {\"metricName\":\"${metricName}|M2\",     \
                  \"aggregatorType\":\"${aggregatorType}\", \
                  \"value\":\"${metricValue2}\"}                \
                ]"
  echo "Posting: $METRIC_DATA"
  curl $VERBOSE -s \
       --header "Content-Type: application/json" \
       --data-binary "${METRIC_DATA}" \
       -X POST "http://$APPD_MAC_AGENT_HOST:$APPD_MAC_AGENT_PORT$APPD_MAC_AGENT_PATH"
}

#AGGREGATOR_TYPE="AVERAGE"
#AGGREGATOR_TYPE="SUM"
AGGREGATOR_TYPE="OBSERVATION"

for i in $(seq $POST_COUNT )
do
  _AppD_PostSingleMetric "Custom Metrics|APP_X" $AGGREGATOR_TYPE
  sleep $POST_INTERVAL
done;
