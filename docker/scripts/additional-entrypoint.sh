#!/bin/bash


sudo socat UNIX-LISTEN:/var/run/docker.sock,fork,mode=660,user=${USER} UNIX-CONNECT:/var/run/docker-host.sock &