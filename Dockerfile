FROM fedora:21

MAINTAINER fabric8.io <fabric8@googlegroups.com>

RUN yum install -y npm git && \
	npm install -g yo generator-hubot coffee-script hubot engine.io-client inherits && \
	yum clean all -y

RUN useradd hubot

RUN mkdir -p /home/hubot
	
WORKDIR /home/hubot

RUN mkdir -p hubot-lets-chat/src
ADD package.json hubot-lets-chat/
ADD src hubot-lets-chat/src/
RUN npm link hubot-lets-chat

RUN chown -R hubot:hubot /home/hubot

USER hubot

RUN yo hubot --owner="fabric8.io <fabric8@googlegroups.com>" --name="fabric8" --description="Platform manager" --adapter=lets-chat --defaults

ADD start.sh /home/hubot/

CMD /home/hubot/start.sh


