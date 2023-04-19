# 容器中使用wps转pdf 

---
说明：本方案使用的wps带有桌面环境

也可以使用服务器版本的，方法类似，这里不做说明

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
 strip --remove-section=.note.ABI-tag /lib/x86_64-linux-gnu/libQt5Core.so.5
```

3. ImportError: /usr/lib/office6/libstdc++.so.6: version `GLIBCXX_3.4.29' not found (required by /usr/lib/libQt5Core.so.5)

```shell
sudo rm /usr/lib/office6/libstdc++.so.6 
sudo ln -s /usr/lib64/libstdc++.so.6 /usr/lib/office6/libstdc++.so.6
```

## openjdk8

根据需要安装相关应用依赖

```shell
apt-get update
apt-get install openjdk-8-jdk
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

