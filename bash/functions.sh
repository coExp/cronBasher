#!/bin/bash
SERVICE='cron'
DATADOG_FULL_URL="$DATADOG_URL$DATADOG_APP_API_KEY"
START_DATE=$(date --iso-8601=ns)

# ----------------------------------------------------------------------------------
# DESCRIPTION
#   To easy launch command in cron, and log there results, follow these steps:
#
#   - Configure these variables into your script:
#       PID_FILE="./pids/<command_name>.pid"
#       LOG_FILE="./logs/cron_<command_name>>.log"
#       DATADOG_TAGS="tags,to,send,to,datadog"
#
#   - Import into your script this file with:
#       if [ -f ./bash/functions.sh ]; then
#         . ./bash/functions.sh
#       else
#         echo "Cannot find file \`function.sh\`. Please run into the symfony project."
#         exit 1
#       fi
#
#   - Launch your simple command with:
#       launchScript "sudo myCommand --options arguments"
#
#   - Launch your command until there work to do. Your commad must write number of result on stdout
#       launchUntilScript "sudo myCommand --options arguments" "number of stuff done"
#
#   - Add a boolean in environment variabe in Kuberancher `CRON_<COMMAND_NAME>` to simply start and stop this cron from kuberancher
#
#   - Modify ./jobs/etc/ermeo.crontag
#       * * * * *   www-data  $CRON_<COMMAND_NAME> && cd $PATH_SYMFONY && ./jobs/<command_name>.sh
#
# EXAMPLES
#   Launch simple command
#   @see ./simple_command.sh
#
#   Launch command while work to do
#   @see ./recursive_command.sh
# ----------------------------------------------------------------------------------

# Launch the command and handle returns
# launchScript <COMMAD>
function launchScript {
  testCmd "$1"
  lockScript

  RETURN_MESSAGE=$($CMD)
  RETURN_VALUE=$?
  logMessageToDatadog "$RETURN_MESSAGE" $RETURN_VALUE

  unlockScript

  return $RETURN_VALUE
}

# Launch the command while it works
# launchUntilScript <COMMAND> <SUCCESS_MESSAGE>
function launchUntilScript {
  testCmd "$1"
  SUCCESS_MESSAGE=$2
  lockScript

  NBR_DONE=0
  CONTINUE=true
  while $CONTINUE; do
    # Do not redirect stdError on stdOut!
    # Because we need the return to count result
    RETURN_MESSAGE=$($CMD)
    RETURN_VALUE=$?

    if [[ $RETURN_VALUE != 0 ]]; then
      logMessageToDatadog "$RETURN_MESSAGE" $RETURN_VALUE
      unlockScript
      return $RETURN_VALUE
    fi

    if [[ "$RETURN_MESSAGE" == "0" ]]; then
      CONTINUE=false
    else
      if [[ $RETURN_MESSAGE =~ ^-?[0-9]+$ ]]; then
        NBR_DONE=$((NBR_DONE + RETURN_MESSAGE))
      fi
    fi
  done

  logMessageToDatadog "$NBR_DONE $SUCCESS_MESSAGE" $RETURN_VALUE $NBR_DONE
  unlockScript

  return $RETURN_VALUE
}

# ----------------------------------------------------------------------------------
# DO NOT USE FOLLOWING FUNCTIONS DIRECTLY INTO YOUR SCRIPTS
# ----------------------------------------------------------------------------------
function testCmd {
  CMD=$1
  if [[ "$CMD" == "" ]]; then
    logMessageToDatadog 'Command is not correctly configured.' 126
    exit 2
  fi
}

# Lock the script
function lockScript {
  if [ -f  "$PID_FILE" ]; then
    logMessageToDatadog "A command \`$COMMAND_NAME\` is running" 127
    exit 3 # Another command is running
  fi

  touch "$PID_FILE"
  date > "$PID_FILE"
}

# Unlock the script
function unlockScript {
  rm "$PID_FILE"
}

# Log messages into DATADOG
function logMessageToDatadog {
  local RETURN_MESSAGE=$1
  local RETURN_VALUE=$2
  local NBR_DONE=$3
  local END_DATE
  local STATUS="FAILED"
  local DATADOG_MESSAGE="{}"

  # Message on Stdout
  echo "$RETURN_MESSAGE"

  # Message in log file
  date +"$1: %x %X" >> "$LOG_FILE"

  if [[ "$DATADOG_APP_API_KEY" == "" ]]; then
    echo "DATADOG is not correctly configured!"
    return
  fi

  if [[ "$RETURN_VALUE" == "0" ]]; then
    local STATUS="SUCCESSED"
  fi

  # Clean message with ' and "
  RETURN_MESSAGE=$(echo "$RETURN_MESSAGE" | sed -e 's/"//g' -e "s/'//g")

  # Message to DATADOG
  END_DATE=$(date --iso-8601=ns)
  DATADOG_MESSAGE='{"status":"'$STATUS'","return_value":"'$RETURN_VALUE'","message":"'$RETURN_MESSAGE'","command_name":"'$COMMAND_NAME'","command":"'$CMD'","ddsource":"'$DATADOG_APP_NAME'","host":"'$HOSTNAME'","ddtags":"'$DATADOG_TAGS'","service":"'$SERVICE'","source":"'$SERVICE'","environment":"'$ENVIRONMENT'","date_start":"'$START_DATE'","date_end":"'$END_DATE'","number_done":"'$NBR_DONE'"}'

  curl -X POST "$DATADOG_FULL_URL" \
    -H "Content-Type: application/json" \
    -d "$DATADOG_MESSAGE"
}
