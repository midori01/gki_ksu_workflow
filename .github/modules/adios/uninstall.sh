#!/system/bin/sh
MODDIR=${0%/*}
if [ -f "$MODDIR/common.sh" ]; then
	. "$MODDIR/common.sh"
	p=$(read_pref)
	if [ -n "$p" ] && [ -f "$ADIOS_ORIG" ] && [ "$(head -n 1 "$ADIOS_ORIG")" = "$(boot_id)" ]; then
		sed -n '2,$p' "$ADIOS_ORIG" | awk '!seen[$1]++' | while read -r d s; do
			[ -n "$s" ] && [ "$(dev_current "$d")" = "$p" ] && set_dev "$d" "$s"
		done
	fi
fi
rm -rf /data/adb/adios
