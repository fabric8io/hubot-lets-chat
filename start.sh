#!/bin/sh -u

export HUBOT_LCB_HOSTNAME=$LETSCHAT_SERVICE_HOST
export HUBOT_LCB_PORT=$LETSCHAT_SERVICE_PORT

export HUBOT_LOG_LEVEL="debug"

cd /home/hubot

AUTH_HEADER=`echo $LETSCHAT_HUBOT_USERNAME:$LETSCHAT_HUBOT_PASSWORD | base64`

HUBOT_LCB_TOKEN=""

# Poll every 5 seconds until letschat is up and generates a token
while [ -z "$HUBOT_LCB_TOKEN" ]
do
    echo "Let's Chat token is empty; lets query again in 5 seconds...."
    sleep 5

    JSON=`curl --silent -X POST  -H "Accept: application/json" -H "Content-type: application/json" -H "Authorization: Basic ${AUTH_HEADER}" -d "{}" http://${LETSCHAT_SERVICE_HOST}:${LETSCHAT_SERVICE_PORT}/account/token/generate`
    HUBOT_LCB_TOKEN=`echo $JSON | jq '.token'`

    echo "Let's Chat token is: $HUBOT_LCB_TOKEN"
done


bin/hubot -a lets-chat
