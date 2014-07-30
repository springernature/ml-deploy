#!/usr/bin/env bash

host=$1
port=$2
tries=$3

if [ -z "$tries" ]; then
	echo "Usage: $0 <host> <port> <tries>"
	exit 1
fi

for attempt in `seq 1 $tries`
do 
	if `nc $host $port </dev/null &> /dev/null`; then
		echo "Connected to $host:$port on attempt $attempt"
		exit
	fi
	sleep 1
done
echo "Unable to connect to $host:$port after $tries tries."
exit 1
