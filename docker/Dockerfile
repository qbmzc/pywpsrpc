FROM congco/wps-office:v1

RUN mkdir -p /apps
WORKDIR /apps
COPY target/*.jar  /apps/
# 开机自启动脚本
COPY ./new.desktop /etc/xdg/autostart/