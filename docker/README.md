# 容器中使用wps转pdf 

---
说明：本方案使用的wps带有桌面环境，需要在桌面环境下使用，也就是你的应用程序需要运行在桌面环境 而不是命令行下

否则会出现`Can't get the application`错误

也可以使用服务器版本的，[RUN ON SERVER](README_SERVER.md)

## [镜像地址](https://hub.docker.com/repository/docker/congco/wps-office)

```shell
docker push congco/wps-office:tagname
```

## 已知缺陷

容器化 命令模式下启动的服务 无法找到wps应用,需要登陆Linux桌面,在桌面模式(GUI)下启动服务.

### 解决方案

开机自启动服务,参照Dockerfile，也可将转换脚本放到web服务中（比如flask）进行调用

## 制作镜像

- [基础镜像-ubuntu](https://hub.docker.com/r/fullaxx/ubuntu-desktop)

- 启动镜像并设置开机密码
```shell
docker run -d -p 5901:5901 -e VNCPASS='vncpass' fullaxx/ubuntu-desktop
# 可以进入容器中，也可以vnc远程登陆到桌面环境
```

![202205061922065](https://fastly.jsdelivr.net/gh/qbmzc/images/2022/202205061922065.png)

![202205061923231](https://fastly.jsdelivr.net/gh/qbmzc/images/2022/202205061923231.png)

- 安装wps
```shell
#下载wps,可以自行替换版本
wget -c https://wps-linux-personal.wpscdn.cn/wps/download/ep/Linux2019/10976/wps-office_11.1.0.10976_amd64.deb
 
# 依赖
apt update
apt install libglu1-mesa bsdmainutils qt5-default
# 安装
dpkg -i wps-office_11.1.0.10976_amd64.deb
```

- 安装字体

[https://github.com/qbmzc/wps-font-symbols](https://github.com/qbmzc/wps-font-symbols)
```shell
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
pip install pywpsrpc -i https://pypi.tuna.tsinghua.edu.cn/simple
```

### 文档互转
 - [WPS文字](examples/rpcwpsapi/convertto)
 - [WPS演示](examples/rpcwppapi/wpp_convert.py)
 - [WPS表格](examples/rpcetapi/et_convert.py)


## 转换pdf

```shell
python convert.py -f pdf input.docx
```

## jdk8环境

根据需要安装相关应用依赖

```dockerfile
FROM images.taimei.com/middle/wps-office:v2.0.0
COPY win /usr/share/fonts/win/
# 中文支持
ENV LANG C.UTF-8
# 自行下载jdk
ADD zulu8.70.0.23-ca-jdk8.0.372-linux_x64.tar.gz /opt/

ENV JAVA_HOME /opt/zulu8.70.0.23-ca-jdk8.0.372-linux_x64
ENV PATH $PATH:$JAVA_HOME/bin
# 安装其他依赖
RUN apt-get -y update&& apt-get install curl -y \
     && apt-get -y autoclean; rm -rf /var/lib/apt/lists/*
```

## docker打包

```shell
# 替换自己的容器ID
 docker commit -a "cong.co" -m "wps" {containerId} wps-office:v1
 # 推送
 docker push wps-office:v1
```

## Java 服务使用示例 Dockerfile

```dockerfile
FROM congco/wps-office:v1

RUN mkdir -p /apps
WORKDIR /apps
COPY target/*.jar  /apps/
# 开机自启动脚本
COPY ./new.desktop /etc/xdg/autostart/
```

## new.desktop

```shell
[Desktop Entry]
Version=1.0.0
Name=new-doc
Exec=xfce4-terminal -e="java -jar /apps/*.jar" # 使用terminal启动java服务
Type=Application
```

## docker-compose

```yaml
version: "3"
 
services:
  new-doc01:
    container_name: new-doc-01
    image: congco/wps-office:v1
    restart: always
    volumes:
      - /data/01/webapps:/data/webapps
      ## 禁止wps在无网络环境下请求DNS解析联网
      - /data/resolv.conf:/etc/resolv.conf:ro 

 
  new-doc02:
    container_name: new-doc-02
    image: congco/wps-office:v1
    restart: always
    volumes:
      - /data/02webapps:/data/webapps
       ## 禁止wps在无网络环境下请求DNS解析联网
      - /data/resolv.conf:/etc/resolv.conf:ro
```

## 参考资料

- [docker-ubuntu-vnc-desktop](https://github.com/fcwu/docker-ubuntu-vnc-desktop)
- [docker commit](https://www.runoob.com/docker/docker-commit-command.html)
- [用docker创建ubuntu VNC桌面](https://blog.csdn.net/arag2009/article/details/78465214)
- [wps](https://open.wps.cn/docs/client/wpsLoad)


