#!/system/bin/sh
data=/data/adb/tcp_congestion
sh "${0%/*}/tcpcc" reset
rm -f "$data/selection" "$data/selection.new"
[ ! -d "$data" ] || rmdir "$data"
