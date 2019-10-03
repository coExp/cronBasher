#!/bin/bash

# Script launched from cron do not have access to the environment variables from Kuberancher
# So we need to copy all env into /etc/environment
printenv >> /etc/environment

# Launch cron in foreground
cron -f
