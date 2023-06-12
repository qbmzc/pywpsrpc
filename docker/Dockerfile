FROM images.taimei.com/middle/wps-office:v2.0.0
#
#RUN echo  apt-get update -y \
#    && apt-get -y install xserver-xorg-video-dummy xorg xorg-utils\
#    && apt-get -y autoclean; rm -rf /var/lib/apt/lists/*
#
#COPY dummy.conf /apps/dummy.conf
#
#COPY hosts /etc/hosts
COPY start.sh /opt/start.sh
RUN chmod +x /opt/start.sh
ENV DISPLAY :0

ENTRYPOINT ["/opt/start.sh"]
