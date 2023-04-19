FROM ubuntu:22.10

WORKDIR /apps

RUN echo  apt-get update -y \
    && apt-get -y install xserver-xorg-video-dummy xorg xorg-utils\
    && apt-get -y autoclean; rm -rf /var/lib/apt/lists/*

COPY dummy.conf /apps/dummy.conf

COPY hosts /etc/hosts

RUN X :0 -config /apps/dummy.conf
ENV DISPLAY :0

CMD ["sh","-c","echo 1"]
