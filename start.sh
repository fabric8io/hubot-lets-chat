#!/bin/sh -u

export HUBOT_LCB_HOSTNAME=letschat
export HUBOT_LCB_PORT=80

cd /home/hubot

AUTH_HEADER=`echo $LETSCHAT_HUBOT_USERNAME:$LETSCHAT_HUBOT_PASSWORD | base64`
BEARER_TOKEN=""

# Poll every 5 seconds until letschat is up and generates a token
while [ -z "$BEARER_TOKEN" ]
do
    echo "Let's Chat token is empty; lets query again in 5 seconds...."
    sleep 5

    JSON=`curl --silent -X POST  -H "Accept: application/json" -H "Content-type: application/json" -H "Authorization: Basic ${AUTH_HEADER}" -d "{}" http://${LETSCHAT_SERVICE_HOST}:${LETSCHAT_SERVICE_PORT}/account/token/generate`
    echo $JSON
    BEARER_TOKEN=`echo $JSON | jq '.token'`

done
export HUBOT_LCB_TOKEN=$BEARER_TOKEN
bin/hubot -a lets-chat
