FROM fedora:21

MAINTAINER fabric8.io <fabric8@googlegroups.com>

RUN yum install -y npm git
RUN npm install -g yo generator-hubot
RUN npm install -g coffee-script
RUN npm install -g hubot




RUN useradd hubot
USER hubot
WORKDIR /home/hubot



RUN yo hubot --owner="fabric8.io <fabric8@googlegroups.com>" --name="fabric8" --description="Platform manager" --adapter=lets-chat --defaults

USER root
RUN mkdir hubot-lets-chat
ADD node_modules/ hubot-lets-chat/
ADD package.json hubot-lets-chat/
ADD src hubot-lets-chat/

RUN npm link hubot-lets-chat
USER hubot

ADD start.sh /home/hubot/



CMD /home/hubot/start.sh


