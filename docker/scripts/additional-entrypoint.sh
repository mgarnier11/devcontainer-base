#!/bin/bash

dockerd > /var/log/dockerd.log 2>&1 &

# sudo socat UNIX-LISTEN:/var/run/docker.sock,fork,mode=660,user=${USER} UNIX-CONNECT:/var/run/docker-host.sock &