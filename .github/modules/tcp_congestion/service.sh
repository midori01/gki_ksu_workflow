#!/system/bin/sh
[ -s /data/adb/tcp_congestion/selection ] || exit 0
until [ "$(getprop sys.boot_completed)" = 1 ]; do sleep 2; done
exec sh "${0%/*}/tcpcc" apply
