#!/bin/sh -u

function clone_copy_cleanup(){
  # clone repo and cd to git repo but removing the '.git' from the directory name
  dirname=$(basename $1)
  len=${#dirname}-4

  cd /tmp && git clone $1 && cd $(echo "${dirname:0:$len}")

  # Move coffeescripts to Hubot scripts folder so they are installed at startup
  mv *.coffee /home/hubot/scripts

  rm -rf /tmp/$(echo "${dirname:0:$len}")
}

export HUBOT_LCB_HOSTNAME=$LETSCHAT_SERVICE_HOST
export HUBOT_LCB_PORT=$LETSCHAT_SERVICE_PORT

clone_copy_cleanup $LETSCHAT_HUBOT_SCRIPTS
cd /home/hubot

AUTH_HEADER=`echo $LETSCHAT_HUBOT_USERNAME:$LETSCHAT_HUBOT_PASSWORD | base64`

JSON=`curl --silent -X POST  -H "Accept: application/json" -H "Content-type: application/json" -H "Authorization: Basic ${AUTH_HEADER}" -d "{}" http://${LETSCHAT_SERVICE_HOST}:${LETSCHAT_SERVICE_PORT}/account/token/generate`

export HUBOT_LCB_TOKEN=`echo $JSON | jq '.token'`

echo "Token is $HUBOT_LCB_TOKEN"

bin/hubot -a lets-chat