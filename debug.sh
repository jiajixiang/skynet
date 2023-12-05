#!/bin/sh
if [ -f ./debug_console.txt ]; then
    . ./debug_console.txt
fi

rlwrap -a -I telnet 127.0.0.1 $port | tee .debug.log
