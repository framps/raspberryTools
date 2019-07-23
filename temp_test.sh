#!/bin/bash
#
# Small script which generates 100% CPU load on a Raspberry and
# monitors the CPU temperature. Useful to test the effectiveness of
# a heat sink and/or a fan.
#
# Based on
# temp_test.sh - Raspberry Pi 4 Cooling - Christopher Barnatt
# Youtube channel: ExplainingComputers - https://www.youtube.com/channel/UCbiGcwDWZjz05njNPrJU7jA
# Enhanced by framp
#
# Copyright (C) 2019 framp at linux-tips-and-tricks dot de

# defaults
WATCH_INTERVAL=15 # seconds
MAX_PRIMES=25000
SILENT=0
WATCH_PID=""
VERBOSE=0

function help() {
	echo "Generate 100% CPU usage and measure CPU temperature."
	echo "-i <CPU temperature watch interval in seconds>"
	echo "-s no CPU temperature watch"
}

function watch() {
	while :; do
		echo -n "Watch +${watch_offset}s:"
		vcgencmd measure_temp
		sleep $WATCH_INTERVAL
		(( watch_offset += $WATCH_INTERVAL ))
	done
}

function cleanup() {
	(( $VERBOSE )) && echo "... Cleanup $WATCH_PID"
	kill -9 $WATCH_PID  &>/dev/null
	trap - SIGINT SIGTERM EXIT
	exit
}

clear
watch_offset=0

while getopts "h?i:p:sv" opt; do
    case "$opt" in
    h|\?)
        help
        exit 0
        ;;
    i)  WATCH_INTERVAL="$OPTARG"
        ;;
    p)  MAX_PRIMES="$OPTARG"
	;;
    s)  SILENT=1
	;;
    v)  VERBOSE=1
	;;
    esac
done

if ! which sysbench; then
	echo "??? Missing sysbench. Install first with 'sudo apt-get install sysbench'"
	exit 42
fi

echo "Generate 100% CPU utilization and measure CPU temperature ..."
if (( ! $SILENT )); then
	echo "CPU watch interval: ${WATCH_INTERVAL}s"
	echo
	watch &
	WATCH_PID=$!
	(( $VERBOSE )) && echo "Created PID $WATCH_PID"
	trap cleanup SIGINT SIGTERM EXIT
fi

START_TIME=$SECONDS
for f in {1..7}; do
	t=$(vcgencmd measure_temp)
	echo "Starting run $f: +$(( $SECONDS - $START_TIME ))s:$t"
	sysbench --test=cpu --cpu-max-prime=$MAX_PRIMES --num-threads=4 run &>/dev/null
done

echo -n "Final "
vcgencmd measure_temp
END_TIME=$SECONDS
DURATION_TIME=$(( $END_TIME - $START_TIME ))
TZ=UTC0 printf 'Time used: %(%H:%M:%S)T\n' $DURATION_TIME
