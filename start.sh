#!bin/bash
cd ./tools/skynet

#echo "脚本名称: $0"

serverName=$1
config=$serverName.config
./skynet ../../src/config/$config >/dev/null &
