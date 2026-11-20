#!/system/bin/sh
MODDIR=${0%/*}
. "$MODDIR/common.sh"

mkdir -p "$ADIOS_DATA"
id=$(boot_id)

if [ -f "$ADIOS_BOOTING" ] && [ "$(cat "$ADIOS_BOOTING" 2>/dev/null)" != "$id" ]; then
	klog "previous boot did not complete, entering safe mode"
	touch "$ADIOS_SAFE"
fi
rm -f "$ADIOS_BOOTING"

if [ -f "$ADIOS_SAFE" ]; then
	update_desc
	exit 0
fi

need_lkm=0
adios_registered || need_lkm=1

if [ "$need_lkm" = 1 ] || [ -n "$(read_pref)" ]; then
	if ! { echo "$id" > "$ADIOS_BOOTING" && sync; }; then
		klog "cannot write boot marker, skipping"
		update_desc
		exit 0
	fi
fi

if [ "$need_lkm" = 1 ] && ! load_adios; then
	klog "no usable ADIOS LKM for $(uname -r)"
fi

update_desc
