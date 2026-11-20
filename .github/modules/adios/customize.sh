ui_print " "
ui_print "======================================="
ui_print "         ADIOS I/O Scheduler           "
ui_print "======================================="
ui_print " "

[ "$ARCH" = "arm64" ] || abort "! Unsupported architecture: $ARCH"

MODDIR=$MODPATH
. "$MODPATH/common.sh"

mkdir -p "$ADIOS_DATA"

ui_print "- Kernel: $(uname -r)"
ui_print "- KMI: $(kmi_tag)"

case $(adios_mode) in
	builtin)
		ui_print "- ADIOS is built into the kernel"
		ui_print "- LKM will not be loaded, module only manages scheduler selection"
		;;
	lkm)
		ui_print "- ADIOS LKM is already loaded"
		[ -n "$(lkm_candidates)" ] || abort "! No ADIOS LKM in this package for $(kmi_tag)"
		ui_print "- The new LKM will be used after reboot"
		;;
	*)
		ui_print "- ADIOS not found in kernel, loading LKM..."
		[ -n "$(lkm_candidates)" ] || abort "! No ADIOS LKM in this package for $(kmi_tag)"
		load_adios || abort "! Failed to load ADIOS LKM, see dmesg for details"
		ui_print "- ADIOS LKM loaded"
		;;
esac

rm -f "$ADIOS_SAFE" "$ADIOS_BOOTING"

v=$(adios_version)
[ -n "$v" ] && ui_print "- ADIOS version: $v"
p=$(read_pref)
ui_print "- Default scheduler: ${p:-system (unchanged)}"
ui_print "- Switch it from the WebUI or the Action button"

set_perm_recursive "$MODPATH" 0 0 0755 0644
for f in adiosctl action.sh post-fs-data.sh service.sh uninstall.sh; do
	set_perm "$MODPATH/$f" 0 0 0755
done

update_desc
ui_print "- Done"

MODULE_HOT_INSTALL_REQUEST=true
