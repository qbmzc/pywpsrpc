# RUN ON SERVER

---

## [镜像地址](https://hub.docker.com/repository/docker/congco/wps-office)

```shell
docker push congco/wps-office:tagname
```

## 制作镜像

```shell
# 基础镜像为Ubuntu18.04LTS
docker run --rm -it --name ubuntu-1804 ubuntu:18.04 bash
```

## 更换国内源

```shell
# 默认注释了源码镜像以提高 apt update 速度，如有需要可自行取消注释
deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic main restricted universe multiverse
deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-updates main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-updates main restricted universe multiverse
deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-backports main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-backports main restricted universe multiverse

# deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-security main restricted universe multiverse
# # deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-security main restricted universe multiverse

deb http://security.ubuntu.com/ubuntu/ bionic-security main restricted universe multiverse
# deb-src http://security.ubuntu.com/ubuntu/ bionic-security main restricted universe multiverse

# 预发布软件源，不建议启用
# deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-proposed main restricted universe multiverse
# # deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-proposed main restricted universe multiverse
```

## 制作镜像

- 安装wps

```shell
#下载wps,可以自行替换版本
# https://wps-linux-personal.wpscdn.cn/wps/download/ep/Linux2019/11698/wps-office_11.1.0.11698_amd64.deb
wget -c https://wps-linux-personal.wpscdn.cn/wps/download/ep/Linux2019/10976/wps-office_11.1.0.10976_amd64.deb
 
# 依赖
apt update
apt install libglu1-mesa bsdmainutils qt5-default xdg-utils
# 安装
dpkg -i wps-office_11.1.0.10976_amd64.deb
```

- 安装字体

[https://github.com/qbmzc/wps-font-symbols](https://github.com/qbmzc/wps-font-symbols)

```shell
wget https://github.com/qbmzc/wps-font-symbols/archive/refs/heads/master.zip
apt install unzip
unzip master.zip
#拷贝字体到 usr/share/fonts
cp -r ./wps-font-symbols /usr/share/fonts/
 
 
fc-cache -vf
```

- 安装python环境

```shell
apt update
# python3-lxml libxslt.so.1
apt install python3 python3-pip python3-lxml

# 安装pywpsrpc
pip3 install pywpsrpc -i https://pypi.tuna.tsinghua.edu.cn/simple
```

### 文档互转

- [WPS文字](examples/rpcwpsapi/convertto)
- [WPS演示](examples/rpcwppapi/wpp_convert.py)
- [WPS表格](examples/rpcetapi/et_convert.py)

## Run On Server

```shell
#模拟x环境
apt install xserver-xorg-video-dummy
```

- dummy.conf

```shell
Section "Monitor"
        Identifier "dummy_monitor"
        HorizSync 28.0-80.0
        VertRefresh 48.0-75.0
        Modeline "1920x1080" 172.80 1920 2040 2248 2576 1080 1081 1084 1118
EndSection

Section "Device"
        Identifier "dummy_card"
        VideoRam 256000
        Driver "dummy"
EndSection

Section "Screen"
        Identifier "dummy_screen"
        Device "dummy_card"
        Monitor "dummy_monitor"
        SubSection "Display"
        EndSubSection
EndSection
```

Now start the Xorg (with root):

```shell
# 启动x服务
X :0 -config dummy.conf
```

```shell
# 设置环境变量
export DISPLAY=:0
```

## EULA

```shell
vim /root/.config/Kingsoft/Office.conf
# 末尾添加
common\AcceptedEULA=true

#或者
echo "common\AcceptedEULA=true" >> /root/.config/Kingsoft/Office.conf
```

## 转换pdf

```shell
python convert.py -f pdf input.docx
```

## 问题

1. 转换卡顿问题或超时

本地部署一般为局域网访问，不开通外网，wps有外网连接请求，在没网的环境下会导致转换过慢，甚至会导致转换超时失败。

```shell
# 可使用tcpdump抓包分析

tcpdump -i eth0 -nt -s 500 port domain
```

解决方案

- 将resolv.conf中的DNS解析服务器设置为空
- docker中可以挂载一个空文件映射到/etc/resolv.conf
- /etc/hosts 添加以下内容(由于有些部署方式会替换容器host，这里没有在容器内修改，可以在配置中添加主机别名)

```shell
127.0.0.1 s1.vip.wpscdn.cn
127.0.0.1 dw-online.ksosoft.com
```

2. libQt5Core.so.5: cannot open shared object file

```bash
 apt-get install libqt5core5a
 strip --remove-section=.note.ABI-tag /usr/lib/x86_64-linux-gnu/libQt5Core.so.5
```

3. ImportError: /usr/lib/office6/libstdc++.so.6: version `GLIBCXX_3.4.29' not found (required by
   /usr/lib/libQt5Core.so.5)

```shell
sudo rm /usr/lib/office6/libstdc++.so.6 
sudo ln -s /usr/lib64/libstdc++.so.6 /usr/lib/office6/libstdc++.so.6
```

4. et转换失败 error: libltdl.so.7: cannot open shared object file: No such file or directory

```shell
# dlopen /opt/kingsoft/wps-office/office6/libetmain.so failed , error: libltdl.so.7: cannot open shared object file: No such file or directory
# Convert failed:
# Details: Can't get the application
# ErrCode: 0x80000008
apt install libltdl7
```

## 使用示例

```dockerfile
FROM images.taimei.com/middle/wps-office:v2.0.4
MAINTAINER congco
ARG QUEUE=doc_convert_test
ENV QUEUE $QUEUE
WORKDIR /k8sapps
COPY *.py  /opt/
COPY target/new-doc-convert-0.0.1-SNAPSHOT.jar  /k8sapps/
#RUN echo "java -jar /k8sapps/new-doc-convert-0.0.1-SNAPSHOT.jar" >> /root/.bashrc
#COPY ./new.desktop /etc/xdg/autostart/
#RUN echo "Exec=xfce4-terminal -e='java -Dspring.profiles.active=${PROFILES_ACTIVE} -Dqueue=${QUEUE} -jar /k8sapps/new-doc-convert-0.0.1-SNAPSHOT.jar '" >> /etc/xdg/autostart/new.desktop
COPY start.sh /opt/start.sh
RUN chmod +x /opt/start.sh
ENV DISPLAY :0
ENTRYPOINT ["/opt/start.sh"]

```

- start.sh

```shell
#! /bin/bash

echo "start X server"

nohup X :0 -config /etc/dummy.conf > /dev/null 2>&1 &
echo "X server start successful!"
echo "start java server"
java ${JAVA_OPTS}  -jar /k8sapps/new-test-0.0.1-SNAPSHOT.jar
```