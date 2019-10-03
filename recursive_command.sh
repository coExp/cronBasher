#!/bin/bash

COMMAND_NAME="recurcive_command"
PID_FILE="./pids/$COMMAND_NAME.pid"
LOG_FILE="./logs/$COMMAND_NAME.log"
DATADOG_TAGS="cron,synchro,register_envents,$ENVIRONMENT"

# Import common functions
if [ -f ./bash/functions.sh ]; then
  . ./bash/functions.sh
else
  echo "Cannot find file \`function.sh\`. Please run into the cronBasher project."
  exit 1
fi

# Launch your command while job to do
launchUntilScript './example/random.sh'
exit $?
