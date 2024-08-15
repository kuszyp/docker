#!/bin/bash
set -e

USER_HOME="/home/soapuser"
PROPERTIES_FILE="$USER_HOME/server.properties"
SOAPUI_PROJECT_FILE="$USER_HOME/wso2is-init-project.xml"
CMD_ARGS=""

while IFS="=" read -r key value; do
  CMD_ARGS="$CMD_ARGS -P$key='$value'"
done <$PROPERTIES_FILE

echo $CMD_ARGS | xargs /opt/SoapUI/bin/testrunner.sh $SOAPUI_PROJECT_FILE
