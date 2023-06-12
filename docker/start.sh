#! /bin/bash

echo "start X server"

nohup X :0 -config /etc/dummy.conf > /dev/null 2>&1 &
echo "X server start successful!"
echo "start convert"
python3 /opt/convert.py a.md -f pdf