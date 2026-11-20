ADIOS_DATA=/data/adb/adios
ADIOS_PREF=$ADIOS_DATA/scheduler
ADIOS_ORIG=$ADIOS_DATA/original
ADIOS_SAFE=$ADIOS_DATA/safe
ADIOS_BOOTING=$ADIOS_DATA/.booting
ADIOS_PROP=$MODDIR/module.prop
ADIOS_DESC="Adaptive Deadline I/O Scheduler: built-in detection, LKM fallback and scheduler switching via WebUI or Action."

klog() {
	echo "<6>adios: $*" > /dev/kmsg 2>/dev/null
}

boot_id() {
	cat /proc/sys/kernel/random/boot_id 2>/dev/null
}

ADIOS_SKIP_DEVS='^(loop|ram|zram|dm-|md|nbd|sr)'

block_devs() {
	awk -v skip="$ADIOS_SKIP_DEVS" '
		{
			d = FILENAME
			sub("^/sys/block/", "", d)
			sub("/.*", "", d)
			if (d !~ skip && NF > 1) print d
		}
	' /sys/block/*/queue/scheduler 2>/dev/null
}

dev_current() {
	sed -n 's/.*\[\([^]]*\)\].*/\1/p' "/sys/block/$1/queue/scheduler" 2>/dev/null
}

dev_available() {
	tr -d '[]' < "/sys/block/$1/queue/scheduler" 2>/dev/null
}

dev_has() {
	case " $(dev_available "$1") " in
		*" $2 "*) return 0 ;;
	esac
	return 1
}

all_schedulers() {
	awk -v skip="$ADIOS_SKIP_DEVS" '
		{
			d = FILENAME
			sub("^/sys/block/", "", d)
			sub("/.*", "", d)
			if (d ~ skip || NF < 2) next
			for (i = 1; i <= NF; i++) {
				s = $i
				gsub(/[][]/, "", s)
				if (!(s in seen)) {
					seen[s] = 1
					print s
				}
			}
		}
	' /sys/block/*/queue/scheduler 2>/dev/null
}

adios_registered() {
	grep -qw adios /sys/block/*/queue/scheduler 2>/dev/null
}

adios_lkm_loaded() {
	grep -q '^adios ' /proc/modules 2>/dev/null
}

adios_mode() {
	if adios_lkm_loaded; then
		echo lkm
	elif adios_registered; then
		echo builtin
	else
		echo missing
	fi
}

kmi_tag() {
	r=$(uname -r)
	kv=$(echo "$r" | cut -d. -f1,2)
	av=$(echo "$r" | grep -oE 'android[0-9]+' | head -n 1)
	echo "${av:+$av-}$kv"
}

lkm_candidates() {
	t=$(kmi_tag)
	kv=${t##*-}
	exact="$MODDIR/lkm/adios-$t.ko"
	[ -f "$exact" ] && echo "$exact"
	for f in "$MODDIR"/lkm/adios-*-"$kv".ko; do
		[ -f "$f" ] && [ "$f" != "$exact" ] && echo "$f"
	done
}

adios_version() {
	v=$(cat /sys/block/*/queue/iosched/adios_version 2>/dev/null | head -n 1)
	k=$(uname -r)
	if [ -n "$v" ]; then
		[ "$(cat "$ADIOS_DATA/version" 2>/dev/null)" = "$k $v" ] || { mkdir -p "$ADIOS_DATA" && echo "$k $v" > "$ADIOS_DATA/version"; } 2>/dev/null
		echo "$v"
	elif adios_lkm_loaded && [ -f "$ADIOS_DATA/lkm_version" ]; then
		cat "$ADIOS_DATA/lkm_version"
	elif adios_registered; then
		awk -v k="$k" '$1 == k { print $2; exit }' "$ADIOS_DATA/version" 2>/dev/null
	fi
}

insmod_ko() {
	out=$(/system/bin/insmod "$1" 2>&1) && return 0
	case $out in
		*"File exists"*) return 0 ;;
	esac
	if command -v ksud >/dev/null 2>&1 && ksud -h 2>&1 | grep -qE '^[[:space:]]+insmod([[:space:]]|$)'; then
		out=$(ksud insmod "$1" 2>&1) && return 0
	fi
	echo "$out"
	return 1
}

load_adios() {
	adios_registered && return 0
	for ko in $(lkm_candidates); do
		if msg=$(insmod_ko "$ko") && adios_registered; then
			k=${ko##*/adios-}
			k=${k%.ko}
			mkdir -p "$ADIOS_DATA"
			sed -n "s/^$k //p" "$MODDIR/lkm/versions" 2>/dev/null | head -n 1 > "$ADIOS_DATA/lkm_version"
			klog "loaded ${ko##*/}"
			return 0
		fi
		klog "failed to load ${ko##*/}: $msg"
	done
	return 1
}

read_pref() {
	[ -f "$ADIOS_PREF" ] || return 0
	p=$(head -n 1 "$ADIOS_PREF" | tr -cd 'a-z0-9_-')
	echo "$p"
}

snapshot_original() {
	id=$(boot_id)
	if [ -f "$ADIOS_ORIG" ] && [ "$(head -n 1 "$ADIOS_ORIG")" = "$id" ]; then
		for d in $(block_devs); do
			sed -n '2,$p' "$ADIOS_ORIG" | grep -q "^$d " && continue
			s=$(dev_current "$d")
			[ -n "$s" ] && echo "$d $s" >> "$ADIOS_ORIG"
		done
		return 0
	fi
	mkdir -p "$ADIOS_DATA"
	tmp="$ADIOS_ORIG.$$"
	{
		echo "$id"
		for d in $(block_devs); do
			echo "$d $(dev_current "$d")"
		done
	} > "$tmp" && mv "$tmp" "$ADIOS_ORIG"
}

orig_of() {
	[ -f "$ADIOS_ORIG" ] || return 0
	sed -n '2,$p' "$ADIOS_ORIG" | awk -v d="$1" '$1 == d { print $2; exit }'
}

set_dev() {
	[ "$(dev_current "$1")" = "$2" ] && return 0
	echo "$2" > "/sys/block/$1/queue/scheduler" 2>/dev/null && return 0
	klog "failed to set $1 to $2"
	return 1
}

restore_original() {
	[ -f "$ADIOS_ORIG" ] || return 0
	sed -n '2,$p' "$ADIOS_ORIG" | awk '!seen[$1]++' | (
		rc=0
		while read -r d s; do
			[ -n "$s" ] && [ -f "/sys/block/$d/queue/scheduler" ] || continue
			set_dev "$d" "$s" || rc=1
		done
		exit $rc
	)
}

apply_pref() {
	snapshot_original
	p=$(read_pref)
	if [ -z "$p" ]; then
		restore_original
		return
	fi
	rc=0
	n=0
	for d in $(block_devs); do
		dev_has "$d" "$p" || continue
		n=$((n + 1))
		set_dev "$d" "$p" || rc=1
	done
	if [ "$n" -eq 0 ]; then
		echo "scheduler not available: $p" >&2
		rc=1
	fi
	return $rc
}

update_desc() {
	[ -f "$ADIOS_PROP" ] || return 0
	case $(adios_mode) in
		builtin) m="✅ Built-in" ;;
		lkm) m="✅ LKM" ;;
		*) m="❌ Unavailable" ;;
	esac
	[ -f "$ADIOS_SAFE" ] && m="⚠️ Safe mode"
	v=$(adios_version)
	p=$(read_pref)
	sed -i "s|^description=.*|description=[$m${v:+ v$v} · Default: ${p:-system}] $ADIOS_DESC|" "$ADIOS_PROP"
}
