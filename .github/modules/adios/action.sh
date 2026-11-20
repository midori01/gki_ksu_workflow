#!/system/bin/sh
MODDIR=${0%/*}
. "$MODDIR/common.sh"

wait_key() {
	end=$(($(date +%s) + 15))
	while :; do
		left=$((end - $(date +%s)))
		[ "$left" -gt 0 ] || break
		ev=$(timeout "$left" getevent -lqc 1 2>/dev/null)
		case $ev in
			*KEY_VOLUMEUP*DOWN*) echo up; return ;;
			*KEY_VOLUMEDOWN*DOWN*) echo down; return ;;
		esac
	done
	echo none
}

case $(adios_mode) in
	builtin) mode="built-in" ;;
	lkm) mode="LKM" ;;
	*) mode="unavailable" ;;
esac
[ -f "$ADIOS_SAFE" ] && mode="$mode, safe mode"

snapshot_original
echo "ADIOS I/O Scheduler ($mode)"
v=$(adios_version)
[ -n "$v" ] && echo "Version: $v"
echo
for d in $(block_devs); do
	echo "  $d: $(dev_current "$d") (original: $(orig_of "$d"))"
done
echo

pref=$(read_pref)
set -- default $(all_schedulers)
[ "$(adios_mode)" = missing ] && [ -n "$(lkm_candidates)" ] && ! all_schedulers | grep -qx adios && set -- "$@" adios

idx=1
i=1
for o in "$@"; do
	[ "$o" = "${pref:-default}" ] && idx=$i
	i=$((i + 1))
done
total=$#

label() {
	if [ "$1" = default ]; then
		echo "System default"
	else
		echo "$1"
	fi
}

nth() {
	shift "$1"
	echo "$1"
}

echo "Current default: $(label "${pref:-default}")"
echo
echo "Volume Up: next option"
echo "Volume Down: apply"
echo "No key for 15s: cancel"
echo

while :; do
	echo "> $(label "$(nth "$idx" "$@")")"
	case $(wait_key) in
		up)
			idx=$((idx % total + 1))
			;;
		down)
			choice=$(nth "$idx" "$@")
			echo
			if sh "$MODDIR/adiosctl" set "$choice"; then
				echo "Applied: $(label "$choice")"
				rc=0
			else
				echo "Failed to apply: $(label "$choice")"
				rc=1
			fi
			for d in $(block_devs); do
				echo "  $d: $(dev_current "$d")"
			done
			exit $rc
			;;
		*)
			echo
			echo "Cancelled, nothing changed"
			exit 0
			;;
	esac
done
