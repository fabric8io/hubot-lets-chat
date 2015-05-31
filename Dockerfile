FROM fedora:21

MAINTAINER fabric8.io <fabric8@googlegroups.com>

RUN yum install -y npm git && \
	npm install -g yo generator-hubot coffee-script hubot && \
	yum clean all -y

RUN useradd hubot
WORKDIR /home/hubot

RUN mkdir hubot-lets-chat
ADD package.json hubot-lets-chat/
ADD src hubot-lets-chat/

RUN npm link hubot-lets-chat && \
	mkdir -p /home/hubot/lc && \
	chown -R hubot:hubot /home/hubot

USER hubot
WORKDIR /home/hubot/lc
RUN yo hubot --owner="fabric8.io <fabric8@googlegroups.com>" --name="fabric8" --description="Platform manager" --adapter=lets-chat --defaults

ADD start.sh /home/hubot/

CMD /home/hubot/start.sh


