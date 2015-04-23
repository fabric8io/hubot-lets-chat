function clone_copy_cleanup(){
  # clone repo and cd to git repo but removing the '.git' from the directory name
  dirname=$(basename $1)
  len=${#dirname}-4

  cd /tmp && git clone $1 && cd $(echo "${dirname:0:$len}")

  # Move coffeescripts to Hubot scripts folder so they are installed at startup
	mv *.coffee /home/hubot/scripts/

	cd /home/hubot
	rm -rf /tmp/$(echo "${dirname:0:$len}")
}

clone_copy_cleanup $HUBOT_SCRIPTS_URI

/home/hubot/bin/hubot -a lets-chat