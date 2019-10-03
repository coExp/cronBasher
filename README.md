cronBasher: Launch cron script
========================

cronBasher helps you to launch command from cron and handle environment variables from Kuberancher. cronBasher locked commands, to avoid launching multiple command in parallel. 

Environment variables
--------------------
PATH_CRON_BASHER: Path to cronBasher project. Set this variable into `/etc/crontab`
DATADOG_URL: URL to log to Datadog. Keep empty to not send log         
DATADOG_APP_API_KEY: your Datadog APP key           
ENVIRONMENT: working environment           

launch_cron.sh
-----------
Remember that scripts launched by cron do not have access to environment variables. 
This script copy environment variables into the file `/etc/environment` and launch `cron` 
Has we launch our script into Kuberancher pod, we use an `ENTRY_POINT` on this script, and run cron in foreground (`cron -f`)
  
Simple command
-----------------
Set PATH_CRON_BASHER into `/etc/crontab` and the line : 
```
* * * * *   www-data  cd PATH_CRON_BASHER && ./simple_command.sh
```
This command use function `launchScript`. The first argument is a string with the command to run.

Recursive command
-----------------
The way of recusive command, is to launch again the command if an action has been made. cronBasher read the number of actiows on the output. If it's not equals to `0`, cronBasher will run command again. It will stop in case of non-zero exit status.  
```
* * * * *   www-data  cd PATH_CRON_BASHER && ./recursive_command.sh
```
This command use function `launchUntilScript`. The first argument is a string with the command to run, the seond one is a message to print with the number of stuffs done.

Send log to Datadog
-------------------
Send all error log to Datadog

Right
-----
Do not forget to add the `executable` right on your script.
